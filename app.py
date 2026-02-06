# app.py
# Upgraded FastAPI wrapper for check_if_email_exists CLI - 2026 speed edition
# Focus: concurrency + async subprocess + no artificial delays
import asyncio
import json
import re
import os
import subprocess
from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import List, Dict, Any

app = FastAPI(title="Gravityer Email Verification API - Fast Edition")

# === CONFIGURATION - TUNE THESE VALUES ===
# Support both local development and Docker deployment
import os

BINARY_PATH = os.getenv(
    "BINARY_PATH",
    os.path.join(os.path.dirname(__file__), "check_if_email_exists")
)
# Fallback to Docker path if local doesn't exist
if not os.path.isfile(BINARY_PATH):
    BINARY_PATH = "/app/check_if_email_exists"

FROM_EMAIL = os.getenv("FROM_EMAIL", "ryees965@gmail.com")
PROXY_HOST = "127.0.0.1"

# You can add more ports when you run multiple tor instances
TOR_PROXY_PORTS = [9050, 9052, 9054, 9056]  # All 4 Tor instances active!

MAX_CONCURRENT = int(os.getenv("MAX_CONCURRENT", "4"))
TIMEOUT_PER_EMAIL = int(os.getenv("TIMEOUT_PER_EMAIL", "90"))
REQUEST_TIMEOUT_BULK = int(os.getenv("REQUEST_TIMEOUT_BULK", "600"))

# Safety check
if not os.path.isfile(BINARY_PATH):
    raise RuntimeError(f"Binary not found at: {BINARY_PATH}")
if not os.access(BINARY_PATH, os.X_OK):
    raise RuntimeError(f"Binary is not executable: {BINARY_PATH}")


class EmailRequest(BaseModel):
    email: str
    proxy_port: int = 9050
    from_email: str = FROM_EMAIL


class BulkEmailRequest(BaseModel):
    emails: List[str]


def strip_ansi(text: str) -> str:
    """Remove ANSI escape sequences"""
    ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
    return ansi_escape.sub('', text)


async def _verify_email_once(email: str, proxy_port: int, from_email: str = FROM_EMAIL) -> Dict[str, Any]:
    """
    Async version using asyncio.subprocess
    """
    cmd = [
        BINARY_PATH,
        "--proxy-host", PROXY_HOST,
        "--proxy-port", str(proxy_port),
        "--from-email", from_email,
        "--hello-name", "gravityer.com",
        email
    ]

    cwd = os.path.dirname(BINARY_PATH)

    try:
        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            cwd=cwd
        )

        try:
            stdout, stderr = await asyncio.wait_for(process.communicate(), timeout=TIMEOUT_PER_EMAIL)
        except asyncio.TimeoutError:
            process.terminate()
            await process.wait()
            return {"email": email, "error": "Timeout after {}s".format(TIMEOUT_PER_EMAIL), "is_reachable": "unknown"}

        if process.returncode != 0:
            err_msg = stderr.decode().strip() or "CLI failed"
            return {"email": email, "error": err_msg, "is_reachable": "unknown"}

        output = stdout.decode()
        cleaned = strip_ansi(output)

        # ── Your original JSON extraction logic ──
        json_candidates = []
        pos = 0
        while True:
            start = cleaned.find('{', pos)
            if start == -1:
                break
            brace_count = 1
            end = start + 1
            for i in range(start + 1, len(cleaned)):
                if cleaned[i] == '{':
                    brace_count += 1
                elif cleaned[i] == '}':
                    brace_count -= 1
                    if brace_count == 0:
                        end = i + 1
                        break
            if brace_count == 0:
                candidate = cleaned[start:end].strip()
                json_candidates.append(candidate)
            pos = end

        if not json_candidates:
            return {
                "email": email,
                "error": "No JSON found in output",
                "raw_preview": cleaned[:300],
                "is_reachable": "unknown"
            }

        # Take the last valid JSON
        json_str = json_candidates[-1]
        try:
            parsed = json.loads(json_str)
            parsed["email"] = email
            return parsed
        except json.JSONDecodeError as e:
            return {
                "email": email,
                "error": f"JSON parse error: {str(e)}",
                "raw_preview": json_str[:200],
                "is_reachable": "unknown"
            }

    except Exception as e:
        return {"email": email, "error": str(e), "is_reachable": "unknown"}


async def verify_email_async(email: str, proxy_port: int = 9050, from_email: str = FROM_EMAIL) -> Dict[str, Any]:
    """
    Wrapper around _verify_email_once that handles proxy rotation on IpBlacklisted errors.
    """
    # Build list of ports to try: requested port first, then others from the pool
    ports_to_try = [proxy_port]
    for p in TOR_PROXY_PORTS:
        if p != proxy_port and p not in ports_to_try:
            ports_to_try.append(p)
    
    # Limit max retries to avoid infinite loops or long delays (e.g., try max 3 ports)
    ports_to_try = ports_to_try[:3]
    
    last_result = {"email": email, "is_reachable": "unknown", "error": "No ports available"}
    
    for port in ports_to_try:
        last_result = await _verify_email_once(email, port, from_email)
        
        # Check for IpBlacklisted in the result
        smtp_data = last_result.get("smtp", {})
        if isinstance(smtp_data, dict) and smtp_data.get("description") == "IpBlacklisted":
            continue  # Retry with next port
        
        return last_result
    
    return last_result


@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "binary_exists": os.path.exists(BINARY_PATH),
        "binary_executable": os.access(BINARY_PATH, os.X_OK)
    }


@app.post("/verify/single")
async def verify_single(request: EmailRequest):
    result = await verify_email_async(request.email, proxy_port=request.proxy_port, from_email=request.from_email)
    return result


@app.post("/verify/bulk/stream")
async def verify_bulk_stream(request: BulkEmailRequest):
    """
    Fast streaming endpoint - concurrent checks + no artificial sleep
    """
    if not request.emails:
        raise HTTPException(400, "Empty email list")

    semaphore = asyncio.Semaphore(MAX_CONCURRENT)

    async def check_and_yield(email: str, port: int):
        async with semaphore:
            result = await verify_email_async(email, proxy_port=port)
            yield f"data: {json.dumps(result)}\n\n"

    async def event_generator():
        semaphore = asyncio.Semaphore(MAX_CONCURRENT)

        async def bounded_check(email: str, port: int):
            async with semaphore:
                result = await verify_email_async(email, proxy_port=port)
                return f"data: {json.dumps(result)}\n\n"

        # Create tasks
        pending = [
            asyncio.create_task(bounded_check(email, TOR_PROXY_PORTS[i % len(TOR_PROXY_PORTS)]))
            for i, email in enumerate(request.emails)
        ]

        # Stream results as they complete
        while pending:
            done, pending = await asyncio.wait(pending, return_when=asyncio.FIRST_COMPLETED)
            for task in done:
                chunk = await task  # get the yielded string
                yield chunk

        yield "data: [DONE]\n\n"
    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive"
        }
    )
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001, reload=False)