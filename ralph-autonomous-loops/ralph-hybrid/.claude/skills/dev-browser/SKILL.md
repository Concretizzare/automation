# Dev Browser Testing Skill

Visual verification of frontend changes in the browser.

## Trigger Phrases

- "verify in browser"
- "test in browser"
- "check the UI"
- "visual verification"
- "browser test"
- "/dev-browser"

## Overview

This skill provides a structured workflow for testing UI changes in a real browser. It uses Claude in Chrome MCP tools when available, or provides manual testing guidance when not.

**Critical:** Frontend stories are NOT complete until visually verified. This skill ensures UI changes actually work as expected.

---

## When to Use This Skill

Use this skill when:

1. A user story has "Verify in browser using dev-browser skill" in acceptance criteria
2. You've made changes to UI components, styles, or layouts
3. You need to verify interactive behavior (clicks, forms, navigation)
4. You want to capture screenshots for documentation
5. You need to debug visual issues

---

## Prerequisites

Before browser testing:

1. **Dev server running:** The application must be running locally
2. **Changes saved:** All code changes must be saved
3. **Build complete:** If applicable, ensure build/compile step is complete
4. **No TypeScript errors:** Fix any type errors before visual testing

### Starting the Dev Server

```bash
# Next.js / React
npm run dev

# Vite
npm run dev

# Python (Flask/FastAPI)
python app.py
# or
uvicorn main:app --reload

# Go
go run main.go
```

Common ports:
- Next.js/React: `http://localhost:3000`
- Vite: `http://localhost:5173`
- Python: `http://localhost:5000` or `http://localhost:8000`
- Go: `http://localhost:8080`

---

## Browser Testing Workflow

### Step 1: Prepare the Environment

1. Ensure dev server is running
2. Note the URL to test (e.g., `http://localhost:3000/tasks`)
3. Clear any cached state if needed (localStorage, cookies)

### Step 2: Navigate to the Page

If using Claude in Chrome MCP:

```
Use mcp__claude-in-chrome__navigate to go to the test URL
```

If testing manually:
- Open browser
- Navigate to the relevant page
- Ensure you're testing fresh state (clear cache if needed)

### Step 3: Visual Verification

Check each acceptance criterion:

1. **Layout:** Elements positioned correctly
2. **Styling:** Colors, fonts, spacing match design
3. **Responsiveness:** Check different viewport sizes
4. **Content:** Text, images, data displayed correctly

### Step 4: Interactive Testing

For interactive elements:

1. **Buttons:** Click and verify action occurs
2. **Forms:** Fill fields, submit, verify validation
3. **Navigation:** Click links, verify routing works
4. **State changes:** Verify UI updates correctly

### Step 5: Screenshot Capture

Capture screenshots for:
- Verification evidence
- Progress log documentation
- Bug reports if issues found

If using Claude in Chrome MCP:

```
Use mcp__claude-in-chrome__computer with action: "screenshot"
```

### Step 6: Report Results

Document in progress.txt:
- What was tested
- What passed/failed
- Screenshots taken
- Any issues discovered

---

## Claude in Chrome MCP Tools

When the Claude in Chrome extension is available, use these tools:

### Navigation

```
mcp__claude-in-chrome__navigate
- url: "http://localhost:3000/tasks"
- tabId: [from tabs_context_mcp]
```

### Reading Page Content

```
mcp__claude-in-chrome__read_page
- tabId: [tab ID]
- filter: "interactive" (for buttons/inputs) or "all"
```

### Taking Screenshots

```
mcp__claude-in-chrome__computer
- action: "screenshot"
- tabId: [tab ID]
```

### Clicking Elements

```
mcp__claude-in-chrome__computer
- action: "left_click"
- coordinate: [x, y]
- tabId: [tab ID]
```

Or use element reference:

```
mcp__claude-in-chrome__computer
- action: "left_click"
- ref: "ref_42"
- tabId: [tab ID]
```

### Filling Forms

```
mcp__claude-in-chrome__form_input
- ref: "ref_15"
- value: "test value"
- tabId: [tab ID]
```

### Finding Elements

```
mcp__claude-in-chrome__find
- query: "add task button"
- tabId: [tab ID]
```

---

## Testing Checklist by Story Type

### Database/Schema Changes
- [ ] No visual testing needed
- [ ] Verify via API or database query

### API/Backend Changes
- [ ] Test via frontend if UI consumes the API
- [ ] Or verify via curl/API client

### UI Component Changes
- [ ] Component renders correctly
- [ ] Props display expected values
- [ ] Styling matches design
- [ ] Responsive behavior correct
- [ ] Accessibility (keyboard nav, screen reader)

### Interactive Feature Changes
- [ ] Click handlers work
- [ ] Form submission works
- [ ] Validation messages display
- [ ] Loading states appear
- [ ] Error states display correctly
- [ ] Success feedback shown

### Navigation/Routing Changes
- [ ] Links navigate correctly
- [ ] URL updates as expected
- [ ] Browser back/forward works
- [ ] Deep linking works

---

## Common Issues and Solutions

### Page Not Loading

1. Check dev server is running
2. Check correct port
3. Check for build errors in terminal
4. Clear browser cache

### Element Not Found

1. Wait for page to fully load
2. Check if element is conditionally rendered
3. Verify correct page/route
4. Check for JavaScript errors in console

### Styles Not Applied

1. Hard refresh (Cmd+Shift+R / Ctrl+Shift+R)
2. Check CSS file is imported
3. Check for CSS conflicts
4. Verify Tailwind classes exist (if using Tailwind)

### Click Not Working

1. Check element is not covered by another element
2. Check element is not disabled
3. Verify correct coordinates
4. Try using element reference instead of coordinates

---

## Verification Report Format

After testing, document results:

```markdown
## Browser Verification - [Story ID]

**URL:** http://localhost:3000/tasks
**Date:** [timestamp]

### Acceptance Criteria

1. [Criterion 1]
   - Status: PASS/FAIL
   - Notes: [observations]

2. [Criterion 2]
   - Status: PASS/FAIL
   - Notes: [observations]

### Screenshots

- [Screenshot 1 description]
- [Screenshot 2 description]

### Issues Found

- [Issue 1] - [severity] - [description]
- [Issue 2] - [severity] - [description]

### Result: PASS/FAIL
```

---

## Integration with Ralph Loop

When Ralph encounters "Verify in browser using dev-browser skill":

1. **Pause implementation:** All code changes complete
2. **Start dev server:** If not already running
3. **Navigate to page:** Go to the relevant URL
4. **Verify each criterion:** Test interactively
5. **Take screenshots:** Document the state
6. **Report results:** Update progress.txt

If verification fails:
1. Document what failed
2. Fix the issue
3. Re-run verification
4. Only mark story as passed when ALL criteria verified

---

## Manual Testing Fallback

If Claude in Chrome MCP is not available:

1. **Instruct user** to open the browser
2. **Provide exact URL** to navigate to
3. **List specific actions** to perform
4. **Describe expected results** for each action
5. **Ask user to confirm** each criterion passes

Example:

```
Please verify the following in your browser:

1. Open http://localhost:3000/tasks

2. Look for the priority badge on each task card
   - Expected: Colored badges (red/yellow/gray)
   - Visible without hovering?

3. Click the "High" filter button
   - Expected: Only high-priority tasks shown
   - URL should update to include ?priority=high

Please confirm: Do all checks pass? (yes/no)
```

---

## Best Practices

1. **Always verify before marking story complete**
   - Don't assume code works
   - Visual bugs are common
   - Interactive issues only show up in browser

2. **Test the happy path AND edge cases**
   - Empty states
   - Error states
   - Loading states
   - Boundary conditions

3. **Document everything**
   - Screenshots are proof
   - Notes help future iterations
   - Issues logged save time later

4. **Fix issues before proceeding**
   - Don't leave broken UI
   - Ralph loop depends on each story being complete
   - Broken UI compounds across iterations
