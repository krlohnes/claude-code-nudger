#!/bin/bash

echo "🔍 Claude Code Nudger Diagnostic Script"
echo "======================================="
echo

# Check if Claude Code is running
echo "1. Checking Claude Code installation..."
if command -v claude >/dev/null 2>&1; then
    echo "✅ Claude Code found: $(which claude)"
    claude --version 2>/dev/null || echo "⚠️  Could not get Claude Code version"
else
    echo "❌ Claude Code not found in PATH"
fi
echo

# Check hook directory and script
echo "2. Checking nudger script..."
HOOKS_DIR="$HOME/.claude/hooks"
SCRIPT_PATH="$HOOKS_DIR/claude-env-nudger.sh"

if [ -d "$HOOKS_DIR" ]; then
    echo "✅ Hooks directory exists: $HOOKS_DIR"
else
    echo "❌ Hooks directory missing: $HOOKS_DIR"
fi

if [ -f "$SCRIPT_PATH" ]; then
    echo "✅ Nudger script exists: $SCRIPT_PATH"
    if [ -x "$SCRIPT_PATH" ]; then
        echo "✅ Script is executable"
    else
        echo "⚠️  Script not executable - fixing..."
        chmod +x "$SCRIPT_PATH"
    fi
else
    echo "❌ Nudger script missing: $SCRIPT_PATH"
fi
echo

# Check settings.json
echo "3. Checking Claude Code settings..."
SETTINGS_FILE="$HOME/.claude/settings.json"

if [ -f "$SETTINGS_FILE" ]; then
    echo "✅ Settings file exists: $SETTINGS_FILE"
    
    # Check if hooks section exists
    if grep -q '"hooks"' "$SETTINGS_FILE" 2>/dev/null; then
        echo "✅ Hooks section found"
        
        # Check if Stop hooks exist
        if grep -q '"Stop"' "$SETTINGS_FILE" 2>/dev/null; then
            echo "✅ Stop hooks configured"
            
            # Check if our nudger is in there
            if grep -q 'claude-env-nudger.sh' "$SETTINGS_FILE" 2>/dev/null; then
                echo "✅ Nudger hook configured in settings"
            else
                echo "❌ Nudger not found in Stop hooks"
            fi
        else
            echo "❌ No Stop hooks configured"
        fi
    else
        echo "❌ No hooks section in settings"
    fi
    
    # Show the relevant part of settings
    echo
    echo "Current hooks configuration:"
    if command -v jq >/dev/null 2>&1; then
        jq '.hooks' "$SETTINGS_FILE" 2>/dev/null || echo "Could not parse with jq"
    else
        echo "--- Raw settings (hooks section) ---"
        grep -A 30 '"hooks"' "$SETTINGS_FILE" 2>/dev/null || echo "No hooks section found"
    fi
else
    echo "❌ Settings file missing: $SETTINGS_FILE"
fi
echo

# Test the script manually
echo "4. Testing nudger script manually..."
if [ -f "$SCRIPT_PATH" ]; then
    echo "Running: $SCRIPT_PATH"
    echo "--- Output ---"
    "$SCRIPT_PATH" 2>&1 || echo "Script exited with code $?"
    echo "--- End Output ---"
else
    echo "❌ Cannot test - script missing"
fi
echo

# Check environment variables
echo "5. Checking environment..."
echo "HOME: $HOME"
echo "PWD: $(pwd)"
echo "CLAUDE_PROJECT_DIR: ${CLAUDE_PROJECT_DIR:-not set}"
echo

# Check for any state files
echo "6. Checking state files..."
STATE_FILES=$(ls ~/.claude/nudge_state_* ~/.claude/session_complete_* ~/.claude/stop_nudge_* 2>/dev/null || echo "none")
if [ "$STATE_FILES" != "none" ]; then
    echo "Found state files:"
    ls -la ~/.claude/nudge_state_* ~/.claude/session_complete_* ~/.claude/stop_nudge_* 2>/dev/null
else
    echo "No nudger state files found"
fi
echo

echo "🏁 Diagnostic complete!"
echo "Run this script on the problematic machine and share the output."