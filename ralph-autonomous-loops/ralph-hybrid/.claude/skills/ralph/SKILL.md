# Ralph PRD Converter Skill

Convert markdown PRDs to `prd.json` format for Ralph loop execution.

## Trigger Phrases

- "convert this prd"
- "turn this into ralph format"
- "create prd.json from this"
- "ralph json"
- "/ralph-convert"

## Overview

This skill takes an existing PRD (markdown file or text) and converts it to the JSON format that Ralph uses for autonomous execution. It validates story sizes, acceptance criteria, and dependencies.

---

## The Workflow

1. **Read** the source PRD (markdown file or pasted text)
2. **Validate** stories for size, dependencies, and acceptance criteria
3. **Convert** to `prd.json` format
4. **Archive** previous run if different feature
5. **Save** to project's ralph directory

---

## Output Format

```json
{
  "project": "[Project Name]",
  "branchName": "ralph/[feature-name-kebab-case]",
  "description": "[Feature description from PRD title/intro]",
  "qualityChecks": {
    "typecheck": "npm run typecheck",
    "lint": "npm run lint",
    "test": "npm run test"
  },
  "userStories": [
    {
      "id": "US-001",
      "title": "[Story title]",
      "description": "As a [user], I want [feature] so that [benefit]",
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

---

## Validation Rules (MUST enforce)

### 1. Story Size Validation

**Each story must be completable in ONE Ralph iteration (one context window).**

Reject or flag stories that are too large:

**Right-sized (ACCEPT):**
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

**Too big (SPLIT or REJECT):**
- "Build the entire dashboard"
- "Add authentication"
- "Refactor the API"
- Any story that requires more than 2-3 sentences to describe

**If story is too big:**
1. Warn the user
2. Suggest how to split it
3. Do NOT include it as-is

### 2. Acceptance Criteria Validation

Each criterion must be VERIFIABLE - something Ralph can CHECK.

**Valid criteria:**
- "Add `status` column to tasks table with default 'pending'"
- "Filter dropdown has options: All, Active, Completed"
- "Clicking delete shows confirmation dialog"
- "Typecheck passes"
- "Tests pass"
- "Verify in browser using dev-browser skill"

**Invalid criteria (REJECT or REWRITE):**
- "Works correctly"
- "User can do X easily"
- "Good UX"
- "Handles edge cases"
- "Is performant"

**If vague criteria found:**
1. Flag to user
2. Suggest specific replacement
3. Do NOT include vague criteria

### 3. Dependency Validation

Stories execute in priority order. Earlier stories must NOT depend on later ones.

**Correct order:**
1. Schema/database changes (migrations)
2. Server actions / backend logic
3. UI components that use the backend
4. Dashboard/summary views that aggregate data

**If dependency cycle detected:**
1. Warn the user
2. Suggest correct ordering
3. Reorder in output

### 4. Branch Name Validation

Branch names must be:
- Prefixed with `ralph/`
- kebab-case
- Descriptive but concise

Examples:
- `ralph/task-priority`
- `ralph/user-notifications`
- `ralph/status-filter`

### 5. Required Criteria

Every story MUST include:
- "Typecheck passes" (or equivalent)

UI stories MUST also include:
- "Verify in browser using dev-browser skill"

Add these automatically if missing.

---

## Quality Checks Detection

Detect project type and set appropriate quality checks:

### TypeScript/JavaScript (Next.js, React, Node)
```json
{
  "typecheck": "npm run typecheck",
  "lint": "npm run lint",
  "test": "npm run test"
}
```

### Python
```json
{
  "typecheck": "mypy .",
  "lint": "ruff check .",
  "test": "pytest"
}
```

### Go
```json
{
  "typecheck": "go build ./...",
  "lint": "golangci-lint run",
  "test": "go test ./..."
}
```

### Rust
```json
{
  "typecheck": "cargo check",
  "lint": "cargo clippy",
  "test": "cargo test"
}
```

If unsure, check for:
- `package.json` → Node/TypeScript project
- `requirements.txt` or `pyproject.toml` → Python project
- `go.mod` → Go project
- `Cargo.toml` → Rust project

---

## Conversion Rules

1. **Each user story becomes one JSON entry**
2. **IDs:** Sequential (US-001, US-002, etc.)
3. **Priority:** Based on dependency order, then document order
4. **All stories:** `passes: false` and empty `notes` initially
5. **branchName:** Derive from feature name, kebab-case, prefixed with `ralph/`
6. **Always add:** "Typecheck passes" to every story if not present
7. **UI stories:** Add "Verify in browser using dev-browser skill" if not present

---

## Splitting Large Stories

If a PRD has big features, split them:

**Original:**
> "Add user notification system"

**Split into:**
1. US-001: Add notifications table to database
2. US-002: Create notification service for sending notifications
3. US-003: Add notification bell icon to header
4. US-004: Create notification dropdown panel
5. US-005: Add mark-as-read functionality
6. US-006: Add notification preferences page

Each is one focused change that can be completed and verified independently.

---

## Archiving Previous Runs

**Before writing a new prd.json, check if there is an existing one from a different feature:**

1. Read the current `prd.json` if it exists
2. Check if `branchName` differs from the new feature's branch name
3. If different AND `progress.txt` has content beyond the header:
   - Create archive folder: `archive/YYYY-MM-DD-feature-name/`
   - Copy current `prd.json` and `progress.txt` to archive
   - Reset `progress.txt` with fresh header

**Archive command:**
```bash
# Create archive directory
mkdir -p archive/$(date +%Y-%m-%d)-[old-feature-name]

# Move files
cp prd.json archive/$(date +%Y-%m-%d)-[old-feature-name]/
cp progress.txt archive/$(date +%Y-%m-%d)-[old-feature-name]/

# Reset progress.txt
echo "# Progress Log\n\n## Codebase Patterns\n\n---\n" > progress.txt
```

---

## Example Conversion

**Input PRD:**

```markdown
# Task Status Feature

Add ability to mark tasks with different statuses.

## Requirements
- Toggle between pending/in-progress/done on task list
- Filter list by status
- Show status badge on each task
- Persist status in database
```

**Output prd.json:**

```json
{
  "project": "TaskApp",
  "branchName": "ralph/task-status",
  "description": "Task Status Feature - Track task progress with status indicators",
  "qualityChecks": {
    "typecheck": "npm run typecheck",
    "lint": "npm run lint",
    "test": "npm run test"
  },
  "userStories": [
    {
      "id": "US-001",
      "title": "Add status field to tasks table",
      "description": "As a developer, I need to store task status in the database.",
      "acceptanceCriteria": [
        "Add status column: 'pending' | 'in_progress' | 'done' (default 'pending')",
        "Generate and run migration successfully",
        "Typecheck passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    },
    {
      "id": "US-002",
      "title": "Display status badge on task cards",
      "description": "As a user, I want to see task status at a glance.",
      "acceptanceCriteria": [
        "Each task card shows colored status badge",
        "Badge colors: gray=pending, blue=in_progress, green=done",
        "Typecheck passes",
        "Verify in browser using dev-browser skill"
      ],
      "priority": 2,
      "passes": false,
      "notes": ""
    },
    {
      "id": "US-003",
      "title": "Add status toggle to task list rows",
      "description": "As a user, I want to change task status directly from the list.",
      "acceptanceCriteria": [
        "Each row has status dropdown or toggle",
        "Changing status saves immediately",
        "UI updates without page refresh",
        "Typecheck passes",
        "Verify in browser using dev-browser skill"
      ],
      "priority": 3,
      "passes": false,
      "notes": ""
    },
    {
      "id": "US-004",
      "title": "Filter tasks by status",
      "description": "As a user, I want to filter the list to see only certain statuses.",
      "acceptanceCriteria": [
        "Filter dropdown: All | Pending | In Progress | Done",
        "Filter persists in URL params",
        "Typecheck passes",
        "Verify in browser using dev-browser skill"
      ],
      "priority": 4,
      "passes": false,
      "notes": ""
    }
  ]
}
```

---

## Validation Report

After conversion, provide a validation report:

```
## Validation Report

Stories: 4
Branch: ralph/task-status

Validation:
- [x] All stories are appropriately sized
- [x] Dependencies are correctly ordered
- [x] All criteria are verifiable
- [x] Typecheck criterion added to all stories
- [x] Browser verification added to UI stories (US-002, US-003, US-004)
- [x] No dependency cycles detected
- [x] Branch name follows conventions

Quality Checks Detected: TypeScript/Next.js project
- typecheck: npm run typecheck
- lint: npm run lint
- test: npm run test

Ready for Ralph execution!
```

---

## Checklist Before Saving

Before writing prd.json, verify:

- [ ] **Previous run archived** (if prd.json exists with different branchName)
- [ ] Each story is completable in one iteration (small enough)
- [ ] Stories are ordered by dependency (schema → backend → UI)
- [ ] Every story has "Typecheck passes" as criterion
- [ ] UI stories have "Verify in browser using dev-browser skill"
- [ ] Acceptance criteria are verifiable (not vague)
- [ ] No story depends on a later story
- [ ] Branch name is kebab-case with `ralph/` prefix
- [ ] Quality checks match project type

---

## Integration with Ralph Loop

After creating `prd.json`:

1. Run `./ralph.sh` to start the autonomous loop
2. Each iteration picks the highest priority story with `passes: false`
3. Claude implements the story and runs quality checks
4. If checks pass, story is marked `passes: true`
5. Progress is logged to `progress.txt`
6. Loop continues until all stories pass

See `prompt.md` for the full agent instructions.
