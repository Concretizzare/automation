# Ralph Hybrid

A hybrid implementation of the Ralph autonomous AI agent loop, combining the best features from two implementations:

- **[ralph](https://github.com/snarktank/ralph)** (original, production-ready): Robust archiving, error handling, external prompt file, rich progress tracking
- **ralph-wiggum** (Claude Code port): Docker sandbox isolation, desktop notifications, simplified execution

Based on [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/).

## Table of Contents

- [What is Ralph?](#what-is-ralph)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Documentation](#documentation)
- [Hybrid Features](#hybrid-features)
- [Configuration](#configuration)
- [File Structure](#file-structure)
- [How It Works](#how-it-works)
- [Examples](#examples)
- [Contributing](#contributing)
- [License](#license)

## What is Ralph?

Ralph is an autonomous AI agent loop that runs Claude Code repeatedly until all PRD (Product Requirements Document) items are complete. Each iteration is a fresh Claude instance with clean context. Memory persists via git history, `progress.txt`, and `prd.json`.

**New to Ralph?** Start with [QUICKSTART.md](QUICKSTART.md) for step-by-step setup.

## Prerequisites

- **Claude Code CLI** (`claude`) OR Docker with Claude Code image
- **jq** for JSON parsing (`brew install jq` on macOS, `apt-get install jq` on Linux)
- A **git repository** for your project

### Optional

- **tt** / **terminal-notifier** / **notify-send** for desktop notifications

## Quick Start

1. **Copy Ralph to your project:**

```bash
mkdir -p scripts/ralph
cp ralph.sh prompt.md scripts/ralph/
chmod +x scripts/ralph/ralph.sh
```

2. **Create your PRD:**

```bash
cp prd.json.example scripts/ralph/prd.json
# Edit prd.json with your user stories
```

3. **Run Ralph:**

```bash
./scripts/ralph/ralph.sh
```

## Documentation

### Getting Started
- [QUICKSTART.md](QUICKSTART.md) - Step-by-step setup and first run
- [README.md](README.md) - This file (overview and quick reference)

### Understanding Ralph
- [STRUCTURE.md](STRUCTURE.md) - Detailed explanation of every file and how they relate
- [ARCHITECTURE.md](docs/ARCHITECTURE.md) - Design decisions and how Ralph works internally
- [COMPARISON.md](docs/COMPARISON.md) - Feature-by-feature comparison with source implementations

### Using Ralph
- [examples/](examples/) - Example PRD files for different project types:
  - [fullstack-web-app.prd.json](examples/fullstack-web-app.prd.json) - Full-stack web application
  - [api-service.prd.json](examples/api-service.prd.json) - REST API service
  - [cli-tool.prd.json](examples/cli-tool.prd.json) - Command-line tool
- [templates/](templates/) - Template files for starting new projects

### Troubleshooting & Contributing
- [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - Common issues and solutions
- [CODE_REVIEW.md](docs/CODE_REVIEW.md) - Code review findings and quality assessment
- [CONTRIBUTING.md](CONTRIBUTING.md) - How to contribute to Ralph-Hybrid

## Hybrid Features

### From ralph (original)

| Feature | Description |
|---------|-------------|
| **External prompt.md** | Full agent instructions in separate file for easy customization |
| **Automatic archiving** | Archives previous runs when branch changes |
| **Branch tracking** | Tracks current branch in `.last-branch` |
| **Progress initialization** | Creates structured progress.txt with Codebase Patterns section |
| **Robust error handling** | Uses `|| true` to prevent premature exits |
| **Cooling period** | Configurable delay between iterations to prevent rate limiting |
| **Rich progress format** | Structured logging with thread links and learnings |
| **AGENTS.md updates** | Instructions for updating codebase knowledge |

### From ralph-wiggum (Claude Code port)

| Feature | Description |
|---------|-------------|
| **Docker sandbox** | Optional Docker isolation via `docker sandbox run` |
| **Desktop notifications** | Completion notifications via tt/terminal-notifier/notify-send |
| **@file syntax** | Uses Claude Code's native file reference syntax |
| **Simple completion check** | Clean grep for `<promise>COMPLETE</promise>` |

### Hybrid Improvements

| Feature | Description |
|---------|-------------|
| **Docker auto-detection** | Automatically detects if Docker/claude CLI is available |
| **Configurable notification tool** | Supports multiple notification tools with fallback |
| **Required file validation** | Checks prd.json and prompt.md exist before starting |
| **Visual iteration markers** | Clear separator between iterations with timestamps |
| **Environment variables** | All settings configurable via environment variables |
| **Cross-platform** | Works on macOS and Linux |

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `RALPH_USE_DOCKER` | `auto` | `auto` (detect), `yes` (force Docker), `no` (force CLI) |
| `RALPH_DOCKER_IMAGE` | `claude-code` | Docker image to use |
| `RALPH_DOCKER_PERMISSION` | `acceptEdits` | Docker sandbox permission mode |
| `RALPH_CLAUDE_PERMISSION` | `--dangerously-skip-permissions` | Claude CLI permission flag |
| `RALPH_NOTIFY_TOOL` | `auto` | `tt`, `terminal-notifier`, `notify-send`, `none`, or `auto` |
| `RALPH_COOLING_PERIOD` | `2` | Seconds between iterations (also supports `COOLING_PERIOD`) |
| `RALPH_MAX_ITERATIONS` | `10` | Max iterations (also supports `MAX_ITERATIONS`) |
| `ANTHROPIC_API_KEY` | (required) | API key for Claude CLI |

**Note**: `RALPH_*` prefixed variables take precedence over non-prefixed versions. Command line argument takes precedence over environment variables for iteration count.

## File Structure

```
ralph-hybrid/
├── ralph.sh           # Main loop script
├── prompt.md          # Agent instructions (customizable)
├── prd.json.example   # Example PRD format
├── AGENTS.md          # Codebase knowledge template
├── README.md          # This file
└── .gitignore         # Excludes working files

# Generated during runs:
├── prd.json           # Your actual PRD (copy from example)
├── progress.txt       # Append-only learnings
├── .last-branch       # Branch tracking for archiving
└── archive/           # Archived previous runs
```

## PRD Format

```json
{
  "project": "MyApp",
  "branchName": "ralph/feature-name",
  "description": "Feature description",
  "userStories": [
    {
      "id": "US-001",
      "title": "Story title",
      "description": "As a user, I want...",
      "acceptanceCriteria": [
        "Criterion 1",
        "Criterion 2",
        "Typecheck passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

## How It Works

1. **Iteration Start**: Ralph prints a separator and timestamp
2. **Context Building**: Combines @prd.json, @progress.txt, and prompt.md
3. **Claude Execution**: Runs via Docker sandbox or direct CLI
4. **Output Capture**: Displays output in real-time while capturing for analysis
5. **Completion Check**: Looks for `<promise>COMPLETE</promise>` in output
6. **Cooling Period**: Waits briefly before next iteration (prevents rate limiting)
7. **Archiving**: On branch change, archives previous prd.json and progress.txt

## Customizing prompt.md

Edit `prompt.md` to customize agent behavior:

- Add project-specific quality check commands
- Include codebase conventions
- Add common gotchas for your stack
- Modify the progress report format

## Debugging

```bash
# See which stories are done
cat prd.json | jq '.userStories[] | {id, title, passes}'

# See learnings from previous iterations
cat progress.txt

# Check git history
git log --oneline -10

# Test Docker availability
docker image inspect claude-code

# Test notification
RALPH_NOTIFY_TOOL=terminal-notifier ./ralph.sh 1
```

## Critical Concepts

### Fresh Context Per Iteration

Each iteration spawns a **new Claude instance** with no memory. The only persistence is:

- Git history (commits from previous iterations)
- progress.txt (learnings and context)
- prd.json (which stories are done)
- AGENTS.md files (codebase knowledge)

### Small Tasks

Each PRD item should be small enough to complete in one context window.

**Right-sized stories:**
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

**Too big (split these):**
- "Build the entire dashboard"
- "Add authentication"
- "Refactor the API"

### Stop Condition

When all stories have `passes: true`, the agent outputs `<promise>COMPLETE</promise>` and the loop exits.

## Examples

Ralph-Hybrid includes three comprehensive example PRDs for different project types:

### Full-Stack Web App
[examples/fullstack-web-app.prd.json](examples/fullstack-web-app.prd.json)

A task management application with React frontend, Node.js backend, and PostgreSQL:
- 15 user stories covering database, API, and UI
- Full CRUD operations
- Drag-and-drop task management
- E2E testing story

### API Service
[examples/api-service.prd.json](examples/api-service.prd.json)

A weather API service with rate limiting and caching:
- Authentication with API keys
- Multiple data sources with fallback
- Redis caching
- OpenAPI documentation
- Docker deployment

### CLI Tool
[examples/cli-tool.prd.json](examples/cli-tool.prd.json)

A git workflow CLI tool with automation:
- Conventional commits
- PR creation
- Git hooks
- Configuration file support
- Tab autocomplete

**Using Examples**: Copy an example as your starting point
```bash
cp examples/fullstack-web-app.prd.json scripts/ralph/prd.json
# Edit to match your project
```

## Comparison with Source Implementations

| Feature | ralph (original) | ralph-wiggum | ralph-hybrid |
|---------|------------------|--------------|--------------|
| Claude Code support | No (Amp) | Yes (Docker) | Yes (Docker + CLI) |
| External prompt file | Yes | No (inline) | Yes |
| Archiving | Yes | No | Yes |
| Notifications | No | Yes (tt) | Yes (multi-tool) |
| Error handling | Yes (`\|\| true`) | Basic | Yes |
| Progress format | Rich | Basic | Rich |
| Docker support | No | Yes (required) | Yes (optional) |
| Configuration | Hardcoded | Hardcoded | Environment vars |

See [docs/COMPARISON.md](docs/COMPARISON.md) for detailed feature-by-feature comparison.

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

**Quick contribution checklist**:
- Test on macOS and Linux
- Run `shellcheck ralph.sh`
- Update documentation if behavior changes
- Add examples for new features

## License

MIT

## References

- [Geoffrey Huntley's Ralph article](https://ghuntley.com/ralph/)
- [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Original ralph repository](https://github.com/snarktank/ralph)
