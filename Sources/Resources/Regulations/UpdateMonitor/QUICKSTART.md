# AIKO Regulation Monitor - Quick Start Guide

## 🚀 5-Minute Setup

### Prerequisites
- Node.js 16+ installed
- npm or yarn package manager
- Internet connection

### Installation

1. **Navigate to the monitor directory**:
```bash
cd /Users/J/aiko/Sources/Resources/Regulations/UpdateMonitor
```

2. **Run the setup script**:
```bash
chmod +x setup.sh
./setup.sh
```

This will:
- Install all dependencies
- Create directory structure
- Generate initial hash files for existing regulations
- Create default configuration
- Set up platform-specific schedulers

### Basic Usage

#### Check for Updates (Manual)
```bash
# Check without applying updates
npm run check

# Check and apply updates
npm run check -- --update
```

#### Start Automatic Monitoring
```bash
# Start with default weekly schedule
npm start

# Start with custom schedule
npm start -- --interval "0 0 * * *" --email admin@example.com
```

#### View Status
```bash
# Check monitor status
npm run status

# View update history
npm run history
```

### Configuration

Edit `.monitor-config.json` to customize:

```json
{
  "checkInterval": "0 0 * * 1",      // Cron schedule
  "notificationEmail": "",           // Email for alerts
  "autoUpdate": false,               // Auto-apply updates
  "backupBeforeUpdate": true,        // Backup on update
  "maxBackups": 10                   // Backup retention
}
```

### Testing Webhooks

1. **Start webhook server**:
```bash
npm run webhook-server
```

2. **Test webhook (in another terminal)**:
```bash
npx ts-node testWebhook.ts all
```

### Monitoring Dashboard

After running checks, view reports at:
- Latest: `Regulations/update-reports/latest.html`
- Historical: `Regulations/update-reports/report-YYYY-MM-DD.html`

## 🎯 Common Tasks

### Enable Email Notifications
```bash
export AIKO_EMAIL_USER="your-email@gmail.com"
export AIKO_EMAIL_PASS="your-app-password"
npm start -- --email your-email@gmail.com
```

### Schedule Daily Checks
```bash
npm start -- --interval "0 2 * * *"
```

### Force Update Check
```bash
npm run check -- --update
```

### View Last 50 Updates
```bash
npm run history -- -n 50
```

## 🚨 Troubleshooting

### No updates detected
- Check internet connectivity
- Verify acquisition.gov is accessible
- Review logs in `monitor.log`

### Email not working
- Verify environment variables are set
- Check email provider allows app passwords
- Review email transporter configuration

### Updates failing
- Check disk space
- Verify write permissions to Regulations folder
- Review error logs for specific failures

## 📱 Integration with AIKO

The monitor automatically updates the local regulation files that AIKO uses for:
- Clause selection
- Compliance checking
- Contract generation

Updates are applied to:
```
/Users/J/aiko/Sources/Resources/Regulations/
├── FAR/
├── DFARS/
├── DFARS PGI/
└── ...
```

## 🔧 Advanced Setup

### GitHub Actions
Add to `.github/workflows/regulation-update.yml`:
```yaml
name: Check Regulation Updates
on:
  schedule:
    - cron: '0 2 * * 1'
jobs:
  check-updates:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - run: |
        cd Sources/Resources/Regulations/UpdateMonitor
        npm install
        npm run check
```

### System Service (macOS)
```bash
# Install as launch agent
cp com.aiko.regulation-monitor.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.aiko.regulation-monitor.plist
```

### System Service (Linux)
```bash
# Install as systemd service
sudo cp aiko-regulation-monitor.service /etc/systemd/system/
sudo systemctl enable aiko-regulation-monitor
sudo systemctl start aiko-regulation-monitor
```

## 📞 Support

For issues or questions:
- Check logs in `monitor.log` and `monitor-error.log`
- Review README.md for detailed documentation
- Enable debug mode: `DEBUG=aiko:* npm run check`

---

**Quick Reference Card**

| Command | Description |
|---------|-------------|
| `npm run check` | Manual update check |
| `npm start` | Start monitoring |
| `npm run status` | View status |
| `npm run history` | View history |
| `npm run webhook-server` | Start webhook receiver |
| `./setup.sh` | Initial setup |