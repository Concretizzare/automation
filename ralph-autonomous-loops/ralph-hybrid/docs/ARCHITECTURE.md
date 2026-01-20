# Architecture

This document explains the design decisions behind ralph-hybrid and how it evolved from both source implementations.

## Design Philosophy

### Core Principle: Stateless Iterations with Persistent Memory

Each Claude instance runs **completely fresh** with no memory of previous iterations. All context must be explicitly provided through:

1. **Git history** - Code changes from previous iterations
2. **progress.txt** - Append-only learnings log
3. **prd.json** - Story completion status
4. **AGENTS.md files** - Permanent codebase knowledge

This architecture prevents:
- Context window bloat
- Drift from actual code state
- Memory hallucinations
- Confusion between attempts

---

## Hybrid Design Rationale

### Why Combine Two Implementations?

**Original Ralph (snarktank/ralph)**: Production-ready but tied to Amp CLI
**Ralph-Wiggum**: Claude Code support but minimal features

**Goal**: Best of both worlds
- Production-ready state management (from original)
- Claude Code integration (from wiggum)
- Enhanced with auto-detection and cross-platform support

### Feature Selection Matrix

| Feature | Source | Why Included | Alternative Considered |
|---------|--------|--------------|------------------------|
| External prompt.md | Original | Customization without touching shell script | Inline prompt (rejected: harder to customize) |
| Docker sandbox | Wiggum | Isolation and reproducibility | Direct CLI only (rejected: less safe) |
| Automatic archiving | Original | Prevents context mixing across branches | Manual archiving (rejected: error-prone) |
| Desktop notifications | Wiggum | User awareness of completion | No notifications (rejected: less user-friendly) |
| Auto-detection | Hybrid | Works out of box for most users | Require explicit config (rejected: poor UX) |
| Environment variables | Hybrid | Flexible configuration | Hardcoded settings (rejected: not portable) |

---

## System Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         User                                 │
└────────────────────┬────────────────────────────────────────┘
                     │ runs ./ralph.sh
                     ↓
┌─────────────────────────────────────────────────────────────┐
│                     ralph.sh                                 │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  1. Initialization                                    │   │
│  │     - Detect Docker/CLI                               │   │
│  │     - Detect notification tool                        │   │
│  │     - Validate required files                         │   │
│  │     - Check for branch change (archive if needed)     │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  2. Iteration Loop                                    │   │
│  │     - Build prompt (prd + progress + prompt.md)       │   │
│  │     - Execute Claude (Docker or CLI)                  │   │
│  │     - Capture output                                  │   │
│  │     - Check for completion signal                     │   │
│  │     - Cooling period                                  │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  3. Completion                                        │   │
│  │     - Send notification                               │   │
│  │     - Print summary                                   │   │
│  └──────────────────────────────────────────────────────┘   │
└────────────────────┬────────────────────────────────────────┘
                     │ spawns
                     ↓
┌─────────────────────────────────────────────────────────────┐
│              Claude Code Instance                            │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Context:                                             │   │
│  │  - @prd.json (user stories)                           │   │
│  │  - @progress.txt (learnings)                          │   │
│  │  - prompt.md (instructions)                           │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Workflow:                                            │   │
│  │  1. Read Codebase Patterns from progress.txt         │   │
│  │  2. Pick highest priority incomplete story           │   │
│  │  3. Implement the story                               │   │
│  │  4. Run quality checks                                │   │
│  │  5. Commit if passing                                 │   │
│  │  6. Update prd.json (set passes: true)                │   │
│  │  7. Append learnings to progress.txt                  │   │
│  │  8. Output <promise>COMPLETE</promise> if all done    │   │
│  └──────────────────────────────────────────────────────┘   │
└────────────────────┬────────────────────────────────────────┘
                     │ modifies
                     ↓
┌─────────────────────────────────────────────────────────────┐
│                  Persistent State                            │
│  ┌──────────────┬──────────────┬──────────────┬──────────┐  │
│  │ Git History  │ prd.json     │ progress.txt │ AGENTS.md│  │
│  │ (commits)    │ (status)     │ (learnings)  │ (patterns)│ │
│  └──────────────┴──────────────┴──────────────┴──────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## State Management Design

### Why Append-Only progress.txt?

**Problem**: Each iteration is a fresh Claude instance with no memory.

**Solution**: Append-only log that accumulates context over time.

**Design decisions**:
1. **Append, never replace**: Future iterations need all learnings
2. **Structured format**: Date/time, story ID, thread link for traceability
3. **Codebase Patterns section**: Consolidated knowledge at the top (most important)
4. **Story-specific learnings**: Details about each implementation

**Alternatives considered**:
- SQLite database (rejected: overkill, harder to inspect)
- JSON log (rejected: harder to read/append)
- Git commit messages only (rejected: insufficient detail)

### Why External prompt.md?

**Problem**: Different projects have different quality checks, conventions, and requirements.

**Solution**: Separate instructions file that's easy to customize.

**Benefits**:
1. Users can modify behavior without touching shell script
2. Prompts can be versioned separately from ralph.sh
3. Easier to share prompt improvements
4. Project-specific prompts can be maintained

**Alternatives considered**:
- Inline prompt in ralph.sh (rejected: hard to customize)
- Multiple prompt files (rejected: confusing)
- Prompt in prd.json (rejected: mixes concerns)

### Why prd.json Instead of TODO Comments?

**Problem**: Need machine-readable story tracking with status.

**Solution**: JSON file with structured user stories.

**Benefits**:
1. Machine-parseable (jq can query status)
2. Structured acceptance criteria
3. Priority ordering
4. Notes field for context
5. Easy to validate format

**Alternatives considered**:
- TODO comments in code (rejected: hard to parse, no structure)
- GitHub Issues (rejected: requires network, harder to iterate locally)
- Markdown checklist (rejected: no machine-parseable status)

---

## Execution Mode Architecture

### Docker vs CLI Decision Tree

```
ralph.sh starts
     ↓
Check RALPH_USE_DOCKER env var
     ↓
┌────────────┬─────────────┬───────────┐
│ "yes"      │ "no"        │ "auto"    │
│            │             │ (default) │
└────┬───────┴─────┬───────┴─────┬─────┘
     ↓             ↓             ↓
Use Docker    Use CLI    Detect available
     ↓             ↓             ↓
     │             │     ┌───────────────┐
     │             │     │ Docker found? │
     │             │     └───┬───────┬───┘
     │             │         │ Yes   │ No
     │             │         ↓       ↓
     │             │    Use Docker  Use CLI
     └─────────────┴─────────┴───────┘
                   ↓
            Execute Claude
```

**Why auto-detection?**
- Best UX: Works without configuration
- Prefers Docker for isolation
- Falls back to CLI gracefully
- User can override if needed

### Docker Sandbox Isolation

**Benefits**:
1. **File system isolation**: Changes contained
2. **Network isolation**: Can be controlled
3. **Reproducibility**: Same image = same environment
4. **Safety**: Can't accidentally modify system files

**Trade-offs**:
1. **Performance**: Slight overhead (~100-200ms per iteration)
2. **Complexity**: Requires Docker installation
3. **Image size**: Need to build/pull claude-code image

**When to use CLI mode**:
- Docker not available
- Performance critical (many short iterations)
- Already running in isolated environment (CI/CD)

---

## Notification System Design

### Multi-Tool Support

**Problem**: Different platforms, different notification tools.

**Solution**: Auto-detect available tool with fallback chain.

**Detection order**:
1. `tt` (terminal-timer, fastest)
2. `terminal-notifier` (macOS standard)
3. `notify-send` (Linux standard)
4. `none` (silent fallback)

**Why this order?**
- `tt` is fastest if available
- `terminal-notifier` is most common on macOS
- `notify-send` is standard on Linux
- Failing gracefully is better than erroring

**Design principle**: Notifications are **nice-to-have**, not **required**. Ralph works fine without them.

---

## Archiving Strategy

### Automatic Branch-Based Archiving

**Problem**: Switching branches mixes context from different features.

**Solution**: Detect branch changes and archive previous run.

**Implementation**:
```bash
# ralph.sh checks .last-branch on each run
current_branch=$(git branch --show-current)
last_branch=$(cat .last-branch 2>/dev/null || echo "")

if [ "$current_branch" != "$last_branch" ]; then
  # Archive prd.json and progress.txt
  timestamp=$(date +%Y-%m-%d-%H-%M-%S)
  archive_dir="archive/${timestamp}-${last_branch}"
  mkdir -p "$archive_dir"
  mv prd.json progress.txt "$archive_dir/" 2>/dev/null || true
fi

echo "$current_branch" > .last-branch
```

**Why branch-based?**
- Different branches = different features = different context
- Prevents mixing learnings from unrelated work
- Archives are timestamped for reference

**Alternatives considered**:
- Manual archiving (rejected: users forget)
- Always archive (rejected: wastes disk space)
- Never archive (rejected: context pollution)

---

## Error Handling Philosophy

### Fail-Safe Defaults

**Principle**: Ralph should survive errors and provide useful feedback.

**Implementations**:

1. **File validation before starting**:
   ```bash
   if [ ! -f "prd.json" ]; then
     echo "ERROR: prd.json not found"
     exit 1
   fi
   ```

2. **Graceful fallbacks**:
   ```bash
   detect_docker || echo "Docker not found, using CLI mode"
   detect_notify_tool || echo "No notification tool, continuing silently"
   ```

3. **Safe cleanup**:
   ```bash
   # Never fail on cleanup
   rm -f /tmp/prompt_temp 2>/dev/null || true
   ```

4. **Cooling period on errors**:
   - Even if iteration fails, wait before retrying
   - Prevents rapid-fire errors (rate limiting protection)

**From original Ralph**: Liberal use of `|| true` to prevent premature exits

**Enhanced in hybrid**: Better error messages and validation

---

## Memory Architecture

### Four-Layer Memory System

#### Layer 1: Git History (Code State)
- **What**: Actual code changes from previous iterations
- **Accessed by**: Git operations (checkout, diff, log)
- **Persistence**: Permanent (until force-pushed)
- **Purpose**: Ground truth of implementation

#### Layer 2: prd.json (Task State)
- **What**: Which stories are complete
- **Accessed by**: jq queries, Claude read/write
- **Persistence**: Until branch change (then archived)
- **Purpose**: Loop termination condition

#### Layer 3: progress.txt (Temporal Context)
- **What**: Story-specific learnings, chronological
- **Accessed by**: Claude reads all, appends new
- **Persistence**: Grows unbounded (archived on branch change)
- **Purpose**: "What happened and why"

#### Layer 4: AGENTS.md (Permanent Knowledge)
- **What**: Directory-specific patterns, timeless
- **Accessed by**: Claude reads when working in that directory
- **Persistence**: Permanent, committed to repo
- **Purpose**: "How this part of the codebase works"

### Memory Access Patterns

```
Iteration N starts
     ↓
Claude reads Layer 3 (progress.txt) - "What did previous iterations learn?"
     ↓
Claude reads Layer 4 (AGENTS.md) - "What are the patterns here?"
     ↓
Claude reads Layer 1 (git diff) - "What's the current state?"
     ↓
Claude implements story
     ↓
Claude writes Layer 1 (git commit) - Code changes
Claude writes Layer 2 (prd.json) - Mark story complete
Claude writes Layer 3 (progress.txt) - Append learnings
Claude writes Layer 4 (AGENTS.md) - Update patterns if needed
     ↓
Iteration N+1 starts (fresh Claude, reads all layers)
```

---

## Scalability Considerations

### Iteration Count Limits

**Default**: 10 iterations
**Configurable**: User can specify (e.g., `./ralph.sh 50`)

**Why limit?**
1. **Cost control**: Each iteration uses API credits
2. **Runaway prevention**: Bad PRD could loop forever
3. **User awareness**: Forces intentional long runs

**When to increase**:
- Large PRDs (20+ stories)
- Complex interdependent stories
- CI/CD automation (can afford to wait)

### progress.txt Growth

**Expected growth**: ~500 bytes per iteration
**At 100 iterations**: ~50KB (manageable)
**At 1000 iterations**: ~500KB (consider archiving)

**Mitigation strategies**:
1. Archive on branch change (automatic)
2. Manually archive old runs
3. Extract patterns to AGENTS.md (consolidate knowledge)

### Git History Size

**Each iteration**: 1 commit
**At 100 iterations**: 100 commits (fine)
**At 1000 iterations**: 1000 commits (squash before merging)

**Best practice**: Squash Ralph commits when merging PR
```bash
git rebase -i main  # Squash all Ralph commits
```

---

## Security Considerations

### Sandboxing (Docker Mode)

**Isolation boundaries**:
- File system: Container only sees project directory
- Network: Configurable (can disable)
- Processes: Isolated from host

**Permission model**:
```bash
docker sandbox run \
  --permission acceptEdits \  # Auto-accept file changes
  --workdir /project \
  --volume $(pwd):/project
```

**Risk mitigation**:
1. Use Docker for untrusted codebases
2. Review commits before pushing
3. Run with limited permissions in CI/CD

### CLI Mode Security

**Risks**:
- Claude has full file system access
- Can execute arbitrary commands
- No sandboxing

**When to use**:
- Trusted codebases
- Your own projects
- Performance is critical

**Permission flag**: `--dangerously-skip-permissions`
- Required for automation
- Bypasses manual confirmations
- Use with caution

---

## Configuration System Design

### Environment Variable Hierarchy

```
1. Command-line environment variables (highest priority)
   RALPH_USE_DOCKER=yes ./ralph.sh

2. Shell session exports
   export RALPH_USE_DOCKER=yes
   ./ralph.sh

3. Script defaults (lowest priority)
   DEFAULT_MAX_ITERATIONS=10  # in ralph.sh
```

**Why this hierarchy?**
- Override without editing scripts
- Session-level configuration
- Sane defaults for most users

### Supported Variables

| Variable | Values | Default | When to Change |
|----------|--------|---------|----------------|
| `RALPH_USE_DOCKER` | `yes`, `no`, `auto` | `auto` | Force specific mode |
| `RALPH_DOCKER_IMAGE` | Image name | `claude-code` | Custom image |
| `RALPH_DOCKER_PERMISSION` | Permission mode | `acceptEdits` | Stricter permissions |
| `RALPH_CLAUDE_PERMISSION` | CLI flag | `--dangerously-skip-permissions` | Manual review mode |
| `RALPH_NOTIFY_TOOL` | Tool name or `none` | `auto` | Disable notifications |

---

## Cross-Platform Design

### Platform Detection

```bash
# ralph.sh detects platform for notifications
case "$(uname)" in
  Darwin)  # macOS
    prefer terminal-notifier or tt
    ;;
  Linux)
    prefer notify-send
    ;;
  *)
    fallback to none
    ;;
esac
```

### Platform-Specific Behaviors

**macOS**:
- Uses `terminal-notifier` by default
- Supports `tt` if installed
- Works with Docker Desktop

**Linux**:
- Uses `notify-send` by default
- Docker runs natively (better performance)
- Requires `libnotify` for notifications

**Windows (WSL)**:
- Works via WSL2
- Docker requires WSL2 backend
- Notifications via `notify-send` (if installed)

---

## Evolution from Source Implementations

### From Original Ralph

**Kept**:
- External prompt.md architecture
- Archiving on branch change
- Structured progress.txt format
- AGENTS.md concept
- Cooling period

**Modified**:
- Added Docker support (was Amp-only)
- Auto-detection (was hardcoded)
- Environment variables (was script constants)

**Removed**:
- Amp CLI calls (replaced with Claude Code)
- Browser skill references (not in Claude Code)
- Some Amp-specific error handling

### From Ralph-Wiggum

**Kept**:
- Docker sandbox execution
- Desktop notifications
- @file syntax for Claude Code
- Simple completion check

**Modified**:
- Made Docker optional (was required)
- Multi-tool notification support (was tt-only)
- Added configuration (was hardcoded)

**Added**:
- External prompt.md (was inline)
- Archiving system
- Rich progress format
- AGENTS.md support

### Hybrid Innovations

**New in ralph-hybrid**:
1. Auto-detection (Docker, notification tools)
2. Environment variable configuration
3. Cross-platform support (macOS, Linux, WSL)
4. Comprehensive documentation
5. Example PRDs for different project types
6. Template files

---

## Future Architecture Considerations

### Potential Enhancements

1. **Resume from checkpoint**: Save state after each iteration, allow resume from specific iteration
2. **Parallel story execution**: Multiple Claude instances working on independent stories
3. **Story dependency graphs**: Automatic ordering based on dependencies
4. **Quality gate plugins**: Extensible system for custom checks
5. **Web UI**: Dashboard showing progress, git history, story status

### Architectural Debt

**Current limitations**:
1. **Single-threaded**: One story at a time
2. **No story dependencies**: Manual priority ordering
3. **Linear progress.txt**: Can grow large
4. **Manual PRD creation**: No tooling for story extraction

**Trade-offs made**:
- Simplicity over features
- Script over compiled binary
- Manual over automated (for now)

---

## Design Principles Summary

1. **Stateless iterations**: Fresh context each time
2. **Explicit memory**: All context in files
3. **Fail-safe defaults**: Works out of box
4. **Platform agnostic**: macOS, Linux, WSL
5. **User customizable**: Edit prompt.md, not ralph.sh
6. **Production ready**: Error handling, archiving, logging
7. **Future proof**: Environment variables, extensible design

---

## References

- [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/)
- [Original ralph repository](https://github.com/snarktank/ralph)
- [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code)
- Docker sandbox documentation
