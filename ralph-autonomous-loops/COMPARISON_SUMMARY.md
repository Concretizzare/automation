# Ralph Autonomous Agent Loop - Comparison

This folder contains two implementations of the Ralph autonomous agent loop pattern.

## Repositories

### 1. `ralph/` - Original Implementation (snarktank/ralph)
- **AI Engine**: Amp CLI
- **Maturity**: Production-ready
- **Lines of Code**: 81 (main script)
- **Documentation**: Comprehensive (README, flowchart, skills)
- **State Management**: Full (archiving, branch tracking, multi-layer persistence)

### 2. `ralph-wiggum/` - Claude Code Port (simone-rizzo)
- **AI Engine**: Claude Code via Docker sandbox
- **Maturity**: Proof-of-concept
- **Lines of Code**: 31 (main script)
- **Documentation**: Minimal (2-line README)
- **State Management**: Basic (prd.json, progress.txt)

## Key Differences

| Feature | Original Ralph | Ralph-Wiggum |
|---------|----------------|--------------|
| Prompt Engineering | External file (109 lines) | Inline (10 lines) |
| Error Handling | Robust (`\|\| true`, stderr) | None |
| Archiving | Automatic on branch change | None |
| Browser Testing | Yes (dev-browser skill) | No |
| Knowledge Accumulation | AGENTS.md + patterns | Basic progress.txt |
| Docker Isolation | No | Yes |
| Desktop Notifications | No | Yes |
| Quality Gates | 4 (typecheck, lint, test, browser) | 2 (typecheck, test) |

## Strengths

### Original Ralph
- Production-ready with comprehensive state management
- Rich prompt engineering with structured guidance
- Knowledge accumulation via AGENTS.md and Codebase Patterns
- Interactive flowchart visualization
- Extensible skill system

### Ralph-Wiggum
- Simple and easy to understand (31 lines)
- Native Claude Code integration
- Docker sandbox isolation
- Desktop notifications on completion

## Recommendations

### For Production Use
→ Use **Original Ralph** - Mature, robust, battle-tested

### For Quick Prototyping
→ Use **Ralph-Wiggum** - Fast setup, minimal dependencies

### Best Path Forward
Combine both approaches:
1. Take Original Ralph's architecture and prompt engineering
2. Add Claude Code support via Docker sandbox
3. Add desktop notifications
4. Keep external prompt file for flexibility

## Getting Started

### Original Ralph
```bash
cd ralph/
./ralph.sh 10  # Run up to 10 iterations
```

### Ralph-Wiggum
```bash
cd ralph-wiggum/
./ralph.sh 5  # Run 5 iterations (required argument)
```

## Full Analysis

See code review output for detailed architectural comparison, quality analysis, and cross-pollination recommendations.

---

**Date**: 2026-01-19
**Analysis Tool**: Claude Code with code-reviewer agent
