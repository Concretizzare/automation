# Quick Start Guide

Get Ralph running on your project in 5 minutes.

## Prerequisites Check

Before starting, verify you have:

```bash
# Check Claude Code CLI
claude --version
# Should show: claude 1.x.x or similar

# Check jq (JSON parser)
jq --version
# Should show: jq-1.x

# Check git
git --version

# Optional: Check Docker (for sandbox mode)
docker --version
```

### Installing Missing Tools

**macOS**:
```bash
# Install Claude Code CLI
# Follow: https://docs.anthropic.com/en/docs/claude-code

# Install jq
brew install jq

# Install notification tool (optional)
brew install terminal-notifier
```

**Linux**:
```bash
# Install jq
sudo apt-get install jq

# Install notification tool (optional)
sudo apt-get install notify-send
```

---

## Step 1: Copy Ralph to Your Project

### Option A: Manual Copy

```bash
# From your project directory
mkdir -p scripts/ralph
cd scripts/ralph

# Copy files (adjust paths to where you cloned ralph-hybrid)
cp /path/to/ralph-hybrid/ralph.sh .
cp /path/to/ralph-hybrid/prompt.md .
cp /path/to/ralph-hybrid/prd.json.example .
cp /path/to/ralph-hybrid/AGENTS.md .

# Make executable
chmod +x ralph.sh
```

### Option B: Git Submodule (Recommended)

```bash
# From your project root
git submodule add https://github.com/YOUR-USERNAME/ralph-hybrid scripts/ralph
cd scripts/ralph
chmod +x ralph.sh
```

---

## Step 2: Create Your First PRD

```bash
cd scripts/ralph

# Copy the example
cp prd.json.example prd.json

# Edit with your stories
nano prd.json  # or vim, code, etc.
```

### Example: Simple Feature Addition

```json
{
  "project": "MyApp",
  "branchName": "ralph/add-user-profile",
  "description": "Add user profile page with avatar upload",
  "userStories": [
    {
      "id": "US-001",
      "title": "Create profile page component",
      "description": "As a user, I want to see my profile information",
      "acceptanceCriteria": [
        "Component renders user name and email",
        "Typecheck passes",
        "Component has basic styling"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    },
    {
      "id": "US-002",
      "title": "Add avatar upload functionality",
      "description": "As a user, I want to upload a profile picture",
      "acceptanceCriteria": [
        "File upload button works",
        "Image preview displays",
        "Upload saves to backend",
        "Typecheck passes"
      ],
      "priority": 2,
      "passes": false,
      "notes": ""
    }
  ]
}
```

### Story Sizing Guidelines

**Good story size** (fits in one iteration):
- ✓ Add a single UI component
- ✓ Add one API endpoint
- ✓ Add a database migration
- ✓ Write tests for one function
- ✓ Add a form with 3-5 fields

**Too large** (split into smaller stories):
- ✗ "Build the entire dashboard"
- ✗ "Add authentication system"
- ✗ "Refactor all API endpoints"

---

## Step 3: Customize for Your Project

Edit `prompt.md` to add project-specific checks:

```bash
nano prompt.md
```

Find the "Common Quality Check Commands" section (~line 85) and customize:

### For TypeScript/React Projects:
```bash
# TypeScript projects
npm run typecheck
npm run lint
npm test
npm run build  # Ensure it builds
```

### For Python Projects:
```bash
# Python projects
mypy .
ruff check .
pytest
python -m myapp --help  # Smoke test
```

### For Go Projects:
```bash
# Go projects
go build ./...
go test ./...
go vet ./...
```

---

## Step 4: Run Ralph

### Basic Run (10 iterations max)

```bash
./ralph.sh
```

### Custom Iteration Count

```bash
./ralph.sh 20  # Run up to 20 iterations
```

### Force Docker Mode

```bash
RALPH_USE_DOCKER=yes ./ralph.sh
```

### Silent Mode (No Notifications)

```bash
RALPH_NOTIFY_TOOL=none ./ralph.sh
```

---

## Step 5: Monitor Progress

### Watch Real-Time Output

Ralph prints output in real-time. You'll see:

```
========================================
Iteration 1/10
Started: 2026-01-19 15:30:45
========================================

Reading PRD...
Reading progress log...
Current branch: ralph/add-user-profile
Working on US-001: Create profile page component
...
```

### Check Story Status

```bash
# See which stories are done
cat prd.json | jq '.userStories[] | {id, title, passes}'
```

Output:
```json
{
  "id": "US-001",
  "title": "Create profile page component",
  "passes": true
}
{
  "id": "US-002",
  "title": "Add avatar upload functionality",
  "passes": false
}
```

### View Learnings

```bash
# See what the agent learned
cat progress.txt
```

### Check Git History

```bash
# See commits made by Ralph
git log --oneline -10
```

---

## Understanding the Output

### Successful Iteration
```
Iteration 1/10
Started: 2026-01-19 15:30:45
========================================
[Claude output showing work]
✓ Typecheck passed
✓ Tests passed
✓ Committed: feat: US-001 - Create profile page component
Updated prd.json: US-001 passes = true
Appended to progress.txt
========================================
Cooling period: 2 seconds...
```

### Completion Signal
```
All stories complete!
<promise>COMPLETE</promise>

========================================
Ralph Loop Complete
Total iterations: 3
Final status: All user stories passing
========================================
```

---

## Common Workflows

### Workflow 1: Start Fresh Feature

```bash
# 1. Create PRD
cp prd.json.example prd.json
# Edit prd.json with stories

# 2. Run Ralph
./ralph.sh

# 3. Review commits
git log --oneline

# 4. Create PR
git push origin ralph/feature-name
```

### Workflow 2: Resume After Failure

```bash
# Ralph creates progress.txt automatically
# Just run again - it picks up where it left off
./ralph.sh
```

### Workflow 3: Split Large PRD

```bash
# Run first batch
./ralph.sh 5

# Check what's done
cat prd.json | jq '.userStories[] | select(.passes == true)'

# Edit prd.json - remove completed stories, add new ones

# Run next batch
./ralph.sh 5
```

---

## Troubleshooting

### "Claude command not found"

```bash
# Install Claude Code CLI
# Follow: https://docs.anthropic.com/en/docs/claude-code

# Or use Docker mode
RALPH_USE_DOCKER=yes ./ralph.sh
```

### "jq: command not found"

```bash
# macOS
brew install jq

# Linux
sudo apt-get install jq
```

### "prd.json: No such file"

```bash
# Copy the example
cp prd.json.example prd.json

# Edit with your stories
nano prd.json
```

### Stories Not Completing

**Check story size**: Stories should be small enough for one iteration
```bash
# If stuck, check progress.txt for errors
cat progress.txt | tail -50
```

**Check quality gates**: Ensure tests/typecheck pass
```bash
# Run checks manually
npm run typecheck
npm test
```

**Check git status**: Ensure clean working tree
```bash
git status
```

### Agent Keeps Failing Same Story

1. Check progress.txt for error patterns
2. Add learnings to Codebase Patterns section
3. Manually fix blocking issue
4. Resume Ralph

### Docker Issues

```bash
# Check Docker is running
docker ps

# Check image exists
docker image inspect claude-code

# Fall back to CLI mode
RALPH_USE_DOCKER=no ./ralph.sh
```

---

## Next Steps

### After Your First Successful Run

1. **Review the commits**:
   ```bash
   git log --oneline -10
   git diff HEAD~3..HEAD  # See last 3 commits
   ```

2. **Check code quality**:
   ```bash
   npm run typecheck
   npm test
   npm run build
   ```

3. **Test in browser** (for frontend changes):
   ```bash
   npm run dev
   # Navigate to changed pages
   ```

4. **Create pull request**:
   ```bash
   git push origin ralph/your-feature
   # Create PR on GitHub/GitLab
   ```

### Improving Ralph for Your Project

1. **Customize prompt.md**:
   - Add project-specific conventions
   - Include common gotchas
   - Add custom quality checks

2. **Create AGENTS.md files**:
   ```bash
   # In key directories
   cat > src/components/AGENTS.md << 'EOF'
   # Component Patterns
   - All components use TypeScript
   - Use shadcn/ui for UI primitives
   - Export types separately
   EOF
   ```

3. **Set up environment variables**:
   ```bash
   # Add to your .zshrc or .bashrc
   export RALPH_USE_DOCKER=yes
   export RALPH_NOTIFY_TOOL=terminal-notifier
   ```

---

## Advanced Usage

### Custom Cooling Period

```bash
# Edit ralph.sh
COOLING_PERIOD=5  # 5 seconds between iterations
```

### Run in Background

```bash
# Run Ralph in background, log to file
nohup ./ralph.sh 20 > ralph.log 2>&1 &

# Watch progress
tail -f ralph.log
```

### Multiple PRDs in Parallel

```bash
# Terminal 1: Frontend stories
cd scripts/ralph-frontend
./ralph.sh

# Terminal 2: Backend stories
cd scripts/ralph-backend
./ralph.sh
```

### Integration with CI/CD

```bash
# .github/workflows/ralph.yml
name: Ralph Auto-Implementation
on:
  workflow_dispatch:
    inputs:
      max_iterations:
        description: 'Max iterations'
        default: '10'

jobs:
  ralph:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Ralph
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          cd scripts/ralph
          ./ralph.sh ${{ github.event.inputs.max_iterations }}
      - name: Create PR
        uses: peter-evans/create-pull-request@v5
        with:
          branch: ralph/auto-implementation
          title: 'Ralph: Auto-implemented PRD stories'
```

---

## Best Practices

### 1. Start Small
- First run: 1-2 simple stories
- Verify Ralph works correctly
- Then tackle larger PRDs

### 2. Quality Gates
- Always include typecheck in acceptance criteria
- Add tests to acceptance criteria
- Never mark story complete without passing checks

### 3. Story Dependencies
- Order stories by dependency (low-level first)
- Database migrations before API endpoints
- API endpoints before UI components

### 4. Context Accumulation
- Ralph learns from progress.txt
- Early iterations set patterns
- Later iterations benefit from learnings

### 5. Branch Hygiene
- One PRD per branch
- Ralph archives on branch change
- Clean branches = clean context

---

## Getting Help

### Check Documentation
- `STRUCTURE.md` - File organization and relationships
- `docs/TROUBLESHOOTING.md` - Common issues
- `docs/ARCHITECTURE.md` - Design decisions

### Debugging Steps
1. Check progress.txt for error messages
2. Run quality checks manually
3. Verify prd.json format
4. Check git status
5. Review recent commits

### Community Resources
- [Original Ralph article](https://ghuntley.com/ralph/)
- [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code)
- [GitHub Issues](https://github.com/YOUR-REPO/issues)

---

## Summary

**Minimum viable setup**:
1. Copy ralph.sh + prompt.md to your project
2. Create prd.json from example
3. Run `./ralph.sh`

**Recommended setup**:
1. Customize prompt.md for your stack
2. Create AGENTS.md in key directories
3. Set environment variables
4. Start with small stories

**Success indicators**:
- Stories marked `passes: true`
- Clean git commits
- Passing quality checks
- Working features

Happy Ralph-ing! 🎉
