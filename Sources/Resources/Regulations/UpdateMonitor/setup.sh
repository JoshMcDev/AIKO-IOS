#!/bin/bash

# AIKO Regulation Monitor Setup Script

echo "================================================"
echo "AIKO Regulation Update Monitor Setup"
echo "================================================"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "Error: Node.js is not installed. Please install Node.js first."
    exit 1
fi

echo "✓ Node.js found: $(node --version)"

# Navigate to the monitor directory
cd "$(dirname "$0")"

# Install dependencies
echo ""
echo "Installing dependencies..."
npm install

# Create necessary directories
echo ""
echo "Creating directory structure..."
mkdir -p ../update-reports
mkdir -p ../.backups
mkdir -p ../.archive

# Generate initial hash files for existing regulations
echo ""
echo "Generating initial hash files..."
node -e "
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const regulations = ['FAR', 'DFARS', 'DFARS PGI', 'AFARS', 'DAFFARS', 'DAFFARS MP', 'SOFARS'];

regulations.forEach(reg => {
  const regPath = path.join('..', reg);
  if (fs.existsSync(regPath)) {
    console.log('Processing ' + reg + '...');
    const hashes = {};
    const files = fs.readdirSync(regPath).filter(f => f.endsWith('.html'));
    
    files.forEach(file => {
      const content = fs.readFileSync(path.join(regPath, file), 'utf-8');
      const hash = crypto.createHash('sha256').update(content).digest('hex');
      hashes[file] = hash;
    });
    
    fs.writeFileSync(path.join(regPath, '.hashes.json'), JSON.stringify(hashes, null, 2));
    console.log('  Generated hashes for ' + files.length + ' files');
  }
});
"

# Create default configuration
echo ""
echo "Creating default configuration..."
cat > ../.monitor-config.json << EOF
{
  "checkInterval": "0 0 * * 1",
  "notificationEmail": "",
  "autoUpdate": false,
  "backupBeforeUpdate": true,
  "maxBackups": 10,
  "sources": [
    {
      "name": "FAR",
      "baseUrl": "https://www.acquisition.gov/far",
      "changelogUrl": "https://www.acquisition.gov/far/current-rule-making",
      "rssUrl": "https://www.acquisition.gov/rss/far"
    },
    {
      "name": "DFARS",
      "baseUrl": "https://www.acquisition.gov/dfars",
      "changelogUrl": "https://www.acquisition.gov/dfars/current-dfars-cases",
      "rssUrl": "https://www.acquisition.gov/rss/dfars"
    },
    {
      "name": "DFARS PGI",
      "baseUrl": "https://www.acquisition.gov/dfarspgi",
      "changelogUrl": "https://www.acquisition.gov/dfarspgi/current-pgi-changes"
    }
  ]
}
EOF

# Create systemd service file (for Linux servers)
echo ""
echo "Creating systemd service file..."
cat > aiko-regulation-monitor.service << EOF
[Unit]
Description=AIKO Regulation Update Monitor
After=network.target

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=$(pwd)
ExecStart=$(which node) $(pwd)/updateScheduler.js start
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create launchd plist (for macOS)
echo ""
echo "Creating macOS launch agent..."
cat > com.aiko.regulation-monitor.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.aiko.regulation-monitor</string>
    <key>ProgramArguments</key>
    <array>
        <string>$(which node)</string>
        <string>$(pwd)/updateScheduler.js</string>
        <string>start</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$(pwd)</string>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key>
        <integer>1</integer>
        <key>Hour</key>
        <integer>2</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>$(pwd)/monitor.log</string>
    <key>StandardErrorPath</key>
    <string>$(pwd)/monitor-error.log</string>
</dict>
</plist>
EOF

echo ""
echo "================================================"
echo "Setup Complete!"
echo "================================================"
echo ""
echo "Next steps:"
echo ""
echo "1. Configure email notifications (optional):"
echo "   Edit ../.monitor-config.json and add your email"
echo ""
echo "2. Test the monitor:"
echo "   npm run check"
echo ""
echo "3. Start automatic monitoring:"
echo "   npm start"
echo ""
echo "4. For system-level scheduling:"
echo "   - Linux: sudo cp aiko-regulation-monitor.service /etc/systemd/system/"
echo "   - macOS: cp com.aiko.regulation-monitor.plist ~/Library/LaunchAgents/"
echo ""
echo "5. View the monitoring dashboard:"
echo "   npm run status"
echo ""
echo "For more information, see README.md"