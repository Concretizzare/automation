# Ralph Hybrid Skills

This directory contains skills that extend Claude Code's capabilities for the Ralph autonomous development loop.

## What Are Skills?

Skills are specialized instructions that teach Claude how to perform specific tasks. They provide:

- **Domain knowledge:** Best practices and patterns
- **Validation rules:** Constraints and requirements
- **Output formats:** Structured templates
- **Workflow guidance:** Step-by-step processes

Skills can be invoked manually or automatically by the Ralph loop.

---

## Available Skills

### 1. PRD Generator (`/prd`)

**Location:** `.claude/skills/prd/SKILL.md`

**Purpose:** Create structured Product Requirements Documents through interactive clarifying questions.

**When to use:**
- Starting a new feature
- Planning before implementation
- Converting vague ideas into actionable specs

**Key features:**
- Lettered multiple-choice questions (A/B/C/D format)
- Size-constrained user stories (one context window each)
- Verifiable acceptance criteria
- Mandatory browser verification for UI stories

**Trigger phrases:**
- "create a prd"
- "write prd for [feature]"
- "plan this feature"
- "requirements for [feature]"

**Output:** `tasks/prd-[feature-name].md`

---

### 2. Ralph PRD Converter (`/ralph-convert`)

**Location:** `.claude/skills/ralph/SKILL.md`

**Purpose:** Convert markdown PRDs to `prd.json` format for Ralph loop execution.

**When to use:**
- After creating a PRD with the prd skill
- When you have an existing PRD to execute
- Before running `ralph.sh`

**Key features:**
- Validates story sizes (must fit in one context window)
- Checks acceptance criteria are verifiable
- Detects dependency cycles
- Auto-detects project type for quality checks
- Archives previous runs

**Trigger phrases:**
- "convert this prd"
- "turn this into ralph format"
- "create prd.json from this"
- "ralph json"

**Output:** `prd.json`

---

### 3. Dev Browser Testing (`/dev-browser`)

**Location:** `.claude/skills/dev-browser/SKILL.md`

**Purpose:** Visual verification of frontend changes in the browser.

**When to use:**
- For any story with UI changes
- When acceptance criteria includes "Verify in browser"
- Debugging visual issues
- Capturing screenshots for documentation

**Key features:**
- Integration with Claude in Chrome MCP tools
- Manual testing fallback when MCP not available
- Structured verification workflow
- Screenshot capture guidance

**Trigger phrases:**
- "verify in browser"
- "test in browser"
- "check the UI"
- "visual verification"

**Output:** Verification report in `progress.txt`

---

## Using Skills

### Manual Invocation

You can invoke skills directly by using their trigger phrases:

```
User: create a prd for task priority system
Claude: [Invokes prd skill, asks clarifying questions]
```

### Within Ralph Loop

The Ralph loop automatically references skills when needed:

1. **PRD Skill:** Used by developers to create PRDs before running Ralph
2. **Ralph Converter:** Converts PRDs to JSON format
3. **Dev Browser:** Invoked when story has "Verify in browser" criterion

### Skill Reference in Acceptance Criteria

When writing acceptance criteria, reference skills explicitly:

```markdown
**Acceptance Criteria:**
- [ ] Button displays correct state
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill
```

This tells Ralph to invoke the dev-browser skill for verification.

---

## Skill Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                     Development Flow                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. User describes feature                                  │
│           │                                                 │
│           ▼                                                 │
│  ┌─────────────────┐                                        │
│  │   PRD Skill     │  Ask questions → Generate PRD         │
│  └────────┬────────┘                                        │
│           │                                                 │
│           ▼                                                 │
│  ┌─────────────────┐                                        │
│  │  Ralph Skill    │  Validate → Convert to JSON           │
│  └────────┬────────┘                                        │
│           │                                                 │
│           ▼                                                 │
│  ┌─────────────────┐                                        │
│  │   Ralph Loop    │  Execute stories autonomously          │
│  │   (ralph.sh)    │                                        │
│  └────────┬────────┘                                        │
│           │                                                 │
│           ▼  (for each UI story)                            │
│  ┌─────────────────┐                                        │
│  │ Dev Browser     │  Visual verification                   │
│  │    Skill        │                                        │
│  └────────┬────────┘                                        │
│           │                                                 │
│           ▼                                                 │
│  Feature Complete!                                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Creating Custom Skills

You can add custom skills for your project:

1. Create a directory under `.claude/skills/`
2. Add a `SKILL.md` file with:
   - Clear purpose description
   - Trigger phrases
   - Step-by-step workflow
   - Validation rules
   - Examples
   - Output format

### Skill File Structure

```markdown
# [Skill Name]

[Brief description]

## Trigger Phrases
- "phrase 1"
- "phrase 2"

## Overview
[What this skill does]

## Workflow
[Step-by-step process]

## Validation Rules
[What to check/enforce]

## Examples
[Input/output examples]

## Output
[Where results go]
```

---

## Best Practices

### For PRD Creation

1. Answer clarifying questions completely
2. Keep stories small (one context window)
3. Make acceptance criteria specific and verifiable
4. Include browser verification for all UI stories

### For Ralph Conversion

1. Review the validation report before running Ralph
2. Fix any flagged issues before execution
3. Archive previous runs to preserve history
4. Verify quality check commands match your project

### For Browser Testing

1. Always start the dev server before testing
2. Test both happy path and edge cases
3. Capture screenshots as evidence
4. Document any issues found

---

## Troubleshooting

### "Story too large" error

The story cannot be completed in one context window. Split it into smaller stories focused on single changes.

### "Vague acceptance criteria" warning

Criteria like "works correctly" cannot be verified. Replace with specific, testable conditions.

### "Dependency cycle detected" error

Story A depends on Story B which depends on Story A. Reorder stories so dependencies come first.

### Browser verification fails

1. Check dev server is running
2. Check for build errors
3. Clear browser cache
4. Verify correct URL

---

## Related Files

- `prompt.md` - Main Ralph agent instructions
- `prd.json` - Current feature specification
- `progress.txt` - Implementation log and learnings
- `ralph.sh` - Loop execution script
