# Multi-stage Dockerfile for Email Validator with Multi-Tor Proxy Rotation
FROM ubuntu:22.04 AS base

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    tor \
    curl \
    python3 \
    python3-pip \
    lsof \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy application files
COPY app.py .
COPY start_tor_instances.sh .
COPY stop_tor_instances.sh .
COPY test_tor_rotation.sh .
COPY bulk_check_rotation.sh .
COPY download_binary.sh .

# Make scripts executable
RUN chmod +x *.sh

# Download the check_if_email_exists binary
RUN ./download_binary.sh

# Create Tor config directories
RUN mkdir -p /root/.tor/instance{1,2,3,4}

# Copy Tor configuration files
COPY tor-configs/instance1.torrc /root/.tor/instance1/torrc
COPY tor-configs/instance2.torrc /root/.tor/instance2/torrc
COPY tor-configs/instance3.torrc /root/.tor/instance3/torrc
COPY tor-configs/instance4.torrc /root/.tor/instance4/torrc

# Set proper permissions for Tor directories
RUN chmod -R 700 /root/.tor

# Expose FastAPI port
EXPOSE 8001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8001/health || exit 1

# Start script that launches Tor instances and FastAPI
COPY start.sh .
RUN chmod +x start.sh

CMD ["./start.sh"]
