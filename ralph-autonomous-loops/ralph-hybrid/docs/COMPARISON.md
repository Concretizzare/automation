# Detailed Comparison with Source Implementations

This document provides an in-depth comparison of ralph-hybrid with its two source implementations.

## Source Repositories

### Original Ralph (snarktank/ralph)
- **Repository**: https://github.com/snarktank/ralph
- **AI Engine**: Amp CLI
- **Created**: 2024
- **Maturity**: Production-ready
- **Lines of Code**: 81 (ralph.sh)
- **Documentation**: Comprehensive

### Ralph-Wiggum (simone-rizzo)
- **Repository**: Custom Claude Code port
- **AI Engine**: Claude Code via Docker
- **Created**: 2024
- **Maturity**: Proof-of-concept
- **Lines of Code**: 31 (ralph.sh)
- **Documentation**: Minimal

---

## Feature-by-Feature Comparison

### Core Features

| Feature | Original Ralph | Ralph-Wiggum | Ralph-Hybrid | Winner |
|---------|----------------|--------------|--------------|--------|
| **Autonomous loop** | ✓ Yes | ✓ Yes | ✓ Yes | All |
| **Fresh context** | ✓ Yes | ✓ Yes | ✓ Yes | All |
| **PRD tracking** | ✓ JSON | ✓ JSON | ✓ JSON | All |
| **Progress logging** | ✓ Rich | ✓ Basic | ✓ Rich | Original + Hybrid |
| **Git commits** | ✓ Yes | ✓ Yes | ✓ Yes | All |

---

### Execution Environment

| Feature | Original Ralph | Ralph-Wiggum | Ralph-Hybrid |
|---------|----------------|--------------|--------------|
| **AI Engine** | Amp CLI | Claude Code | Claude Code |
| **Docker support** | ✗ No | ✓ Required | ✓ Optional |
| **CLI support** | ✓ Amp only | ✗ No | ✓ Yes |
| **Auto-detection** | ✗ No | ✗ No | ✓ Yes |
| **Sandbox isolation** | ✗ No | ✓ Docker | ✓ Docker (optional) |

**Analysis**:
- **Original**: Tied to Amp CLI (now deprecated)
- **Wiggum**: Claude Code only, requires Docker
- **Hybrid**: Best of both - auto-detects, supports Docker AND CLI

**Why Hybrid Wins**: Flexibility. Works out-of-box for most users, adapts to environment.

---

### Prompt Engineering

| Feature | Original Ralph | Ralph-Wiggum | Ralph-Hybrid |
|---------|----------------|--------------|--------------|
| **Prompt location** | External file | Inline script | External file |
| **Prompt lines** | 109 | 10 | ~150 |
| **Customization** | Easy (edit file) | Hard (edit script) | Easy (edit file) |
| **Quality gates** | 4 (typecheck, lint, test, browser) | 2 (typecheck, test) | Customizable |
| **Browser testing** | ✓ dev-browser skill | ✗ No | ✓ Manual instructions |

**Example from Original Ralph** (prompt.md):
```markdown
## Quality Requirements

- typecheck must pass
- lint must pass
- all tests must pass
- browser verification for UI changes
```

**Example from Wiggum** (inline in ralph.sh):
```bash
PROMPT="You are an AI coding agent. Read @prd.json and @progress.txt.
Pick the next incomplete story. Implement it. Update prd.json."
```

**Example from Hybrid** (prompt.md):
```markdown
## Quality Requirements

- ALL commits must pass your project's quality checks (typecheck, lint, test)
- Do NOT commit broken code
- Keep changes focused and minimal
- Follow existing code patterns

### Common Quality Check Commands

Adapt these to your project:

\`\`\`bash
# TypeScript projects
npm run typecheck
npm run lint
npm run test
\`\`\`
```

**Why Hybrid Wins**: Detailed guidance like Original, but more flexible. Users customize without touching shell script.

---

### State Management

| Feature | Original Ralph | Ralph-Wiggum | Ralph-Hybrid |
|---------|----------------|--------------|--------------|
| **progress.txt** | ✓ Structured | ✓ Basic | ✓ Structured |
| **Codebase Patterns** | ✓ Yes | ✗ No | ✓ Yes |
| **AGENTS.md support** | ✓ Yes | ✗ No | ✓ Yes |
| **Archiving** | ✓ Auto (branch change) | ✗ No | ✓ Auto (branch change) |
| **.last-branch tracking** | ✓ Yes | ✗ No | ✓ Yes |

**Original Ralph's Archiving**:
```bash
# Detects branch change
if [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
  # Archive old run
  mkdir -p "archive/$TIMESTAMP-$LAST_BRANCH"
  mv prd.json progress.txt "archive/$TIMESTAMP-$LAST_BRANCH/"
fi
```

**Wiggum's Approach**: No archiving. Mixing context from different branches.

**Hybrid's Approach**: Adopted Original's archiving system verbatim. Critical for preventing context pollution.

---

### Error Handling

| Feature | Original Ralph | Ralph-Wiggum | Ralph-Hybrid |
|---------|----------------|--------------|--------------|
| **File validation** | ✓ Yes | ✗ No | ✓ Yes |
| **Graceful fallbacks** | ✓ Yes (`\|\| true`) | ✗ No | ✓ Yes |
| **Error messages** | ✓ Detailed | ✗ Basic | ✓ Detailed |
| **Stderr handling** | ✓ Yes | ✗ No | ✓ Yes |

**Original Ralph's Error Handling**:
```bash
# Liberal use of || true to prevent premature exits
mv prd.json archive/ 2>/dev/null || true
claude ... || echo "Iteration failed, continuing..."
```

**Wiggum's Error Handling**:
```bash
# Minimal - relies on bash defaults
docker sandbox run ...
```

**Hybrid's Error Handling**:
```bash
# Validates before starting
if [ ! -f "prd.json" ]; then
  echo "ERROR: prd.json not found. Copy from prd.json.example"
  exit 1
fi

# Graceful fallbacks
detect_docker || echo "Docker not found, using CLI mode"
```

---

### User Experience Features

| Feature | Original Ralph | Ralph-Wiggum | Ralph-Hybrid |
|---------|----------------|--------------|--------------|
| **Desktop notifications** | ✗ No | ✓ Yes (tt only) | ✓ Yes (multi-tool) |
| **Iteration markers** | ✓ Yes | ✓ Basic | ✓ Enhanced |
| **Cooling period** | ✓ Configurable | ✗ No | ✓ Configurable |
| **Progress visibility** | ✓ Real-time | ✓ Real-time | ✓ Real-time |
| **Completion summary** | ✓ Yes | ✗ No | ✓ Yes |

**Notification Tool Support**:
- **Original**: None
- **Wiggum**: `tt` only (hardcoded)
- **Hybrid**: Auto-detects `tt`, `terminal-notifier`, `notify-send` with fallback

**Why This Matters**: Different platforms, different tools. Auto-detection = better UX.

---

### Configuration & Customization

| Feature | Original Ralph | Ralph-Wiggum | Ralph-Hybrid |
|---------|----------------|--------------|--------------|
| **Environment variables** | ✗ No | ✗ No | ✓ Yes |
| **Script constants** | ✓ Edit script | ✓ Edit script | ✓ Edit script OR env vars |
| **Iteration count arg** | ✓ Yes | ✓ Required | ✓ Yes (optional) |
| **Permission modes** | ✗ Hardcoded | ✗ Hardcoded | ✓ Configurable |

**Configuration Comparison**:

**Original Ralph**:
```bash
# To change settings, edit ralph.sh
MAX_ITERATIONS=10  # Hardcoded in script
```

**Wiggum**:
```bash
# Iteration count required as argument
./ralph.sh 5  # Must specify
```

**Hybrid**:
```bash
# Multiple ways to configure
./ralph.sh              # Default 10 iterations
./ralph.sh 20           # 20 iterations
RALPH_USE_DOCKER=yes ./ralph.sh  # Force Docker
export RALPH_NOTIFY_TOOL=none    # Disable notifications
```

---

## Architectural Decisions

### Memory Architecture

**All three use same 4-layer approach**:
1. Git history (code state)
2. prd.json (task state)
3. progress.txt (temporal context)
4. AGENTS.md (permanent knowledge)

**Differences**:

| Layer | Original Ralph | Ralph-Wiggum | Ralph-Hybrid |
|-------|----------------|--------------|--------------|
| **Git** | ✓ Rich commits | ✓ Basic commits | ✓ Rich commits |
| **prd.json** | ✓ Full schema | ✓ Full schema | ✓ Full schema |
| **progress.txt** | ✓ Structured + patterns | ✓ Simple append | ✓ Structured + patterns |
| **AGENTS.md** | ✓ Yes + instructions | ✗ No | ✓ Yes + instructions |

**Hybrid inherits from Original**: Structured progress.txt with Codebase Patterns section is critical for knowledge accumulation.

---

### Execution Model

**Original Ralph**:
```bash
for i in $(seq 1 $MAX_ITERATIONS); do
  # Build prompt
  cat prompt.md > /tmp/prompt
  echo "@prd.json @progress.txt" >> /tmp/prompt

  # Execute Amp
  amp < /tmp/prompt

  # Check completion
  # Continue or exit
done
```

**Wiggum**:
```bash
for i in $(seq 1 $1); do  # Iteration count required
  # Inline prompt + file references
  docker sandbox run claude \
    "Read @prd.json and @progress.txt. [instructions]"

  # Check for COMPLETE signal
done
```

**Hybrid**:
```bash
# Detect execution mode first
if [ "$USE_DOCKER" = "yes" ]; then
  EXEC_CMD="docker sandbox run"
else
  EXEC_CMD="claude"
fi

for i in $(seq 1 $MAX_ITERATIONS); do
  # Build prompt (like Original)
  cat prompt.md > /tmp/prompt
  echo "@prd.json" >> /tmp/prompt
  echo "@progress.txt" >> /tmp/prompt

  # Execute (like Wiggum, but configurable)
  $EXEC_CMD < /tmp/prompt

  # Check completion
  # Send notification (like Wiggum, but multi-tool)
done
```

**Hybrid combines**:
- Original's external prompt approach
- Wiggum's Docker execution
- Added auto-detection + CLI fallback

---

## Evolution Timeline

### From Original Ralph

**Kept**:
```
✓ External prompt.md architecture
✓ Archiving on branch change
✓ .last-branch tracking
✓ Structured progress.txt with Codebase Patterns
✓ AGENTS.md support
✓ Cooling period
✓ Rich commit messages
✓ Error handling patterns (|| true)
```

**Modified**:
```
~ Amp CLI → Claude Code support
~ Hardcoded settings → Environment variables
~ Amp-specific features → Claude Code equivalents
```

**Removed**:
```
✗ Amp CLI calls
✗ dev-browser skill (not in Claude Code)
✗ Amp-specific error handling
```

---

### From Ralph-Wiggum

**Kept**:
```
✓ Docker sandbox execution
✓ Desktop notifications concept
✓ @file syntax for Claude Code
✓ Simple <promise>COMPLETE</promise> check
```

**Modified**:
```
~ Inline prompt → External prompt.md
~ tt-only → Multi-tool notification support
~ Docker required → Docker optional with auto-detect
~ Hardcoded settings → Environment variables
```

**Added**:
```
✓ Archiving system (from Original)
✓ Rich progress format (from Original)
✓ AGENTS.md support (from Original)
✓ CLI mode fallback (new in Hybrid)
```

---

## What Makes Ralph-Hybrid Different

### 1. Auto-Detection System

Neither source implementation had this. Hybrid auto-detects:
- Docker availability
- Claude CLI availability
- Notification tools (3 different tools)
- Falls back gracefully

**Implementation**:
```bash
detect_docker() {
  if command -v docker &> /dev/null; then
    if docker info &> /dev/null; then
      return 0  # Docker available
    fi
  fi
  return 1  # Docker not available
}

detect_notify_tool() {
  for tool in tt terminal-notifier notify-send; do
    if command -v $tool &> /dev/null; then
      echo "$tool"
      return
    fi
  done
  echo "none"
}
```

### 2. Environment Variable System

Complete configuration via env vars:
```bash
RALPH_USE_DOCKER=yes|no|auto     # Execution mode
RALPH_DOCKER_IMAGE=image-name    # Docker image
RALPH_DOCKER_PERMISSION=mode     # Docker permissions
RALPH_CLAUDE_PERMISSION=flags    # CLI permissions
RALPH_NOTIFY_TOOL=tool|auto      # Notification tool
```

Neither source had this level of configurability.

### 3. Cross-Platform Support

Tested on:
- macOS (both Intel and Apple Silicon)
- Linux (Ubuntu, Debian, Fedora)
- Windows WSL2

Platform-specific adjustments:
```bash
case "$(uname)" in
  Darwin)  # macOS
    DEFAULT_NOTIFY=terminal-notifier
    ;;
  Linux)
    DEFAULT_NOTIFY=notify-send
    ;;
esac
```

### 4. Comprehensive Documentation

| Document | Original Ralph | Wiggum | Hybrid |
|----------|----------------|--------|--------|
| README | ✓ Detailed | ✗ 2 lines | ✓ Comprehensive |
| STRUCTURE | ✗ No | ✗ No | ✓ Yes |
| QUICKSTART | ✗ No | ✗ No | ✓ Yes |
| ARCHITECTURE | ✗ No | ✗ No | ✓ Yes |
| TROUBLESHOOTING | ✗ No | ✗ No | ✓ Yes |
| COMPARISON | ✗ No | ✗ No | ✓ This file |
| CODE_REVIEW | ✗ No | ✗ No | ✓ Yes |
| Examples | ✗ No | ✗ No | ✓ 3 PRD examples |
| Templates | ✗ No | ✗ No | ✓ Yes |

---

## Quantitative Comparison

### Lines of Code

| File | Original Ralph | Wiggum | Hybrid |
|------|----------------|--------|--------|
| ralph.sh | 81 | 31 | ~300 (with docs) |
| prompt.md | 109 | 0 (inline) | ~150 |
| Documentation | ~500 | ~50 | ~3000 |
| **Total** | ~690 | ~81 | ~3450 |

**Why Hybrid is larger**:
- Comprehensive documentation
- Auto-detection logic
- Error handling
- Cross-platform support
- Environment variable system

**Core loop complexity**: Similar across all three (~50 lines)

### Feature Count

| Category | Original Ralph | Wiggum | Hybrid |
|----------|----------------|--------|--------|
| Execution modes | 1 | 1 | 2 |
| Notification tools | 0 | 1 | 3 |
| Config methods | 1 | 1 | 3 |
| Documentation files | 3 | 1 | 9 |
| Example PRDs | 0 | 0 | 3 |
| Templates | 0 | 0 | 3 |

---

## Use Case Recommendations

### When to Use Original Ralph

**Use if**:
- You're still using Amp CLI
- You want the battle-tested production version
- You don't need Claude Code features
- You prefer minimal dependencies

**Don't use if**:
- You want Claude Code support
- You need Docker isolation

---

### When to Use Ralph-Wiggum

**Use if**:
- You want minimal, simple implementation
- You only use Docker
- You don't need archiving or rich features
- You want to understand the core pattern

**Don't use if**:
- You need production-ready features
- You want archiving
- You need CLI mode
- You want rich documentation

---

### When to Use Ralph-Hybrid

**Use if**:
- You want production-ready Claude Code implementation
- You need Docker OR CLI support
- You want archiving and state management
- You want comprehensive documentation
- You need cross-platform support
- You want flexibility via environment variables

**Don't use if**:
- You want absolute minimal implementation
- You're using Amp CLI (use Original)

---

## Migration Guides

### From Original Ralph to Hybrid

```bash
# 1. Backup current setup
cp -r scripts/ralph scripts/ralph-backup

# 2. Replace ralph.sh
cp /path/to/ralph-hybrid/ralph.sh scripts/ralph/

# 3. Keep your existing prompt.md (or use hybrid's enhanced version)
# Your existing prompt.md should work fine

# 4. No changes needed to prd.json or progress.txt

# 5. Test
cd scripts/ralph
./ralph.sh 1  # Test single iteration

# 6. Benefits you get:
# - Docker support (if desired)
# - Desktop notifications
# - Environment variable configuration
# - Better error handling
```

---

### From Ralph-Wiggum to Hybrid

```bash
# 1. Extract your inline prompt to prompt.md
# Copy the prompt string from your ralph.sh into prompt.md

# 2. Replace ralph.sh
cp /path/to/ralph-hybrid/ralph.sh .
cp /path/to/ralph-hybrid/prompt.md .

# 3. Your prd.json and progress.txt should work as-is

# 4. Benefits you get:
# - Archiving on branch changes
# - CLI mode option
# - Multi-tool notifications
# - Rich progress.txt format
# - AGENTS.md support
# - Comprehensive documentation
```

---

## Lessons Learned

### From Original Ralph

**Lesson**: External prompt.md is essential for customization
**Applied**: Hybrid uses same architecture

**Lesson**: Archiving prevents context pollution
**Applied**: Hybrid uses same .last-branch system

**Lesson**: Structured progress.txt with patterns helps knowledge accumulation
**Applied**: Hybrid uses same format

### From Ralph-Wiggum

**Lesson**: Docker isolation is valuable
**Applied**: Hybrid supports Docker as option

**Lesson**: Desktop notifications improve UX
**Applied**: Hybrid auto-detects multiple tools

**Lesson**: Simplicity matters
**Applied**: Hybrid keeps core loop simple, adds complexity in detection/config

### New in Hybrid

**Lesson**: Auto-detection beats configuration
**Applied**: Detect Docker, CLI, notification tools

**Lesson**: Environment variables beat hardcoded values
**Applied**: All settings configurable via env vars

**Lesson**: Documentation is as important as code
**Applied**: Comprehensive docs for all aspects

---

## Summary

**Ralph-Hybrid is**:
- The Original Ralph's architecture
- With Wiggum's Claude Code integration
- Plus auto-detection, configurability, and comprehensive documentation

**It preserves**:
- Original's production-ready state management
- Original's external prompt architecture
- Original's archiving system
- Wiggum's Docker sandbox approach
- Wiggum's notification concept

**It improves**:
- Auto-detection (neither source had this)
- Environment variables (neither source had this)
- Cross-platform support (neither source focused on this)
- Documentation (far more comprehensive)
- Flexibility (works in more environments)

**It's the recommended choice for**:
- New Claude Code projects
- Production use
- Teams needing comprehensive documentation
- Cross-platform deployments

---

## Version History

**Original Ralph**: v1.0 (2024) - Amp CLI, production-ready
**Ralph-Wiggum**: v1.0 (2024) - Claude Code port, proof-of-concept
**Ralph-Hybrid**: v1.0 (2026) - Best of both + enhancements

This comparison reflects implementations as of January 2026.
