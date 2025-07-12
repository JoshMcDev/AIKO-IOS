# AIKO Regulation Update Monitor

## Overview
This system monitors acquisition.gov for updates to Federal Acquisition Regulations (FAR/DFAR) and automatically updates the AIKO knowledge base.

## Features

### 1. Multiple Update Detection Methods
- **RSS Feed Monitoring** - Monitors official RSS feeds for regulation updates
- **Changelog Scraping** - Scrapes rule-making and changelog pages
- **File Hash Comparison** - Detects changes by comparing file hashes
- **Webhook Support** - Ready to receive push notifications (when available)

### 2. Automated Update Process
- Scheduled checks (configurable via cron)
- Automatic backup before updates
- Download and update changed clauses
- Email notifications for changes
- Detailed update reports

### 3. Manual Control
- CLI interface for manual checks
- Update history tracking
- Status monitoring
- Selective update application

## Installation

```bash
cd /Users/J/aiko/Sources/Resources/Regulations/UpdateMonitor
npm install
```

## Configuration

### Environment Variables
```bash
# Email notifications (optional)
export AIKO_EMAIL_USER="your-email@gmail.com"
export AIKO_EMAIL_PASS="your-app-password"
```

### Monitor Configuration
Edit `.monitor-config.json`:
```json
{
  "checkInterval": "0 0 * * 1",  // Weekly on Monday
  "notificationEmail": "admin@example.com",
  "autoUpdate": false,           // Manual approval required
  "backupBeforeUpdate": true,
  "maxBackups": 10
}
```

## Usage

### Start Automatic Monitoring
```bash
# Default weekly schedule
npm start

# Custom schedule with email notifications
npm start -- --interval "0 0 * * *" --email admin@example.com --auto-update
```

### Manual Update Check
```bash
# Check for updates without applying
npm run check

# Check and apply updates
npm run check -- --update
```

### View Update History
```bash
# Show last 10 updates
npm run history

# Show last 50 updates
npm run history -- -n 50
```

### Check Monitor Status
```bash
npm run status
```

## Update Detection Logic

### 1. RSS Feed Monitoring
- Monitors official acquisition.gov RSS feeds
- Parses new entries for clause changes
- Extracts Federal Register citations

### 2. Changelog Page Scraping
- Checks FAR/DFAR rule-making pages
- Compares page hashes for changes
- Extracts clause numbers and effective dates

### 3. File Hash Comparison
- Calculates SHA-256 hash for each regulation file
- Compares with stored hashes
- Detects added, modified, and deleted clauses

## Automated Workflows

### GitHub Actions
Create `.github/workflows/regulation-update.yml`:
```yaml
name: Check Regulation Updates

on:
  schedule:
    - cron: '0 2 * * 1'  # Weekly
  workflow_dispatch:

jobs:
  check-updates:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Check for updates
      run: |
        cd Sources/Resources/Regulations/UpdateMonitor
        npm install
        npm run check
```

### Cron Job (Linux/Mac)
```bash
# Add to crontab
0 2 * * 1 cd /Users/J/aiko && npm run --prefix Sources/Resources/Regulations/UpdateMonitor check
```

### Windows Task Scheduler
Create a scheduled task that runs:
```
C:\path\to\node.exe C:\path\to\aiko\Sources\Resources\Regulations\UpdateMonitor\updateScheduler.js check
```

## Webhook Integration

### Starting Webhook Server
```bash
npm run webhook-server
```

The server listens on port 3000 for POST requests to `/webhook/regulation-update`.

### Webhook Payload Format
```json
{
  "regulation": "FAR",
  "changes": [
    {
      "clauseNumber": "52.217-8",
      "changeType": "modified",
      "effectiveDate": "2025-01-15",
      "federalRegisterCitation": "90 FR 12345"
    }
  ]
}
```

## Update Reports

Reports are generated in HTML format at:
- Latest: `Regulations/update-reports/latest.html`
- Historical: `Regulations/update-reports/report-YYYY-MM-DD.html`

## Backup Management

Backups are stored in `.backups/` with timestamps:
```
Regulations/
├── .backups/
│   ├── backup-2025-01-12T10-00-00/
│   ├── backup-2025-01-05T10-00-00/
│   └── ...
```

Old backups are automatically cleaned based on `maxBackups` setting.

## Security Considerations

1. **Webhook Validation** - Implement signature verification when available
2. **Email Credentials** - Use app passwords, not account passwords
3. **File Permissions** - Ensure regulation files are read-only to AIKO
4. **Backup Encryption** - Consider encrypting backups if sensitive

## Troubleshooting

### Common Issues

1. **No updates detected**
   - Check internet connectivity
   - Verify acquisition.gov URLs are accessible
   - Review `.monitor-config.json` for last check times

2. **Email notifications not working**
   - Verify environment variables are set
   - Check email provider settings (app passwords)
   - Review email transporter configuration

3. **Updates failing to download**
   - Check disk space
   - Verify write permissions
   - Review error logs for specific clause failures

### Debug Mode
```bash
# Enable verbose logging
DEBUG=aiko:* npm run check
```

## Future Enhancements

1. **Machine Learning** - Predict which clauses are likely to change
2. **API Integration** - Direct API access when acquisition.gov provides it
3. **Differential Updates** - Track specific changes within clause text
4. **Impact Analysis** - Analyze how changes affect existing contracts
5. **Slack/Teams Integration** - Send notifications to team channels

## Contributing

To add support for additional regulation sources:

1. Add source configuration to `config.sources`
2. Implement scraping logic for the new source
3. Update URL construction in `constructClauseUrl()`
4. Test with manual check command

## License

MIT License - See LICENSE file for details