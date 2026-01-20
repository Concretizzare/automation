# Concretizzare Automation

Repository centrale per strumenti di automazione e agenti autonomi.

## 📁 Ralph Autonomous Loops

Tre implementazioni dell'agente autonomo Ralph per sviluppo software automatizzato basato su PRD.

**Percorso**: `ralph-autonomous-loops/`

| Versione | AI Engine | Status | Docs |
|----------|-----------|--------|------|
| **ralph-hybrid** ⭐ | Claude Code | **Raccomandato** | [README](ralph-autonomous-loops/ralph-hybrid/README.md) |
| ralph | Amp CLI | Production | [README](ralph-autonomous-loops/ralph/README.md) |
| ralph-wiggum | Claude Code | PoC | [README](ralph-autonomous-loops/ralph-wiggum/README.md) |

### Quick Links
- [Confronto](ralph-autonomous-loops/COMPARISON_SUMMARY.md)
- [Analisi Hybrid](ralph-autonomous-loops/HYBRID_SUMMARY.md)
- [Quick Start](ralph-autonomous-loops/ralph-hybrid/QUICKSTART.md)

### Quick Start - ralph-hybrid

```bash
git clone https://github.com/Concretizzare/automation.git
cd automation/ralph-autonomous-loops/ralph-hybrid
cp examples/fullstack-web-app.prd.json prd.json
./ralph.sh 10
```

### Features ralph-hybrid
- ✅ Claude Code nativo + Docker sandbox
- ✅ Archiving automatico + Branch tracking
- ✅ Quality gates (typecheck/lint/test/browser)
- ✅ Desktop notifications multi-platform
- ✅ 4 Skills Claude Code
- ✅ 3 PRD esempi (45 user stories)
- ✅ ~5,200 righe documentazione

**Creato**: 2026-01-19 con 3 agenti Claude Code (code-editor, code-reviewer, docs-structure-specialist)
