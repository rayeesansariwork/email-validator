# Deployment Guide - Email Validator

This guide covers deploying your email validator to various cloud platforms. Choose based on your budget and requirements.

---

## ⚠️ Critical Requirement

> [!WARNING]
> Your server **MUST have port 25 (SMTP) outbound access**. Many cloud platforms block it to prevent spam. VPS providers typically allow it.

---

## 🌟 Recommended: Digital Ocean Droplet

**Cost:** $6/month | **Setup Time:** 10 minutes

### Why DigitalOcean?

- ✅ Port 25 is open by default
- ✅ Simple, reliable
- ✅ Good documentation
- ✅ $200 free credit for new users

### Steps

1. **Create Droplet**
   ```
   - Choose Ubuntu 22.04 LTS
   - Select $6/month plan (1GB RAM)
   - Choose nearest datacenter
   - Add SSH key
   ```

2. **SSH into server**
   ```bash
   ssh root@your-droplet-ip
   ```

3. **Install Docker**
   ```bash
   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sh get-docker.sh
   
   # Install Docker Compose
   apt-get update
   apt-get install -y docker-compose
   ```

4. **Clone and Deploy**
   ```bash
   # Clone repository
   git clone https://github.com/rayeesansariwork/email-validator.git
   cd email-validator
   
   # Configure environment
   cp .env.example .env
   nano .env  # Edit FROM_EMAIL and HELLO_NAME
   
   # Start service
   docker-compose up -d
   ```

5. **Verify Deployment**
   ```bash
   # Wait for Tor bootstrap (3 minutes)
   sleep 180
   
   # Test health endpoint
   curl http://localhost:8001/health
   
   # Test verification
   curl -X POST http://localhost:8001/verify/single \
     -H "Content-Type: application/json" \
     -d '{"email":"test@gmail.com"}'
   ```

6. **Access from Internet**
   
   Your API is now available at: `http://your-droplet-ip:8001`

---

## 💶 Budget Option: Hetzner Cloud

**Cost:** €4/month (~$4.50) | **Setup Time:** 10 minutes

### Why Hetzner?

- ✅ Cheapest option
- ✅ Port 25 open
- ✅ Fast European servers
- ❌ EU-based (GDPR compliant)

### Steps

Same as DigitalOcean above, just create server on [Hetzner Cloud](https://www.hetzner.com/cloud).

---

## ☁️ AWS EC2

**Cost:** $5-10/month | **Setup Time:** 15 minutes

### Important

- ⚠️ **Port 25 is blocked by default** - you must request removal
- Request here: https://aws.amazon.com/forms/ec2-email-limit-rdns-request

### Steps

1. **Launch EC2 Instance**
   ```
   - AMI: Ubuntu 22.04
   - Type: t2.micro (free tier) or t3.small
   - Security Group: Allow inbound 8001, outbound all
   ```

2. **Request Port 25 Access**
   
   Submit form with:
   - Elastic IP address
   - Reverse DNS record (optional but helpful)
   - Use case: "Email validation for SaaS application"

3. **Deploy** (same as DigitalOcean steps 2-6)

---

## 🚫 Platforms That WON'T Work

### Railway ❌
- Port 25 is blocked
- Cannot be unblocked

### Render ❌  
- Port 25 is blocked
- Cannot be unblocked

### Heroku ❌
- Port 25 is blocked
- Expensive ($7-25/month)

### Vercel / Netlify ❌
- Serverless - can't run persistent Tor instances
- No port 25 access

---

## 🔐 Security Recommendations

### 1. Set up Firewall

```bash
# Allow SSH and API port
ufw allow 22
ufw allow 8001
ufw enable
```

### 2. Use Reverse Proxy (Optional but Recommended)

Install Nginx to add HTTPS:

```bash
# Install Nginx
apt-get install -y nginx certbot python3-certbot-nginx

# Configure Nginx
nano /etc/nginx/sites-available/email-validator
```

Add:
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

```bash
# Enable site
ln -s /etc/nginx/sites-available/email-validator /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx

# Get SSL certificate
certbot --nginx -d your-domain.com
```

### 3. Add API Key Authentication (Optional)

Modify `app.py` to add authentication:

```python
from fastapi import Header, HTTPException

API_KEY = "your-secure-api-key"

async def verify_api_key(x_api_key: str = Header(...)):
    if x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    return x_api_key

@app.post("/verify/single", dependencies=[Depends(verify_api_key)])
async def verify_single(request: EmailRequest):
    # ... existing code
```

---

## 📊 Monitoring

### View Logs

```bash
# Docker logs
docker-compose logs -f

# Tor instance logs
docker-compose exec email-validator tail -f /root/.tor/instance1/tor.log
```

### Check Tor IPs

```bash
# Access container
docker-compose exec email-validator bash

# Test each Tor instance
for port in 9050 9052 9054 9056; do
  echo -n "Port $port: "
  curl --socks5 127.0.0.1:$port -s https://api.ipify.org
  echo ""
done
```

### Monitor Resource Usage

```bash
# Docker stats
docker stats

# Server resources
htop
```

---

## 🔧 Maintenance

### Update the Service

```bash
cd email-validator

# Pull latest changes
git pull

# Rebuild and restart
docker-compose down
docker-compose up -d --build
```

### Restart Tor Instances

If Tor instances get stuck:

```bash
# Restart container
docker-compose restart

# Or rebuild fresh
docker-compose down -v  # Removes volumes
docker-compose up -d
```

### Clean Up Old Results

```bash
# Remove old result files
rm -f results_rotation_*.jsonl

# Or in Docker
docker-compose exec email-validator rm -f /app/results_rotation_*.jsonl
```

---

## 🆘 Troubleshooting

### "Port 25 connection refused"

**Problem:** Server blocks port 25 outbound

**Solution:** 
- Contact hosting provider to unblock port 25
- Or switch to DigitalOcean/Hetzner

### "IpBlacklisted" errors

**Problem:** Google is blocking your Tor IPs

**Solutions:**
1. Wait 60 seconds for IP rotation
2. Add more Tor instances (edit docker-compose.yml)
3. Reduce request rate
4. Consider residential proxies for Gmail

### Tor instances not bootstrapping

**Problem:** Tor can't connect to network

**Solution:**
```bash
# Check Tor logs
docker-compose exec email-validator cat /root/.tor/instance1/tor.log

# Restart if stuck
docker-compose restart
```

### Health check failing

```bash
# Check if container is running
docker-compose ps

# Check logs
docker-compose logs

# Restart
docker-compose restart
```

---

## 💡 Performance Tuning

### Scale  Beyond 4 Tor Instances

Edit `docker-compose.yml` to add more instances:

```yaml
# Add to docker-compose.yml
volumes:
  - tor-instance5:/root/.tor/instance5
  - tor-instance6:/root/.tor/instance6
```

Create additional Tor configs in `tor-configs/`.

Update `app.py`:
```python
TOR_PROXY_PORTS = [9050, 9052, 9054, 9056, 9058, 9060]
```

### Optimize for High Volume

```bash
# In .env file
MAX_CONCURRENT=6  # Increase concurrent checks
TIMEOUT_PER_EMAIL=60  # Reduce timeout
```

### Use Multiple Servers

Deploy to multiple regions and load-balance between them for maximum capacity.

---

## 📈 Cost Comparison

| Provider | Monthly Cost | Port 25 | Setup Time | Recommended |
|----------|--------------|---------|------------|-------------|
| **Hetzner** | €4 ($4.50) | ✅ Open | 10 min | 🏆 Best Value |
| **DigitalOcean** | $6 | ✅ Open | 10 min | 🥈 Easiest |
| **Contabo** | $5 | ✅ Open | 15 min | Budget |
| **AWS EC2** | $5-10 | ⚠️ Request | 20 min | Enterprise |
| **Railway** | $5 | ❌ Blocked | N/A | ❌ Won't work |
| **Render** | $7 | ❌ Blocked | N/A | ❌ Won't work |

---

## 🎯 Next Steps

1. ✅ Choose hosting provider
2. ✅ Deploy using steps above
3. ✅ Set up monitoring
4. ✅ Configure reverse proxy (optional)
5. ✅ Test with your email list

**Need help?** [Open an issue](https://github.com/rayeesansariwork/email-validator/issues)
