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

# Function to load and display configurable prompt
load_and_display_prompt() {
    # Default config locations to check
    local config_locations=(
        "$HOME/.claude/nudger-config.json"
        "$(dirname "$0")/nudger-config.json"
        "./nudger-config.json"
    )
    
    # Allow template override via environment variable
    local template="${NUDGER_TEMPLATE:-default}"
    local config_file=""
    
    # Find first existing config file
    for location in "${config_locations[@]}"; do
        if [ -f "$location" ]; then
            config_file="$location"
            break
        fi
    done
    
    if [ -z "$config_file" ]; then
        # Fallback to hardcoded prompt if no config found
        echo "🤖 Hey Claude, before you're done: (Nudge $NUDGE_COUNT/$MAX_NUDGES)" >&2
        echo "   Project: $PROJECT_NAME" >&2
        echo "" >&2
        echo "Required actions:" >&2
        echo "  1. Did you actually test your work?" >&2
        echo "  2. Please check task-tree MCP server to see if there are any tasks left for the current session if you are truly done with the current task" >&2
        echo "  3. Ask the user: 'What would you like me to work on next?'" >&2
        echo "  4. Do NOT make up additional tasks" >&2
        echo "  5. Wait for user direction" >&2
        echo "" >&2
        echo "To stop nudging: touch \"$DONE_FILE\"" >&2
        return
    fi
    
    # Parse JSON and extract prompts (using jq if available, otherwise grep/sed fallback)
    if command -v jq >/dev/null 2>&1; then
        load_prompt_with_jq "$config_file" "$template"
    else
        load_prompt_with_grep "$config_file" "$template"
    fi
}

# Load prompt using jq (preferred method)
load_prompt_with_jq() {
    local config_file="$1"
    local template="$2"
    
    # Try to get template-specific prompts first, fall back to default
    local prompt_path=""
    if [ "$template" != "default" ] && jq -e ".templates.$template" "$config_file" >/dev/null 2>&1; then
        prompt_path=".templates.$template"
    else
        prompt_path=".prompts"
    fi
    
    # Extract and substitute variables in prompts
    local header=$(jq -r "$prompt_path.header" "$config_file" 2>/dev/null)
    local project_line=$(jq -r "$prompt_path.project_line" "$config_file" 2>/dev/null)
    local footer=$(jq -r "$prompt_path.footer" "$config_file" 2>/dev/null)
    
    # Substitute template variables (using | as delimiter to avoid path conflicts)
    header=$(echo "$header" | sed "s|{{nudge_count}}|$NUDGE_COUNT|g; s|{{max_nudges}}|$MAX_NUDGES|g; s|{{project_name}}|$PROJECT_NAME|g")
    project_line=$(echo "$project_line" | sed "s|{{project_name}}|$PROJECT_NAME|g")
    footer=$(echo "$footer" | sed "s|{{done_file}}|$DONE_FILE|g")
    
    # Display header and project line
    echo "$header" >&2
    echo "$project_line" >&2
    echo "" >&2
    
    # Display required actions
    echo "Required actions:" >&2
    local actions_json=$(jq -r "$prompt_path.required_actions" "$config_file" 2>/dev/null)
    local actions_length=$(echo "$actions_json" | jq 'length' 2>/dev/null)
    
    for ((i=0; i<actions_length; i++)); do
        local action=$(echo "$actions_json" | jq -r ".[$i]" 2>/dev/null)
        echo "  $((i+1)). $action" >&2
    done
    
    echo "" >&2
    echo "$footer" >&2
}

# Fallback prompt loading without jq (basic grep/sed)
load_prompt_with_grep() {
    local config_file="$1"
    local template="$2"
    
    # This is a simplified fallback - just use default prompts section
    echo "🤖 Hey Claude, before you're done: (Nudge $NUDGE_COUNT/$MAX_NUDGES)" >&2
    echo "   Project: $PROJECT_NAME" >&2
    echo "" >&2
    echo "Required actions:" >&2
    echo "  1. Did you actually test your work?" >&2
    echo "  2. Please check task-tree MCP server to see if there are any tasks left for the current session if you are truly done with the current task" >&2
    echo "  3. Ask the user: 'What would you like me to work on next?'" >&2
    echo "  4. Do NOT make up additional tasks" >&2
    echo "  5. Wait for user direction" >&2
    echo "" >&2
    echo "To stop nudging: touch \"$DONE_FILE\"" >&2
}

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

# Load and display configurable prompt
load_and_display_prompt

exit 2