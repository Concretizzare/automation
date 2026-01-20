#!/bin/bash
# =============================================================================
# Ralph Hybrid - Autonomous AI Agent Loop
# =============================================================================
# Combines the best features from:
#   - ralph (original, production-ready): archiving, error handling, prompt.md
#   - ralph-wiggum (Claude Code port): Docker sandbox, notifications
#
# Usage: ./ralph.sh [max_iterations]
#   max_iterations: Number of iterations to run (default: 10)
#
# Requirements:
#   - Claude Code CLI (claude) OR Docker with Claude Code image
#   - jq for JSON parsing
#   - Git repository for your project
# =============================================================================

set -e  # Exit on error (individual commands use || true for safe failure)

# =============================================================================
# PATH SETUP - Resolve script location first (needed for .env loading)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# LOAD .env CONFIGURATION (if exists)
# =============================================================================
# Environment variables from .env file are loaded early so they can be used
# in the configuration section below. Priority: CLI args > env vars > defaults

if [ -f "$SCRIPT_DIR/.env" ]; then
    # shellcheck disable=SC1090
    source "$SCRIPT_DIR/.env"
fi

# =============================================================================
# CONFIGURATION - Customize these for your environment
# =============================================================================

# Default maximum iterations if not specified
# Supports: RALPH_MAX_ITERATIONS, MAX_ITERATIONS, or command line argument
DEFAULT_MAX_ITERATIONS=${RALPH_MAX_ITERATIONS:-${MAX_ITERATIONS:-10}}

# Cooling period between iterations (seconds) - prevents rate limiting
# Supports: RALPH_COOLING_PERIOD or COOLING_PERIOD
COOLING_PERIOD=${RALPH_COOLING_PERIOD:-${COOLING_PERIOD:-2}}

# Docker settings
USE_DOCKER="${RALPH_USE_DOCKER:-auto}"  # "auto", "yes", or "no"
DOCKER_IMAGE="${RALPH_DOCKER_IMAGE:-claude-code}"
DOCKER_PERMISSION_MODE="${RALPH_DOCKER_PERMISSION:-acceptEdits}"

# Notification tool (auto-detected if not set)
# Supported: "tt", "terminal-notifier", "notify-send", "none"
NOTIFY_TOOL="${RALPH_NOTIFY_TOOL:-auto}"

# Claude CLI permission mode (when not using Docker)
CLAUDE_PERMISSION_MODE="${RALPH_CLAUDE_PERMISSION:---dangerously-skip-permissions}"

# =============================================================================
# KEY FILE PATHS
# =============================================================================

PRD_FILE="$SCRIPT_DIR/prd.json"
PROMPT_FILE="$SCRIPT_DIR/prompt.md"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
ARCHIVE_DIR="$SCRIPT_DIR/archive"
LAST_BRANCH_FILE="$SCRIPT_DIR/.last-branch"

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

# Support both required argument (ralph-wiggum style) and default value (ralph style)
if [ -n "$1" ]; then
    MAX_ITERATIONS="$1"
else
    MAX_ITERATIONS="$DEFAULT_MAX_ITERATIONS"
fi

# Validate iteration count
if ! [[ "$MAX_ITERATIONS" =~ ^[0-9]+$ ]] || [ "$MAX_ITERATIONS" -lt 1 ]; then
    echo "Error: Invalid iteration count '$MAX_ITERATIONS'. Must be a positive integer."
    echo "Usage: $0 [max_iterations]"
    exit 1
fi

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

# Print a visual separator for iteration boundaries
print_separator() {
    local iteration="$1"
    local max="$2"
    echo ""
    echo "==============================================================================="
    echo "  Ralph Iteration $iteration of $max"
    echo "  $(date '+%Y-%m-%d %H:%M:%S')"
    echo "==============================================================================="
    echo ""
}

# Detect and configure notification tool
setup_notifications() {
    if [ "$NOTIFY_TOOL" = "none" ]; then
        return
    fi

    if [ "$NOTIFY_TOOL" = "auto" ]; then
        # Auto-detect available notification tool
        if command -v tt &> /dev/null; then
            NOTIFY_TOOL="tt"
        elif command -v terminal-notifier &> /dev/null; then
            NOTIFY_TOOL="terminal-notifier"
        elif command -v notify-send &> /dev/null; then
            NOTIFY_TOOL="notify-send"
        else
            NOTIFY_TOOL="none"
        fi
    fi
}

# Send desktop notification
notify() {
    local message="$1"
    local title="${2:-Ralph}"

    case "$NOTIFY_TOOL" in
        tt)
            tt notify "$message" 2>/dev/null || true
            ;;
        terminal-notifier)
            terminal-notifier -title "$title" -message "$message" 2>/dev/null || true
            ;;
        notify-send)
            notify-send "$title" "$message" 2>/dev/null || true
            ;;
        none|*)
            # No notification - silent
            ;;
    esac
}

# Detect whether to use Docker
detect_docker() {
    if [ "$USE_DOCKER" = "yes" ]; then
        if ! command -v docker &> /dev/null; then
            echo "Error: Docker requested but not installed."
            exit 1
        fi
        return 0  # Use Docker
    elif [ "$USE_DOCKER" = "no" ]; then
        return 1  # Don't use Docker
    else
        # Auto-detect: prefer Docker if available and image exists
        if command -v docker &> /dev/null; then
            if docker image inspect "$DOCKER_IMAGE" &> /dev/null; then
                return 0  # Use Docker
            fi
        fi
        # Fall back to direct claude CLI
        if command -v claude &> /dev/null; then
            return 1  # Don't use Docker
        fi
        echo "Error: Neither Docker (with $DOCKER_IMAGE image) nor claude CLI found."
        exit 1
    fi
}

# Run Claude with the prompt - handles both Docker and direct CLI
run_claude() {
    local prompt_content="$1"

    if detect_docker; then
        # Docker sandbox mode (from ralph-wiggum)
        docker sandbox run "$DOCKER_IMAGE" claude \
            --permission-mode "$DOCKER_PERMISSION_MODE" \
            -p "$prompt_content" 2>&1
    else
        # Direct CLI mode (from ralph, adapted for Claude Code)
        # Use @file syntax to reference files directly
        echo "$prompt_content" | claude $CLAUDE_PERMISSION_MODE 2>&1
    fi
}

# =============================================================================
# PRE-FLIGHT CHECKS
# =============================================================================

# Validate required files exist
if [ ! -f "$PRD_FILE" ]; then
    echo "Error: PRD file not found at $PRD_FILE"
    echo "Create a prd.json file with your user stories. See prd.json.example for format."
    exit 1
fi

if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: Prompt file not found at $PROMPT_FILE"
    echo "Create a prompt.md file with agent instructions."
    exit 1
fi

# Validate jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    echo "Install with: brew install jq (macOS) or apt-get install jq (Linux)"
    exit 1
fi

# Setup notification tool
setup_notifications

# =============================================================================
# ARCHIVING SYSTEM - Archive previous run if branch changed
# =============================================================================

if [ -f "$PRD_FILE" ] && [ -f "$LAST_BRANCH_FILE" ]; then
    # Read current branch from PRD
    CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null) || CURRENT_BRANCH=""
    LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null) || LAST_BRANCH=""

    if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_BRANCH" ] && [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
        # Branch changed - archive the previous run
        DATE=$(date +%Y-%m-%d)
        # Strip "ralph/" prefix from branch name for cleaner folder names
        FOLDER_NAME=$(echo "$LAST_BRANCH" | sed 's|^ralph/||')
        ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"

        echo "Archiving previous run: $LAST_BRANCH"
        mkdir -p "$ARCHIVE_FOLDER"

        # Copy files to archive (use || true for safe failure)
        [ -f "$PRD_FILE" ] && cp "$PRD_FILE" "$ARCHIVE_FOLDER/" || true
        [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/" || true

        echo "  Archived to: $ARCHIVE_FOLDER"

        # Reset progress file for new run
        {
            echo "# Ralph Progress Log"
            echo "Started: $(date)"
            echo "Branch: $CURRENT_BRANCH"
            echo ""
            echo "## Codebase Patterns"
            echo "(Add reusable patterns discovered during implementation here)"
            echo ""
            echo "---"
        } > "$PROGRESS_FILE"
    fi
fi

# =============================================================================
# BRANCH TRACKING - Save current branch for future archiving
# =============================================================================

if [ -f "$PRD_FILE" ]; then
    CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null) || CURRENT_BRANCH=""
    if [ -n "$CURRENT_BRANCH" ]; then
        echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"
    fi
fi

# =============================================================================
# PROGRESS FILE INITIALIZATION
# =============================================================================

if [ ! -f "$PROGRESS_FILE" ]; then
    PROJECT_NAME=$(jq -r '.project // "Unknown"' "$PRD_FILE" 2>/dev/null) || PROJECT_NAME="Unknown"
    CURRENT_BRANCH=$(jq -r '.branchName // "unknown"' "$PRD_FILE" 2>/dev/null) || CURRENT_BRANCH="unknown"

    {
        echo "# Ralph Progress Log"
        echo "Project: $PROJECT_NAME"
        echo "Branch: $CURRENT_BRANCH"
        echo "Started: $(date)"
        echo ""
        echo "## Codebase Patterns"
        echo "(Add reusable patterns discovered during implementation here)"
        echo ""
        echo "---"
    } > "$PROGRESS_FILE"
fi

# =============================================================================
# MAIN LOOP
# =============================================================================

echo "Starting Ralph - Max iterations: $MAX_ITERATIONS"
echo "PRD: $PRD_FILE"
echo "Prompt: $PROMPT_FILE"
echo "Progress: $PROGRESS_FILE"
if detect_docker; then
    echo "Mode: Docker sandbox ($DOCKER_IMAGE)"
else
    echo "Mode: Direct Claude CLI"
fi
if [ "$NOTIFY_TOOL" != "none" ]; then
    echo "Notifications: $NOTIFY_TOOL"
fi
echo ""

for i in $(seq 1 "$MAX_ITERATIONS"); do
    print_separator "$i" "$MAX_ITERATIONS"

    # Build the prompt content
    # Uses @file syntax for Claude Code to reference files directly
    PROMPT_CONTENT="@$PRD_FILE @$PROGRESS_FILE

$(cat "$PROMPT_FILE")"

    # Run Claude and capture output with tee-like behavior
    # The || true prevents exit on non-zero return (from ralph)
    OUTPUT=$(run_claude "$PROMPT_CONTENT" | tee /dev/stderr) || true

    # Check for completion signal
    if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
        echo ""
        echo "==============================================================================="
        echo "  Ralph completed all tasks!"
        echo "  Finished at iteration $i of $MAX_ITERATIONS"
        echo "==============================================================================="

        # Send completion notification (from ralph-wiggum)
        notify "PRD complete after $i iterations" "Ralph Complete"

        exit 0
    fi

    echo ""
    echo "Iteration $i complete. Continuing..."

    # Cooling period between iterations (from ralph)
    if [ "$i" -lt "$MAX_ITERATIONS" ]; then
        echo "Cooling period: ${COOLING_PERIOD}s..."
        sleep "$COOLING_PERIOD"
    fi
done

# =============================================================================
# MAX ITERATIONS REACHED
# =============================================================================

echo ""
echo "==============================================================================="
echo "  Ralph reached max iterations ($MAX_ITERATIONS) without completing all tasks."
echo "  Check $PROGRESS_FILE for current status."
echo "==============================================================================="

# Send notification about incomplete run
notify "Reached max iterations ($MAX_ITERATIONS) without completing" "Ralph Incomplete"

exit 1
