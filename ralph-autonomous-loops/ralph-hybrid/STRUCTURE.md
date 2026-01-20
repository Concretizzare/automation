# Project Structure

This document explains the organization and purpose of every file in ralph-hybrid.

## Core Files

### ralph.sh
**Purpose**: Main loop orchestrator
**Lines**: ~300 (with documentation)
**What it does**:
1. Validates environment (checks for required files, tools)
2. Detects execution mode (Docker vs CLI, notification tool)
3. Archives previous runs when branch changes
4. Spawns Claude instances in a loop until completion
5. Captures output and checks for `<promise>COMPLETE</promise>`
6. Manages cooling periods between iterations

**How it works**:
```bash
# Each iteration:
1. Print separator with timestamp
2. Build prompt: prd.json + progress.txt + prompt.md
3. Execute: docker sandbox run OR claude CLI
4. Capture output while displaying in real-time
5. Check for completion signal
6. Wait COOLING_PERIOD seconds
7. Repeat or exit
```

**Key functions**:
- `detect_docker()`: Auto-detects Docker availability
- `detect_notify_tool()`: Finds available notification tool
- `send_notification()`: Sends desktop notification
- `archive_run()`: Archives old runs when branch changes

**Reads**: prompt.md, prd.json, .last-branch
**Writes**: .last-branch, archive/*
**Calls**: Claude Code (via Docker or CLI)

---

### prompt.md
**Purpose**: Agent instructions for each Claude instance
**Lines**: ~150
**What it does**:
- Defines the agent's task and workflow
- Specifies progress report format
- Lists quality requirements
- Explains stop condition

**How Ralph uses it**:
```bash
# Ralph reads this file and passes it to Claude:
cat prompt.md > /tmp/prompt_temp
echo "@prd.json" >> /tmp/prompt_temp
echo "@progress.txt" >> /tmp/prompt_temp
claude < /tmp/prompt_temp
```

**Customization points**:
- Quality check commands (lines 85-100)
- Progress report format (lines 18-32)
- Project-specific conventions
- Additional requirements

**Relationship to ralph.sh**:
- ralph.sh READS prompt.md but never modifies it
- Allows customization without changing shell script
- Can be versioned separately from ralph.sh

---

### prd.json
**Purpose**: Product Requirements Document (user stories)
**Format**: JSON with specific schema
**What it does**:
- Lists all user stories to complete
- Tracks completion status (`passes: true/false`)
- Provides acceptance criteria
- Defines priority order

**Schema**:
```json
{
  "project": "string",
  "branchName": "string",
  "description": "string",
  "userStories": [
    {
      "id": "string",
      "title": "string",
      "description": "string",
      "acceptanceCriteria": ["string"],
      "priority": number,
      "passes": boolean,
      "notes": "string"
    }
  ]
}
```

**Modified by**: Claude agent (sets `passes: true`)
**Read by**: Ralph (checks if all done), Claude agent (picks next story)
**Created from**: prd.json.example (manual copy)

---

### prd.json.example
**Purpose**: Template for creating your PRD
**What it does**:
- Provides example user story format
- Shows proper JSON structure
- Documents all required fields

**Usage**:
```bash
cp prd.json.example prd.json
# Edit prd.json with your stories
```

**NOT used by ralph.sh** - only a template for users

---

### progress.txt
**Purpose**: Append-only learnings log
**Created by**: Ralph (initializes with Codebase Patterns section)
**Written by**: Claude agent (appends progress reports)
**What it does**:
- Preserves context across iterations
- Documents learnings and gotchas
- Provides patterns for future iterations

**Structure**:
```
## Codebase Patterns
[Consolidated reusable patterns]

## [Date/Time] - [Story ID]
Thread: [Link]
- What was implemented
- Files changed
- Learnings for future iterations
---
```

**Why append-only**: Each iteration needs all previous learnings. Never replace, always append.

**Relationship to AGENTS.md**:
- progress.txt = temporal log (story-specific)
- AGENTS.md = permanent knowledge (directory-specific)

---

### AGENTS.md
**Purpose**: Codebase knowledge template
**Where it goes**: In directories throughout the codebase (not in ralph-hybrid/)
**What it does**:
- Documents directory-specific patterns
- Preserves architectural decisions
- Guides future implementations

**Example locations**:
```
src/components/AGENTS.md
src/api/AGENTS.md
tests/AGENTS.md
```

**Updated by**: Claude agent (when discovering reusable patterns)
**Read by**: Claude agent (before working in that directory)

**This file is a template** - shows agents what AGENTS.md files should contain

---

### .gitignore
**Purpose**: Excludes working files from git
**What it excludes**:
```
prd.json          # User-specific PRD
progress.txt      # Append-only log (can be huge)
.last-branch      # Temporary state file
archive/          # Previous runs
```

**Why excluded**:
- prd.json: User-specific, might contain private info
- progress.txt: Can grow very large
- .last-branch: Temporary state, not needed in repo
- archive/: Old runs, not needed in repo

**What IS tracked**: ralph.sh, prompt.md, prd.json.example, AGENTS.md template, documentation

---

### README.md
**Purpose**: Project overview and quick start
**Audience**: First-time users
**What it covers**:
- What Ralph is
- How to install
- Quick start guide
- Configuration options
- File structure overview
- Comparison with source implementations

**Links to**:
- STRUCTURE.md (this file)
- QUICKSTART.md
- docs/ directory

---

## Documentation Files

### docs/ARCHITECTURE.md
**Purpose**: Explains design decisions
**Topics**:
- Why hybrid approach
- Trade-offs made
- Docker vs CLI architecture
- State management design
- Notification system

### docs/TROUBLESHOOTING.md
**Purpose**: Common issues and solutions
**Topics**:
- Docker not found
- prd.json format errors
- Claude permission issues
- Notification failures
- Iteration stuck in loop

### docs/COMPARISON.md
**Purpose**: Detailed comparison with source repos
**Based on**: COMPARISON_SUMMARY.md from code review
**Topics**:
- Feature-by-feature comparison
- What was kept from each source
- Why certain features were chosen
- Evolution from both sources

### docs/CODE_REVIEW.md
**Purpose**: Findings from initial code review
**Topics**:
- Security issues found
- Quality improvements made
- Differences from source repos
- Recommendations for users

---

## Example Files

### examples/fullstack-web-app.prd.json
**Purpose**: Example PRD for a web application
**Shows**:
- Frontend stories (UI components)
- Backend stories (API endpoints)
- Integration stories
- Testing stories

### examples/api-service.prd.json
**Purpose**: Example PRD for an API service
**Shows**:
- Endpoint implementation stories
- Database migration stories
- Testing and documentation

### examples/cli-tool.prd.json
**Purpose**: Example PRD for a CLI tool
**Shows**:
- Command implementation
- Argument parsing
- Help text and docs

---

## Template Files

### templates/progress.txt
**Purpose**: Empty template for progress.txt
**Contains**: Just the Codebase Patterns header

### templates/AGENTS.md
**Purpose**: Empty template for AGENTS.md files
**Contains**: Structure guide for what to include

### templates/.env.example
**Purpose**: Environment variable examples
**Shows**: All RALPH_* variables with descriptions

---

## Generated Files (Not in Repo)

### .last-branch
**Created by**: ralph.sh on first run
**Purpose**: Tracks current branch for archiving
**Content**: Just the branch name
**When updated**: Every iteration (checks for branch changes)

**Used for**:
```bash
# If branch changed since last run:
# Archive prd.json and progress.txt to archive/YYYY-MM-DD-HH-MM-SS-BRANCH/
```

### archive/
**Created by**: ralph.sh when branch changes
**Structure**:
```
archive/
└── 2026-01-19-15-30-45-ralph-feature-auth/
    ├── prd.json
    └── progress.txt
```

**Why archive**: Prevents mixing progress from different branches

---

## File Relationships

### Execution Flow
```
User runs ./ralph.sh
    ↓
ralph.sh reads prompt.md
    ↓
ralph.sh checks .last-branch (archive if changed)
    ↓
ralph.sh spawns Claude with: @prd.json @progress.txt + prompt.md
    ↓
Claude reads prd.json (picks story)
    ↓
Claude reads progress.txt (learns patterns)
    ↓
Claude implements story
    ↓
Claude updates prd.json (sets passes: true)
    ↓
Claude appends to progress.txt
    ↓
ralph.sh checks output for <promise>COMPLETE</promise>
    ↓
Loop or exit
```

### Data Dependencies
```
prd.json ←─ modified by ─ Claude agent
progress.txt ←─ appended by ─ Claude agent
.last-branch ←─ updated by ─ ralph.sh
prompt.md ←─ read by ─ ralph.sh (not modified)
archive/* ←─ created by ─ ralph.sh
```

### Configuration Chain
```
Environment variables (RALPH_*)
    ↓ override
Script defaults (in ralph.sh)
    ↓ controls
Execution behavior (Docker/CLI, notifications)
```

---

## Naming Conventions

### Files
- Scripts: `ralph.sh` (lowercase, .sh extension)
- Documentation: `README.md`, `STRUCTURE.md` (UPPERCASE for main docs)
- Configs: `prd.json`, `.last-branch` (lowercase)
- Templates: `.example` suffix (e.g., `prd.json.example`)

### Directories
- `docs/` - documentation (lowercase)
- `examples/` - example files (lowercase)
- `templates/` - templates (lowercase)
- `archive/` - generated archives (lowercase)

### Variables (in ralph.sh)
- Environment: `RALPH_*` (UPPERCASE with RALPH_ prefix)
- Internal: `lowercase_with_underscores`
- Constants: `UPPERCASE_WITH_UNDERSCORES`

---

## Extension Points

### To Customize Ralph for Your Project

1. **Edit prompt.md**:
   - Add project-specific quality checks
   - Include codebase conventions
   - Modify progress report format

2. **Set environment variables**:
   - Force Docker: `RALPH_USE_DOCKER=yes`
   - Disable notifications: `RALPH_NOTIFY_TOOL=none`

3. **Adjust ralph.sh constants**:
   - `DEFAULT_MAX_ITERATIONS` (line 10)
   - `COOLING_PERIOD` (line 11)

4. **Add project documentation**:
   - Create AGENTS.md in your source directories
   - Document patterns in progress.txt

### To Add Features

- New notification tool: Add to `detect_notify_tool()` and `send_notification()`
- New execution mode: Add to Docker detection logic
- New quality checks: Edit prompt.md (don't modify ralph.sh)

---

## File Size Expectations

| File | Typical Size | Max Recommended |
|------|--------------|-----------------|
| ralph.sh | ~10KB | N/A (script) |
| prompt.md | ~5KB | ~20KB |
| prd.json | ~2-10KB | ~50KB |
| progress.txt | Grows over time | ~500KB (then archive) |
| AGENTS.md | ~1-5KB | ~10KB |

**If progress.txt > 500KB**: Consider archiving old runs and starting fresh

---

## Summary

**Core loop**: ralph.sh → prompt.md → Claude → prd.json + progress.txt
**Memory**: Git history + progress.txt + prd.json + AGENTS.md
**Customization**: Edit prompt.md, not ralph.sh
**State management**: .last-branch tracks archiving
**Knowledge**: progress.txt (temporal) + AGENTS.md (permanent)
