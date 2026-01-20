# Ralph Agent Instructions

## Overview

Ralph is an autonomous AI agent loop that runs Claude Code repeatedly until all PRD items are complete. Each iteration is a fresh Claude instance with clean context.

## How Memory Works

Each iteration spawns a **new Claude instance** with no memory of previous iterations. Memory persists only through:

- **Git history** - Commits from previous iterations
- **progress.txt** - Learnings and context from each iteration
- **prd.json** - Which stories are done (`passes: true`)
- **AGENTS.md files** - Reusable patterns in the codebase

## Key Files

| File | Purpose |
|------|---------|
| `ralph.sh` | Main loop script that spawns Claude instances |
| `prompt.md` | Instructions given to each Claude instance |
| `prd.json` | User stories with `passes` status |
| `progress.txt` | Append-only learnings for future iterations |
| `.last-branch` | Tracks current branch for archiving |
| `archive/` | Previous runs archived by date/branch |

## Commands

```bash
# Run Ralph with default 10 iterations
./ralph.sh

# Run Ralph with custom iteration count
./ralph.sh 20

# Check which stories are done
cat prd.json | jq '.userStories[] | {id, title, passes}'

# See learnings from previous iterations
cat progress.txt

# Check git history
git log --oneline -10
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `RALPH_USE_DOCKER` | `auto` | Docker mode: `auto`, `yes`, or `no` |
| `RALPH_DOCKER_IMAGE` | `claude-code` | Docker image name |
| `RALPH_DOCKER_PERMISSION` | `acceptEdits` | Docker permission mode |
| `RALPH_CLAUDE_PERMISSION` | `--dangerously-skip-permissions` | CLI permission flag |
| `RALPH_NOTIFY_TOOL` | `auto` | Notification tool: `tt`, `terminal-notifier`, `notify-send`, `none` |

## Patterns

- Each iteration = fresh context, no memory
- Stories should be small enough to complete in one context window
- Always read Codebase Patterns section in progress.txt first
- Update AGENTS.md files when you discover reusable patterns
- Keep CI green - broken code compounds across iterations

## Common Gotchas

- Don't work on multiple stories in one iteration
- Always verify UI changes in browser before marking complete
- Run all quality checks before committing
- Never commit broken code
