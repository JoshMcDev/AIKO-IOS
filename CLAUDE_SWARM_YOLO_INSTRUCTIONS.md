# AIKO Claude Swarm YOLO Mode Instructions

## ⚠️ DANGER: YOLO Mode with --vibe

**WARNING**: `--vibe` mode allows ALL tools for all instances with no restrictions. Use with extreme caution.

---

## 🚀 INITIAL Setup

### 1. Prerequisites Check
```bash
# Verify Ruby version (3.2.0+ required)
ruby --version

# Verify Claude CLI is installed and configured
claude --version

# Verify claude-swarm installation
export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/3.4.0/bin:$PATH"
claude-swarm version
```

### 2. Pre-Flight Safety
```bash
cd /Users/J/aiko

# Backup current state
git status
git stash push -m "Pre-swarm backup $(date)"

# Verify configuration
ruby -e "require 'yaml'; puts 'Config valid' if YAML.load_file('claude-swarm.yml')"
```

---

## 🎯 DURING Operation

### 3. Launch YOLO Mode
```bash
# Standard launch (recommended first)
claude-swarm start claude-swarm.yml

# OR YOLO MODE (⚠️ DANGEROUS - ALL TOOLS ENABLED)
claude-swarm start claude-swarm.yml --vibe
```

### 4. Monitor Session Activity
```bash
# In another terminal - monitor active sessions
claude-swarm ps

# Watch real-time activity (replace SESSION_ID)
claude-swarm watch SESSION_ID

# List all sessions
claude-swarm list-sessions
```

### 5. TDD Workflow Commands (in Claude interface)
```
/prd     # Start with enhanced requirements
/conTS   # Implementation planning
/tdd     # Test-driven development setup
/dev     # Development with multiple agents
/green   # Validate all tests pass
/refactor # Code cleanup
/qa      # Quality assurance gate
```

### 6. Emergency Stop
```bash
# Kill all claude-swarm processes
pkill -f claude-swarm

# Or use Ctrl+C in the running terminal
```

---

## 🧹 AFTER Usage

### 7. Post-Session Cleanup
```bash
# Check what changed
git status
git diff

# Review all modifications
git log --oneline -10

# If satisfied, commit changes
git add .
git commit -m "Claude Swarm Phase 5 development session"

# If not satisfied, reset
git reset --hard HEAD
git clean -fd
```

### 8. Session Management
```bash
# Show session details (replace SESSION_ID)
claude-swarm show SESSION_ID

# Clean up old sessions
claude-swarm clean

# Restore previous session if needed
claude-swarm restore SESSION_ID
```

### 9. Security Review (CRITICAL after --vibe mode)
```bash
# Check for unexpected file changes
find . -name "*.sh" -newer claude-swarm.yml -ls
find . -name "*.rb" -newer claude-swarm.yml -ls
find . -name "*.py" -newer claude-swarm.yml -ls

# Review any new executable files
find . -type f -perm +111 -newer claude-swarm.yml -ls

# Check for network configuration changes
grep -r "http" . --include="*.swift" --include="*.json" | grep -v ".git"

# Verify TodoWrite and Project_Tasks.md synchronization
git diff HEAD -- TodoWrite.json Project_Tasks.md
echo "Check TodoWrite → Project_Tasks.md sync integrity"
```

---

## 🛡️ Safety Protocols

### Before YOLO Mode
```bash
# Set session limits
export CLAUDE_SWARM_HOME="/tmp/claude-swarm-session"

# Create isolated working directory
mkdir -p /tmp/aiko-safe-test
cp -r /Users/J/aiko/* /tmp/aiko-safe-test/
cd /tmp/aiko-safe-test

# Run in sandboxed environment
claude-swarm start claude-swarm.yml --vibe
```

### During YOLO Mode
- Monitor file system changes continuously
- Watch network activity if possible  
- Be ready to interrupt with Ctrl+C
- Never leave unattended

### After YOLO Mode
- Complete security review (above)
- Verify all changes before committing
- Reset permissions if needed: `chmod -R u+rw,go-rwx .`

---

## 📋 Command Reference

### Session Commands
```bash
claude-swarm                                    # Start with default config
claude-swarm start [config.yml]               # Start with specific config
claude-swarm start [config.yml] --vibe        # ⚠️ YOLO MODE - ALL TOOLS
claude-swarm ps                                # Show active sessions
claude-swarm list-sessions                     # List all sessions
claude-swarm show SESSION_ID                   # Show session details
claude-swarm restore SESSION_ID                # Restore previous session
claude-swarm watch SESSION_ID                  # Watch session activity
claude-swarm clean                             # Clean old sessions
```

### Safety Commands
```bash
pkill -f claude-swarm                         # Emergency stop
git stash push -m "backup"                   # Quick backup
git reset --hard HEAD && git clean -fd       # Nuclear reset
```

### Configuration Commands  
```bash
claude-swarm init                             # Create basic config
claude-swarm generate                         # Interactive config creation
ruby -c claude-swarm.yml                     # Validate syntax
```

---

## 🎯 AIKO Phase 5 Specific Usage

### Standard TDD Flow
```bash
cd /Users/J/aiko
claude-swarm start claude-swarm.yml
# Use TDD commands: /prd → /conTS → /tdd → /dev → /green → /refactor → /qa
```

### YOLO Development (High Risk)
```bash
cd /Users/J/aiko
git stash push -m "pre-yolo-backup"
claude-swarm start claude-swarm.yml --vibe
# Monitor closely, interrupt if needed
# Complete security review after
```

### VanillaIce Integration Test
```bash
# Test VanillaIce integration
/Users/J/.claude/commands/vanillaice-command.sh "Test Phase 5 initialization" --operation consensus

# Then launch swarm
claude-swarm start claude-swarm.yml
```

---

**Remember**: `--vibe` mode removes all safety constraints. Only use when you fully understand the risks and have appropriate backups in place.