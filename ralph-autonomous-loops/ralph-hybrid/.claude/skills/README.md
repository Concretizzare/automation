# Ralph Skills for Claude Code

Skills originali da **ralph** e **ralph-wiggum**, copiate senza modifiche.

## Available Skills (2)

### 1. PRD Generator (`prd`)

**File**: `.claude/skills/prd/SKILL.md`

**Trigger**: `create a prd`, `write prd for`, `plan this feature`, `requirements for`, `spec out`

**Funzione**: Genera PRD strutturati tramite domande chiarificatrici (formato A/B/C/D).

**Output**: `tasks/prd-[feature-name].md`

**Quando usare**:
- Pianificare una nuova feature
- Convertire idee vaghe in specifiche actionable
- Prima di iniziare l'implementazione

### 2. Ralph Converter (`ralph`)

**File**: `.claude/skills/ralph/SKILL.md`

**Trigger**: `convert this prd`, `turn this into ralph format`, `create prd.json`, `ralph json`

**Funzione**: Converte PRD markdown in formato `prd.json` per il loop Ralph.

**Output**: `prd.json`

**Quando usare**:
- Dopo aver generato un PRD con `/prd`
- Per preparare l'input del loop autonomo `./ralph.sh`

---

## Workflow

```bash
# 1. Genera PRD interattivo
User: "create a prd for user authentication"
Claude: [Fa domande A/B/C/D]
Claude: [Crea tasks/prd-user-auth.md]

# 2. Converti in prd.json
User: "convert this prd to ralph format"  
Claude: [Crea prd.json]

# 3. Esegui loop Ralph
./ralph.sh 10
```

---

## Note Tecniche

**Formato**: YAML front-matter + markdown (standard Claude Code)

**Indicizzazione**: Claude Code rileva automaticamente da `.claude/skills/*/SKILL.md`

**Invocazione**: 
- Automatica (via trigger keywords nel messaggio)
- Manuale (via `/skills` menu)

**Scope**: Project-local (non globali)

---

## Confronto con Versioni Originali

| Versione | Path | Skills | Note |
|----------|------|--------|------|
| **ralph** (Amp) | `skills/*/SKILL.md` | prd, ralph | Fonte primaria (Amp) |
| **ralph-wiggum** | `.claude/skills/*/SKILL.md` | prd, ralph | Copia da ralph |
| **ralph-hybrid** | `.claude/skills/*/SKILL.md` | prd, ralph | **Copiate da ralph (Amp)** |

**Contenuto identico** - ralph-hybrid usa direttamente le skills originali da ralph (Amp).

---

## Browser Testing

**NON DISPONIBILE** come skill.

Le versioni originali non includono skill per browser testing.

Per testing UI:
1. Usa MCP `claude-in-chrome` se disponibile
2. Test manuale nel browser

Il `prompt.md` menziona browser verification ma è **opzionale**.

---

**Ultima modifica**: 2026-01-19
