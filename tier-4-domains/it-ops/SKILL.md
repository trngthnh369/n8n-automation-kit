---
name: it-ops
tier: 4
category: domain
version: 1.0.0
description: IT operations automation — monitoring, alerting, CI/CD triggers, backup verification, incident response.
triggers:
  - "server"
  - "monitoring"
  - "CI/CD"
  - "DevOps"
  - "backup"
  - "uptime"
  - "deploy"
  - "incident"
requires:
  - builder
  - n8n-mcp
recommends:
  - messaging
related:
  - "[[messaging]]"
---

# ⚙️ IT Operations Automation

Server monitoring, CI/CD integration, backup verification, and incident response.

## Architecture: Observability Pipeline

```
Probes (Collect):
├── HTTP health checks (ping endpoints)
├── Server metrics (CPU, RAM, disk via API)
├── Application logs (webhook/poll)
├── SSL certificate expiry check
├── Docker container status
    ↓
Analyze:
├── Threshold comparison (CPU >80%, disk >90%)
├── Pattern detection (error rate spike)
├── Availability tracking (uptime %)
    ↓
Respond:
├── Alert (Slack/Telegram/Email)
├── Auto-remediate (restart service, scale up)
├── Escalate (page on-call engineer)
├── Log incident
```

## Key Patterns

### 1. HTTP Health Check

```
Schedule Trigger (every 5min)
→ HTTP Request: GET {service_url}/health
→ IF response.status !== 200 OR timeout:
  → Check 2 more times (avoid false positive)
  → IF still down → alert via [[messaging]]
  → Log downtime start
→ IF previously down AND now up:
  → Calculate downtime duration
  → Send recovery alert
  → Log recovery
```

### 2. SSL Certificate Monitoring

```javascript
const https = require("https");
const domain = "example.com";
const options = { host: domain, port: 443, method: "GET" };

return new Promise((resolve) => {
  const req = https.request(options, (res) => {
    const cert = res.socket.getPeerCertificate();
    const expiry = new Date(cert.valid_to);
    const daysLeft = Math.floor((expiry - Date.now()) / 86400000);
    resolve([{ json: { domain, expiry: cert.valid_to, daysLeft } }]);
  });
  req.end();
});
// Alert if daysLeft < 30
```

### 3. Docker Container Monitoring

```
Schedule Trigger (every 10min)
→ HTTP Request: GET http://docker-host:2375/containers/json?all=true
→ Code node: Check each container status
  → IF state !== "running" AND expected_running:
    → Alert + attempt restart:
      POST http://docker-host:2375/containers/{id}/restart
    → Verify restart successful
```

### 4. CI/CD Pipeline Trigger

```
GitHub Webhook (push to main)
→ Validate: branch === "main" AND commits not empty
→ Trigger deployment:
  → SSH into server OR call deployment API
  → run: git pull && docker compose up -d --build
→ Wait 30s → health check
→ IF healthy → notify success
→ IF unhealthy → rollback + alert
```

### 5. Backup Verification

```
Schedule Trigger (daily, 2AM)
→ Check backup directory:
  → List files modified in last 24h
  → Verify file sizes > minimum expected
  → Verify file count matches expected
→ IF any check fails → CRITICAL alert
→ Weekly: test restore from backup → verify data integrity

Database backup check:
→ mysqldump/pg_dump → verify size + record count
→ Log backup metadata to Sheets
```

### 6. Log Aggregation & Alerting

```
Webhook (from Filebeat/Fluentd/rsyslog)
→ Parse log entry: { timestamp, level, service, message }
→ IF level === "ERROR" OR level === "FATAL":
  → Count errors in last 5min window
  → IF error_count > threshold → alert with recent errors sample
→ Store to logging DB for historical analysis
```

### 7. Incident Response Automation

```
Alert triggered → Create incident record:
  { id, service, severity, started_at, status: "OPEN" }
→ Notify on-call engineer (rotate based on schedule)
→ IF no acknowledgment in 15min → escalate to manager
→ On resolution:
  → Calculate MTTR (mean time to resolve)
  → Post incident summary
  → Update incident record: status: "RESOLVED"
```

## Server Resource Alerts

| Metric             | Warning         | Critical        | Check Interval |
| ------------------ | --------------- | --------------- | -------------- |
| CPU usage          | >70% (5min avg) | >90% (5min avg) | 5min           |
| RAM usage          | >80%            | >95%            | 5min           |
| Disk usage         | >80%            | >95%            | 30min          |
| HTTP response time | >2s             | >5s             | 5min           |
| Error rate         | >1%             | >5%             | 5min           |

## Credentials Required

- Server SSH keys or API endpoints
- Docker API access (TCP socket or TLS)
- GitHub/GitLab webhook secrets
- Monitoring service APIs (if using external: UptimeRobot, Datadog)
- [[messaging]] credentials for alerts
