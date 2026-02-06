# 🚀 Quick Start Guide - Multi-Tor Proxy Rotation

## Ready to Use in 3 Steps!

### 1️⃣ Start Tor Instances
```bash
cd /Users/arin/Documents/email_validator/check-if-email-exists
./start_tor_instances.sh
```

### 2️⃣ Test IP Rotation (Verify Different IPs)
```bash
./test_tor_rotation.sh
```

### 3️⃣ Run Your Email Validator

**Option A - FastAPI Server:**
```bash
python app.py
# Server runs on http://0.0.0.0:8001
```

**Option B - Bulk Script:**
```bash
./bulk_check_rotation.sh emails.txt
```

---

## 🛑 When Done
```bash
./stop_tor_instances.sh
```

---

## 📦 What You Have Now

✅ **4 Tor instances** running on ports: `9050, 9052, 9054, 9056`  
✅ **Automatic IP rotation** every 60 seconds  
✅ **Smart retry logic** when IPs get blacklisted  
✅ **4x capacity** before hitting Google's rate limits  

---

## 🔍 Expected Performance

| Before | After |
|--------|-------|
| 1 Tor IP | 4 rotating Tor IPs |
| ~10-20 emails before block | ~40-100 emails before block |
| Manual recovery | Automatic retry |

---

## 📚 Full Documentation

- [Complete Walkthrough](file:///Users/arin/.gemini/antigravity/brain/62282c44-2f62-4583-9390-ff1b03e24aa3/walkthrough.md) - Detailed usage and troubleshooting
- [Analysis & Recommendations](file:///Users/arin/.gemini/antigravity/brain/62282c44-2f62-4583-9390-ff1b03e24aa3/analysis_and_recommendations.md) - How we got here and alternatives

---

## 💡 Pro Tips

- Run `test_tor_rotation.sh` to see your 4 different IPs
- Check logs: `tail -f ~/.tor/instance1/tor.log`
- Monitor blacklists: `tail -f results_rotation_*.jsonl | grep -i blacklist`
- Need more capacity? I can help add more Tor instances!

**You're all set! 🎉**
