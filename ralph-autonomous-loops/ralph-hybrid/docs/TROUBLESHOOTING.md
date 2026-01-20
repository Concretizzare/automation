# Troubleshooting Guide

Common issues and solutions when running Ralph.

## Table of Contents

- [Installation Issues](#installation-issues)
- [Configuration Issues](#configuration-issues)
- [Runtime Issues](#runtime-issues)
- [Story Completion Issues](#story-completion-issues)
- [Docker Issues](#docker-issues)
- [Git Issues](#git-issues)
- [Notification Issues](#notification-issues)
- [Performance Issues](#performance-issues)

---

## Installation Issues

### "claude: command not found"

**Problem**: Claude Code CLI is not installed or not in PATH.

**Solution**:
```bash
# Check if Claude is installed
which claude

# If not found, install Claude Code CLI
# Follow: https://docs.anthropic.com/en/docs/claude-code

# Verify installation
claude --version

# Alternative: Use Docker mode
RALPH_USE_DOCKER=yes ./ralph.sh
```

**Workaround**:
```bash
# Force Docker mode permanently
export RALPH_USE_DOCKER=yes
./ralph.sh
```

---

### "jq: command not found"

**Problem**: jq JSON parser is not installed.

**Solution**:

**macOS**:
```bash
brew install jq
```

**Linux (Debian/Ubuntu)**:
```bash
sudo apt-get update
sudo apt-get install jq
```

**Linux (RedHat/CentOS)**:
```bash
sudo yum install jq
```

**Verify**:
```bash
jq --version
```

---

### "Permission denied: ./ralph.sh"

**Problem**: Ralph script is not executable.

**Solution**:
```bash
chmod +x ralph.sh
./ralph.sh
```

**Verify**:
```bash
ls -l ralph.sh
# Should show: -rwxr-xr-x (note the x flags)
```

---

## Configuration Issues

### "prd.json: No such file or directory"

**Problem**: PRD file not created.

**Solution**:
```bash
# Copy the example
cp prd.json.example prd.json

# Edit with your stories
nano prd.json
# or
code prd.json
```

**Validation**:
```bash
# Verify JSON is valid
jq . prd.json

# Check structure
jq '.userStories | length' prd.json
```

---

### "prompt.md: No such file or directory"

**Problem**: Prompt file missing (shouldn't happen in normal setup).

**Solution**:
```bash
# If you're in scripts/ralph/, check files
ls -la

# prompt.md should exist
# If missing, copy from ralph-hybrid repo
cp /path/to/ralph-hybrid/prompt.md .
```

---

### "Invalid JSON in prd.json"

**Problem**: Syntax error in prd.json.

**Symptoms**:
```bash
jq . prd.json
# parse error: Invalid numeric literal at line X, column Y
```

**Solution**:
```bash
# Validate JSON
jq . prd.json

# Common issues:
# 1. Missing comma between objects
# 2. Trailing comma in last item
# 3. Unescaped quotes in strings
# 4. Wrong boolean (true/false, not "true"/"false")

# Example fix:
{
  "passes": false,  # ← Add comma here if there's another field
  "notes": ""       # ← No comma here (last field)
}
```

**Use a JSON validator**:
- VS Code: Install "JSON Tools" extension
- Online: https://jsonlint.com/

---

## Runtime Issues

### Ralph stops after first iteration

**Problem**: Completion signal detected too early.

**Diagnosis**:
```bash
# Check if <promise>COMPLETE</promise> appears in output
./ralph.sh 2>&1 | grep COMPLETE

# Check prd.json status
jq '.userStories[] | {id, passes}' prd.json
```

**Possible causes**:
1. All stories already marked `passes: true`
2. Claude output contains completion signal prematurely
3. Story acceptance criteria too easy

**Solution**:
```bash
# Reset story status
jq '.userStories[].passes = false' prd.json > prd.tmp.json && mv prd.tmp.json prd.json

# Run again
./ralph.sh
```

---

### "Not a git repository"

**Problem**: Ralph requires git repository.

**Solution**:
```bash
# Initialize git if needed
git init

# Create initial commit
git add .
git commit -m "Initial commit"

# Run Ralph
./ralph.sh
```

---

### Iterations keep failing with same error

**Problem**: Recurring issue blocking progress.

**Diagnosis**:
```bash
# Check last 100 lines of progress.txt
tail -100 progress.txt

# Look for repeated error patterns
grep -i error progress.txt | tail -20
```

**Solutions**:

**1. Quality checks failing**:
```bash
# Run checks manually
npm run typecheck  # or your project's command
npm test

# Fix issues manually
# Then resume Ralph
./ralph.sh
```

**2. Missing dependencies**:
```bash
# Install missing packages
npm install
# or
pip install -r requirements.txt

# Resume Ralph
./ralph.sh
```

**3. Story too large**:
```bash
# Split into smaller stories
# Edit prd.json:
{
  "id": "US-001-A",
  "title": "First part of large story",
  "priority": 1,
  ...
},
{
  "id": "US-001-B",
  "title": "Second part of large story",
  "priority": 2,
  ...
}
```

**4. Add guidance to progress.txt**:
```bash
# Manually add pattern to help future iterations
cat >> progress.txt << 'EOF'

## Codebase Patterns
- When implementing X, remember to update Y
- Use pattern Z for this type of change
- Check file W before modifying V
EOF
```

---

### API rate limiting

**Problem**: Too many requests to Claude API.

**Symptoms**:
- Errors mentioning rate limits
- 429 HTTP status codes
- Slow responses

**Solution**:
```bash
# Increase cooling period
# Edit ralph.sh:
COOLING_PERIOD=5  # Increase from 2 to 5 seconds

# Or set via environment
RALPH_COOLING_PERIOD=10 ./ralph.sh
```

**Long-term**:
- Split PRD into smaller batches
- Run during off-peak hours
- Upgrade API tier

---

## Story Completion Issues

### Stories never marked complete

**Problem**: Agent doesn't update prd.json.

**Diagnosis**:
```bash
# Check if prd.json is being modified
git status prd.json

# Check last iteration's output
tail -200 progress.txt
```

**Possible causes**:

**1. Quality checks failing**:
```bash
# Run checks manually
npm run typecheck
npm test

# Look for failures
```

**2. Agent confused about task**:
- Story description unclear
- Acceptance criteria ambiguous
- Conflicting requirements

**Solution**:
```bash
# Clarify story in prd.json
{
  "description": "More specific description here",
  "acceptanceCriteria": [
    "Very specific criterion 1",
    "Measurable criterion 2",
    "Typecheck passes"  # Always include
  ]
}
```

**3. File permission issues**:
```bash
# Check prd.json is writable
ls -l prd.json

# Fix permissions
chmod 644 prd.json
```

---

### Agent marks story complete too early

**Problem**: Story marked done but not fully implemented.

**Prevention**:
```bash
# Add strict acceptance criteria
{
  "acceptanceCriteria": [
    "Feature works in browser",
    "All tests pass",
    "Typecheck passes",
    "No console errors",
    "Meets design specs"
  ]
}
```

**After the fact**:
```bash
# Reset story status
jq '(.userStories[] | select(.id == "US-001") | .passes) = false' prd.json > prd.tmp.json && mv prd.tmp.json prd.json

# Add more specific criteria
# Run again
./ralph.sh
```

---

### Agent skips stories

**Problem**: Some stories never attempted.

**Diagnosis**:
```bash
# Check priority ordering
jq '.userStories[] | {id, priority, passes}' prd.json

# Check for dependencies
grep -i "depends\|requires" prd.json
```

**Solution**:

**1. Fix priority order**:
```bash
# Ensure priorities are sequential
# Edit prd.json:
{
  "userStories": [
    {"priority": 1, ...},  # Will be done first
    {"priority": 2, ...},  # Will be done second
    {"priority": 3, ...}   # Will be done third
  ]
}
```

**2. Add dependency notes**:
```bash
{
  "id": "US-002",
  "notes": "Depends on US-001. Should implement database schema first."
}
```

---

## Docker Issues

### "Cannot connect to Docker daemon"

**Problem**: Docker not running or not accessible.

**Diagnosis**:
```bash
# Check Docker status
docker ps

# Check Docker is running
docker info
```

**Solutions**:

**macOS**:
```bash
# Start Docker Desktop
open /Applications/Docker.app

# Wait for Docker to start (check menu bar icon)

# Verify
docker ps
```

**Linux**:
```bash
# Start Docker service
sudo systemctl start docker

# Enable auto-start
sudo systemctl enable docker

# Add user to docker group (to run without sudo)
sudo usermod -aG docker $USER
# Log out and back in

# Verify
docker ps
```

**Workaround**:
```bash
# Use CLI mode instead
RALPH_USE_DOCKER=no ./ralph.sh
```

---

### "No such image: claude-code"

**Problem**: Docker image not available.

**Solution**:
```bash
# Check available images
docker images | grep claude

# Pull Claude Code image (if available)
docker pull claude-code:latest

# Or build custom image
# Create Dockerfile:
cat > Dockerfile << 'EOF'
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y claude-cli
# Add other dependencies
EOF

docker build -t claude-code .
```

**Workaround**:
```bash
# Use different image
RALPH_DOCKER_IMAGE=my-claude-image ./ralph.sh

# Or use CLI mode
RALPH_USE_DOCKER=no ./ralph.sh
```

---

### Docker permissions error

**Problem**: Permission denied when running Docker.

**Linux solution**:
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and log back in
# Or use newgrp:
newgrp docker

# Verify
docker ps
```

**macOS**:
- Should not occur (Docker Desktop handles permissions)
- If it does, reinstall Docker Desktop

---

## Git Issues

### "Detached HEAD state"

**Problem**: Not on a branch.

**Solution**:
```bash
# Check current state
git branch

# Create and checkout branch
git checkout -b ralph/my-feature

# Or switch to existing branch
git checkout main
```

---

### Merge conflicts in prd.json

**Problem**: Manual edits conflicting with Ralph's updates.

**Prevention**:
- Don't edit prd.json while Ralph is running
- Let Ralph finish before making changes

**Solution**:
```bash
# Resolve conflict
git status  # Shows conflicted files

# Edit prd.json, remove conflict markers
nano prd.json

# Mark as resolved
git add prd.json
git commit -m "Resolve prd.json conflict"

# Resume Ralph
./ralph.sh
```

---

### Too many commits

**Problem**: Ralph created 100+ commits.

**Solution (before merging)**:
```bash
# Squash all Ralph commits
git rebase -i main

# In editor, change all but first "pick" to "squash"
# Save and exit

# Edit commit message
# Save and exit

# Force push (if already pushed)
git push --force-with-lease origin your-branch
```

---

## Notification Issues

### No notifications appearing

**Problem**: Notification tool not working.

**Diagnosis**:
```bash
# Check detected tool
./ralph.sh 2>&1 | grep "Notify tool"

# Test notification manually
terminal-notifier -message "Test" -title "Ralph Test"
# or
notify-send "Ralph Test" "Test message"
# or
tt "Test message"
```

**Solutions**:

**1. Install notification tool**:
```bash
# macOS
brew install terminal-notifier

# Linux
sudo apt-get install libnotify-bin

# Or install tt (cross-platform)
# Follow: https://github.com/loteoo/tt
```

**2. Force specific tool**:
```bash
RALPH_NOTIFY_TOOL=terminal-notifier ./ralph.sh
```

**3. Disable notifications**:
```bash
RALPH_NOTIFY_TOOL=none ./ralph.sh
```

---

### Notification tool crashes

**Problem**: Notification command fails.

**Workaround**:
```bash
# Disable notifications to continue
RALPH_NOTIFY_TOOL=none ./ralph.sh
```

**Debug**:
```bash
# Test the failing tool directly
terminal-notifier -message "Test" -title "Test"

# Check error message
# Fix or report issue to tool's repo
```

---

## Performance Issues

### Iterations taking too long

**Problem**: Each iteration takes 5+ minutes.

**Possible causes**:

**1. Large context window**:
```bash
# Check progress.txt size
du -h progress.txt

# If >500KB, consider archiving
mv progress.txt archive/progress-old.txt

# Start fresh (keep patterns)
head -50 archive/progress-old.txt > progress.txt
```

**2. Slow quality checks**:
```bash
# Time your checks
time npm run typecheck
time npm run test

# Optimize slow tests
# Skip slow tests in Ralph, run separately:
# Edit prompt.md quality checks
```

**3. Network latency**:
- Check internet connection
- Try different time of day
- Consider upgrading API tier

**4. Large codebase**:
- Use `.gitignore` to exclude large files
- Exclude `node_modules`, `dist`, etc.

---

### High API costs

**Problem**: Using too many tokens/requests.

**Solutions**:

**1. Optimize story size**:
- Smaller stories = fewer tokens per iteration
- More focused context

**2. Better progress.txt**:
- Clear patterns prevent repeated work
- Consolidated learnings

**3. Reduce iterations**:
```bash
# Review progress after fewer iterations
./ralph.sh 3

# Check what's done
jq '.userStories[] | {id, passes}' prd.json

# Continue if needed
./ralph.sh 3
```

**4. Use haiku model** (if supported):
```bash
# Configure Claude to use cheaper model
# (Implementation-dependent)
```

---

## Advanced Debugging

### Enable verbose logging

```bash
# Add to ralph.sh for debugging
set -x  # Print all commands

./ralph.sh 2>&1 | tee ralph-debug.log

set +x  # Disable after debugging
```

---

### Inspect Claude's context

```bash
# See what Claude receives
cat /tmp/prompt_temp 2>/dev/null

# If file doesn't exist, add to ralph.sh:
# cat "$PROMPT_FILE" > /tmp/prompt_debug
# echo "@prd.json" >> /tmp/prompt_debug
# echo "@progress.txt" >> /tmp/prompt_debug
```

---

### Check iteration output

```bash
# Ralph captures output to detect completion
# Add logging to see full output:

# In ralph.sh, modify the execution line:
claude ... | tee /tmp/ralph-iteration-$i.log
```

---

### Manual iteration

```bash
# Run a single Claude instance manually
cat prompt.md > /tmp/manual_prompt
echo "@prd.json" >> /tmp/manual_prompt
echo "@progress.txt" >> /tmp/manual_prompt

claude < /tmp/manual_prompt

# Observe behavior
# Check if story gets marked complete
jq '.userStories[] | {id, passes}' prd.json
```

---

## Getting Help

### Before reporting issues

1. **Check this guide** for your specific error
2. **Read error messages** carefully
3. **Check logs**: progress.txt, git log, console output
4. **Verify files**: prd.json format, prompt.md exists
5. **Test components**: Claude CLI, jq, git, Docker

### Information to include in reports

```bash
# Environment info
uname -a
claude --version
jq --version
docker --version
git --version

# Ralph version
head -5 ralph.sh  # Shows version in comments

# prd.json structure
jq '.userStories | length' prd.json

# Last 50 lines of progress.txt
tail -50 progress.txt

# Recent git history
git log --oneline -10

# Error message (full text)
```

### Where to get help

- GitHub Issues: [YOUR-REPO/issues](https://github.com/YOUR-REPO/issues)
- Documentation: README.md, STRUCTURE.md, ARCHITECTURE.md
- Original Ralph: https://github.com/snarktank/ralph
- Claude Code docs: https://docs.anthropic.com/en/docs/claude-code

---

## Quick Reference

### Common commands

```bash
# Check story status
jq '.userStories[] | {id, passes}' prd.json

# Validate prd.json
jq . prd.json

# View recent learnings
tail -100 progress.txt

# Check recent commits
git log --oneline -10

# Test Docker
docker ps

# Test notifications
terminal-notifier -message "Test" -title "Test"

# Run Ralph with custom settings
RALPH_USE_DOCKER=no RALPH_NOTIFY_TOOL=none ./ralph.sh 5
```

### Emergency recovery

```bash
# Ralph stuck in infinite loop
Ctrl+C  # Stop it

# Reset prd.json to last good state
git restore prd.json

# Archive current run
mkdir -p archive/manual-$(date +%Y-%m-%d)
cp prd.json progress.txt archive/manual-$(date +%Y-%m-%d)/

# Start fresh
cp prd.json.example prd.json
echo "## Codebase Patterns" > progress.txt
```
