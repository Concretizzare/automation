# Contributing to Ralph-Hybrid

Thank you for your interest in improving Ralph-Hybrid! This guide will help you contribute effectively.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Testing Guidelines](#testing-guidelines)
- [Documentation Standards](#documentation-standards)
- [Pull Request Process](#pull-request-process)
- [Reporting Issues](#reporting-issues)

---

## Code of Conduct

Be respectful, constructive, and professional. We're all here to make Ralph better.

---

## How to Contribute

### Types of Contributions Welcome

1. **Bug Fixes**: Fix issues in ralph.sh, prompt.md, or documentation
2. **Documentation**: Improve guides, add examples, fix typos
3. **Examples**: Add PRD examples for new project types
4. **Features**: Enhance Ralph's capabilities (discuss first in an issue)
5. **Testing**: Add test cases, improve validation
6. **Platform Support**: Improve cross-platform compatibility

### What NOT to Contribute

- **Breaking changes** without discussion first
- **Large refactors** without opening an issue
- **Features that add dependencies** (Ralph should stay simple)
- **AI model-specific optimizations** (keep it model-agnostic)

---

## Development Setup

### Prerequisites

```bash
# Required
git --version
bash --version  # or zsh

# Optional (for testing)
docker --version
jq --version
```

### Fork and Clone

```bash
# Fork the repository on GitHub
# Then clone your fork:
git clone https://github.com/YOUR-USERNAME/ralph-hybrid.git
cd ralph-hybrid

# Add upstream remote
git remote add upstream https://github.com/ORIGINAL-AUTHOR/ralph-hybrid.git
```

### Local Testing

```bash
# Create a test project
mkdir test-project
cd test-project
git init

# Copy Ralph files
cp ../ralph-hybrid/ralph.sh .
cp ../ralph-hybrid/prompt.md .
cp ../ralph-hybrid/prd.json.example prd.json

# Make executable
chmod +x ralph.sh

# Edit prd.json with a simple test story
# Run Ralph
./ralph.sh 1
```

---

## Testing Guidelines

### Manual Testing Checklist

Before submitting changes to ralph.sh:

- [ ] Test with Docker mode (`RALPH_USE_DOCKER=yes`)
- [ ] Test with CLI mode (`RALPH_USE_DOCKER=no`)
- [ ] Test auto-detection (`RALPH_USE_DOCKER=auto`)
- [ ] Test with valid prd.json
- [ ] Test with invalid prd.json (should show helpful error)
- [ ] Test with missing prompt.md (should show error)
- [ ] Test notification (if applicable)
- [ ] Test archiving (switch branches mid-run)
- [ ] Test completion signal detection

### Test Environments

**macOS**:
```bash
# Test with terminal-notifier
RALPH_NOTIFY_TOOL=terminal-notifier ./ralph.sh 1

# Test with Docker Desktop
RALPH_USE_DOCKER=yes ./ralph.sh 1
```

**Linux**:
```bash
# Test with notify-send
RALPH_NOTIFY_TOOL=notify-send ./ralph.sh 1

# Test with native Docker
RALPH_USE_DOCKER=yes ./ralph.sh 1
```

**Windows (WSL2)**:
```bash
# Test in WSL environment
./ralph.sh 1
```

### Testing Prompt Changes

```bash
# Create a minimal test PRD
cat > prd.json << 'EOF'
{
  "project": "Test",
  "branchName": "ralph/test",
  "description": "Test story",
  "userStories": [{
    "id": "US-001",
    "title": "Create hello.txt",
    "description": "Create a file called hello.txt",
    "acceptanceCriteria": ["File exists", "Contains 'Hello World'"],
    "priority": 1,
    "passes": false,
    "notes": ""
  }]
}
EOF

# Run with modified prompt.md
./ralph.sh 1

# Verify story completed
jq '.userStories[0].passes' prd.json
# Should output: true
```

### Testing Documentation

- [ ] All links work (no 404s)
- [ ] Code examples are valid
- [ ] Examples in docs can be copy-pasted and work
- [ ] Markdown renders correctly on GitHub
- [ ] Table of contents is accurate

---

## Documentation Standards

### File Naming

- Main documentation: `UPPERCASE.md` (e.g., `README.md`, `STRUCTURE.md`)
- Subdocs: `lowercase-kebab.md` (e.g., `docs/troubleshooting.md`)
- Templates: `.example` suffix (e.g., `prd.json.example`)

### Writing Style

- **Be concise**: No unnecessary words
- **Be specific**: "Run `npm test`" not "Run the tests"
- **Use examples**: Show, don't just tell
- **Use code blocks**: Always specify language (e.g., ```bash)
- **Use tables**: For structured comparisons
- **Active voice**: "Run this command" not "This command should be run"

### Documentation Checklist

- [ ] Clear purpose statement at top
- [ ] Table of contents for docs >100 lines
- [ ] Code examples are tested
- [ ] Cross-references use relative links
- [ ] No broken links
- [ ] Updated "Last Updated" date (if applicable)

---

## Pull Request Process

### Before Opening a PR

1. **Test your changes** following the testing guidelines
2. **Update documentation** if you changed behavior
3. **Check for conflicts** with main branch
4. **Run shellcheck** on ralph.sh (if you modified it):
   ```bash
   shellcheck ralph.sh
   ```

### PR Title Format

Use conventional commit format:

- `feat: Add support for XYZ`
- `fix: Correct Docker detection on Windows`
- `docs: Improve troubleshooting guide`
- `refactor: Simplify notification detection`
- `test: Add test for archiving behavior`

### PR Description Template

```markdown
## What Changed

[Brief description of the change]

## Why

[Why this change is needed]

## Testing

[How you tested this change]

- [ ] Tested on macOS
- [ ] Tested on Linux
- [ ] Tested on Windows WSL2
- [ ] Tested Docker mode
- [ ] Tested CLI mode
- [ ] Documentation updated

## Related Issues

Fixes #123
Related to #456
```

### Review Process

1. **Automated checks**: Must pass (if we add CI)
2. **Manual review**: Maintainer will review within 1 week
3. **Feedback**: Address feedback in new commits
4. **Merge**: Squash commits when merging

---

## Reporting Issues

### Before Reporting

1. **Search existing issues**: Your issue may already exist
2. **Check documentation**: README, TROUBLESHOOTING, etc.
3. **Test on latest version**: Pull latest from main
4. **Minimal reproduction**: Create smallest example that shows the bug

### Issue Template

**Title**: Clear, specific description (e.g., "Docker detection fails on Ubuntu 22.04")

**Body**:
```markdown
## Description

[Clear description of the issue]

## Steps to Reproduce

1. Step one
2. Step two
3. Step three

## Expected Behavior

[What should happen]

## Actual Behavior

[What actually happens]

## Environment

- OS: [e.g., macOS 13.0, Ubuntu 22.04]
- Ralph version: [from ralph.sh header]
- Docker version: [output of `docker --version`]
- Claude version: [output of `claude --version`]
- Shell: [bash, zsh, etc.]

## Logs/Output

```bash
[Paste relevant logs or error messages]
```

## Additional Context

[Any other relevant information]
```

### Issue Labels

We use these labels:

- `bug`: Something isn't working
- `documentation`: Improvements or additions to docs
- `enhancement`: New feature or request
- `good first issue`: Good for new contributors
- `help wanted`: Extra attention needed
- `question`: Further information requested
- `wontfix`: This will not be worked on

---

## Specific Contribution Areas

### Improving ralph.sh

**Guidelines**:
- Keep it POSIX-compliant where possible
- Comment non-obvious logic
- Use functions for reusable code
- Fail-safe defaults (graceful degradation)
- Test on bash 3.2+ (macOS default)

**Example function structure**:
```bash
# Brief description of what this function does
# Args: $1 = description of first argument
# Returns: 0 on success, 1 on failure
function_name() {
  local arg1="$1"

  # Function logic here

  return 0
}
```

### Improving prompt.md

**Guidelines**:
- Keep instructions clear and actionable
- Use examples liberally
- Order sections by importance
- Test that Claude follows the instructions
- Don't make assumptions about project structure

**Testing prompt changes**:
1. Create test PRD with known outcome
2. Run Ralph with modified prompt
3. Verify behavior matches expectations
4. Test on different project types

### Adding Examples

**PRD Example Requirements**:
- Realistic user stories
- Clear acceptance criteria
- Appropriate priority ordering
- Story dependencies noted
- 10-15 stories minimum
- JSON validates (`jq . example.prd.json`)

**Example naming**:
- `examples/project-type.prd.json`
- e.g., `examples/mobile-app.prd.json`
- e.g., `examples/data-pipeline.prd.json`

### Improving Documentation

**High-value documentation contributions**:
- More detailed troubleshooting scenarios
- Platform-specific guides (Windows, Linux distros)
- Integration examples (CI/CD, hooks)
- Video tutorials or GIFs
- Translations (if there's demand)

---

## Development Workflow

### 1. Create a branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-you-are-fixing
```

### 2. Make changes

- Edit files
- Test locally
- Commit frequently with clear messages

### 3. Commit

```bash
git add .
git commit -m "feat: Add support for XYZ"
```

Use conventional commits:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation only
- `refactor:` Code change that neither fixes a bug nor adds a feature
- `test:` Adding missing tests
- `chore:` Changes to build process or auxiliary tools

### 4. Push and PR

```bash
git push origin feature/your-feature-name
```

Open PR on GitHub with clear description.

### 5. Address feedback

```bash
# Make requested changes
git add .
git commit -m "fix: Address review feedback"
git push
```

### 6. Merge

Maintainer will squash and merge when approved.

---

## Code Review Guidelines

### As a Reviewer

- Be kind and constructive
- Ask questions rather than making demands
- Acknowledge good work
- Focus on important issues
- Suggest alternatives

### As a Contributor

- Don't take feedback personally
- Ask for clarification if needed
- Be open to different approaches
- Keep discussions on topic
- Be patient

---

## Release Process

(For maintainers)

1. Update version in ralph.sh header
2. Update CHANGELOG.md
3. Create git tag: `git tag v1.x.x`
4. Push tag: `git push --tags`
5. Create GitHub release with notes

---

## Questions?

- Open a [GitHub Discussion](https://github.com/YOUR-REPO/discussions)
- Comment on relevant issue
- Read existing documentation

---

## Recognition

Contributors will be:
- Mentioned in release notes
- Added to contributors list (if significant contribution)
- Thanked publicly

---

Thank you for contributing to Ralph-Hybrid!
