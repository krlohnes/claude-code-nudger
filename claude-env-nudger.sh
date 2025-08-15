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
MAX_NUDGES=3

# Create .claude directory if it doesn't exist
mkdir -p "$HOME/.claude"

# Check if nudging is disabled for this session
if [ -f "$STOP_FILE" ]; then
    echo "✅ Nudging disabled for project: $PROJECT_NAME"
    echo "   To re-enable: rm \"$STOP_FILE\""
    exit 0
fi

# Get current nudge count
if [ -f "$NUDGE_FILE" ]; then
    NUDGE_COUNT=$(cat "$NUDGE_FILE")
    TIMESTAMP=$(stat -f %m "$NUDGE_FILE" 2>/dev/null || stat -c %Y "$NUDGE_FILE" 2>/dev/null || echo 0)
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

echo "🤖 Hey Claude, are you sure you're done? (Nudge $NUDGE_COUNT/$MAX_NUDGES)"
echo "   Project: $PROJECT_NAME"
echo
echo "Consider:"
echo "  - \"Is there anything else I should work on?\""
echo "  - \"What's next?\""

exit 0