#!/bin/bash

# Claude Code environment-aware nudger

# Use Claude Code's project directory if available, fallback to PWD
if [ -n "$CLAUDE_PROJECT_DIR" ]; then
    SESSION_ID=$(echo "$CLAUDE_PROJECT_DIR" | sed 's/[^a-zA-Z0-9]/_/g')
    PROJECT_NAME=$(basename "$CLAUDE_PROJECT_DIR")
else
    SESSION_ID=$(pwd | sed 's/[^a-zA-Z0-9]/_/g')
    PROJECT_NAME=$(basename $(pwd))
fi

# State files specific to this Claude Code session
NUDGE_FILE="$HOME/.claude/nudge_state_${SESSION_ID}"
STOP_FILE="$HOME/.claude/stop_nudge_${SESSION_ID}"
DONE_FILE="$HOME/.claude/session_complete_${SESSION_ID}"
MAX_NUDGES=3

# Create .claude directory if it doesn't exist
mkdir -p "$HOME/.claude"

# Check if nudging is disabled for this session
if [ -f "$STOP_FILE" ]; then
    echo "✅ Nudging disabled for project: $PROJECT_NAME"
    echo "   To re-enable: rm \"$STOP_FILE\""
    exit 0
fi

# Check if Claude has marked the session as complete
if [ -f "$DONE_FILE" ]; then
    echo "✅ Session marked complete by Claude for: $PROJECT_NAME"
    echo "   File will be auto-deleted on next user prompt"
    exit 0
fi

# Get current nudge count
if [ -f "$NUDGE_FILE" ]; then
    NUDGE_COUNT=$(cat "$NUDGE_FILE")
    # Get file modification time (cross-platform)
    # Check if we're on macOS (has stat -f) or Linux (has stat -c)
    if stat -f %m "$NUDGE_FILE" >/dev/null 2>&1; then
        # macOS/BSD style
        TIMESTAMP=$(stat -f %m "$NUDGE_FILE")
    elif stat -c %Y "$NUDGE_FILE" >/dev/null 2>&1; then
        # Linux/GNU style
        TIMESTAMP=$(stat -c %Y "$NUDGE_FILE")
    else
        # Fallback if stat is missing or broken
        TIMESTAMP=0
    fi
    NOW=$(date +%s)
    
    # Reset counter if it's been more than 10 minutes since last nudge
    # This prevents old sessions from staying "used up"
    if [ $((NOW - TIMESTAMP)) -gt 600 ]; then
        echo "⏰ Resetting nudge counter (10+ minutes since last nudge)"
        NUDGE_COUNT=0
    fi
else
    NUDGE_COUNT=0
fi

# Increment counter
NUDGE_COUNT=$((NUDGE_COUNT + 1))
echo "$NUDGE_COUNT" > "$NUDGE_FILE"

# Check if we've hit our limit
if [ "$NUDGE_COUNT" -gt "$MAX_NUDGES" ]; then
    echo "🛑 Max nudges reached for: $PROJECT_NAME ($MAX_NUDGES)"
    echo "   To reset: rm \"$NUDGE_FILE\""
    echo "   To disable: touch \"$STOP_FILE\""
    exit 0
fi

echo "🤖 Hey Claude, before you're done: (Nudge $NUDGE_COUNT/$MAX_NUDGES)" >&2
echo "   Project: $PROJECT_NAME" >&2
echo "" >&2
echo "Required actions:" >&2
echo "  1. Did you actually test your work?" >&2
echo "  2. Ask the user: 'What would you like me to work on next?'" >&2
echo "  3. Do NOT make up additional tasks" >&2
echo "  4. Wait for user direction" >&2
echo "" >&2
echo "To stop nudging: touch \"$DONE_FILE\"" >&2

exit 2