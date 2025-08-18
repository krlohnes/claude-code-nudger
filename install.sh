#!/bin/bash

# Claude Code Nudger Installer
# One-click install script for lazy bastards (said with love)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔══════════════════════════════════════╗"
echo "║     Claude Code Nudger Installer    ║"
echo "║        (For Lazy Developers)        ║"
echo "╚══════════════════════════════════════╝"
echo -e "${NC}"

# Check if we're in the right directory
if [ ! -f "claude-env-nudger.sh" ]; then
    echo -e "${RED}❌ Error: Can't find claude-env-nudger.sh in current directory${NC}"
    echo "   Make sure you're running this from the minder-mcp directory"
    exit 1
fi

echo -e "${YELLOW}🔍 Checking your setup...${NC}"

# Create Claude hooks directory
HOOKS_DIR="$HOME/.claude/hooks"
echo "📁 Creating hooks directory: $HOOKS_DIR"
mkdir -p "$HOOKS_DIR"

# Copy the nudger script
echo "📋 Installing nudger script..."
cp claude-env-nudger.sh "$HOOKS_DIR/"
chmod +x "$HOOKS_DIR/claude-env-nudger.sh"

# Handle UserPromptSubmit hook for session complete cleanup
PROMPT_HOOK="$HOOKS_DIR/user-prompt-submit"
echo "🔧 Setting up session complete cleanup..."

if [ -f "$PROMPT_HOOK" ]; then
    echo "ℹ️  Found existing UserPromptSubmit hook - patching it..."
    # Check if our cleanup code is already there
    if grep -q "session_complete" "$PROMPT_HOOK" 2>/dev/null; then
        echo "✅ Session complete cleanup already configured"
    else
        echo "➕ Adding session complete cleanup to existing hook..."
        # Insert our cleanup code after the shebang
        sed -i.bak '2i\
\
# Clean up any session complete files (for nudger tool)\
if [ -n "$CLAUDE_PROJECT_DIR" ]; then\
    SESSION_ID=$(echo "$CLAUDE_PROJECT_DIR" | sed '\''s/[^a-zA-Z0-9]/_/g'\'')\
else\
    SESSION_ID=$(pwd | sed '\''s/[^a-zA-Z0-9]/_/g'\'')\
fi\
DONE_FILE="$HOME/.claude/session_complete_${SESSION_ID}"\
NUDGE_FILE="$HOME/.claude/nudge_state_${SESSION_ID}"\
if [ -f "$DONE_FILE" ]; then\
    rm "$DONE_FILE"\
    # Reset nudge counter when user sends new prompt after session completion\
    rm "$NUDGE_FILE" 2>/dev/null\
fi\
' "$PROMPT_HOOK"
        echo "✅ Patched existing UserPromptSubmit hook"
    fi
else
    echo "📝 Creating new UserPromptSubmit hook..."
    cat > "$PROMPT_HOOK" << 'EOF'
#!/bin/bash

# Clean up any session complete files (for nudger tool)
if [ -n "$CLAUDE_PROJECT_DIR" ]; then
    SESSION_ID=$(echo "$CLAUDE_PROJECT_DIR" | sed 's/[^a-zA-Z0-9]/_/g')
else
    SESSION_ID=$(pwd | sed 's/[^a-zA-Z0-9]/_/g')
fi
DONE_FILE="$HOME/.claude/session_complete_${SESSION_ID}"
NUDGE_FILE="$HOME/.claude/nudge_state_${SESSION_ID}"
if [ -f "$DONE_FILE" ]; then
    rm "$DONE_FILE"
    # Reset nudge counter when user sends new prompt after session completion
    rm "$NUDGE_FILE" 2>/dev/null
fi

# Exit successfully
exit 0
EOF
    chmod +x "$PROMPT_HOOK"
    echo "✅ Created UserPromptSubmit hook"
fi

# Check if settings file exists
SETTINGS_FILE="$HOME/.claude/settings.json"
BACKUP_FILE="$HOME/.claude/settings.json.backup-$(date +%Y%m%d-%H%M%S)"

if [ -f "$SETTINGS_FILE" ]; then
    echo -e "${YELLOW}⚠️  Found existing Claude settings file${NC}"
    echo "🔄 Creating backup: $(basename $BACKUP_FILE)"
    cp "$SETTINGS_FILE" "$BACKUP_FILE"
    
    # Smart patching of existing settings
    if grep -q '"hooks"' "$SETTINGS_FILE" 2>/dev/null; then
        echo "🔧 Found existing hooks - patching settings intelligently..."
        
        # Check if Stop hooks already exist
        if grep -q '"Stop"' "$SETTINGS_FILE" 2>/dev/null; then
            echo "🔍 Stop hooks already exist - adding our nudger to the list..."
            # Add our nudger to existing Stop hooks
            python3 -c "
import json
import sys

try:
    with open('$SETTINGS_FILE', 'r') as f:
        settings = json.load(f)
    
    # Ensure hooks structure exists
    if 'hooks' not in settings:
        settings['hooks'] = {}
    if 'Stop' not in settings['hooks']:
        settings['hooks']['Stop'] = []
    
    # Check if our nudger is already there
    nudger_exists = False
    for stop_hook in settings['hooks']['Stop']:
        if 'hooks' in stop_hook:
            for hook in stop_hook['hooks']:
                if 'claude-env-nudger.sh' in hook.get('command', ''):
                    nudger_exists = True
                    break
    
    if not nudger_exists:
        # Add our nudger
        new_hook = {
            'matcher': '.*',
            'hooks': [{
                'type': 'command',
                'command': '$HOOKS_DIR/claude-env-nudger.sh',
                'description': 'Nudge Claude to keep working'
            }]
        }
        settings['hooks']['Stop'].append(new_hook)
        
        with open('$SETTINGS_FILE', 'w') as f:
            json.dump(settings, f, indent=2)
        print('✅ Added nudger to existing Stop hooks')
    else:
        print('ℹ️  Nudger already configured')
        
except Exception as e:
    print(f'❌ Error patching settings: {e}')
    sys.exit(1)
"
        else
            echo "➕ Adding Stop hooks section to existing hooks..."
            # Add Stop section to existing hooks
            python3 -c "
import json

try:
    with open('$SETTINGS_FILE', 'r') as f:
        settings = json.load(f)
    
    if 'hooks' not in settings:
        settings['hooks'] = {}
    
    settings['hooks']['Stop'] = [{
        'matcher': '.*',
        'hooks': [{
            'type': 'command',
            'command': '$HOOKS_DIR/claude-env-nudger.sh',
            'description': 'Nudge Claude to keep working'
        }]
    }]
    
    # Add UserPromptSubmit hook if it doesn't exist
    if 'UserPromptSubmit' not in settings['hooks']:
        settings['hooks']['UserPromptSubmit'] = [{
            'hooks': [{
                'type': 'command',
                'command': '$HOOKS_DIR/user-prompt-submit'
            }]
        }]
    
    with open('$SETTINGS_FILE', 'w') as f:
        json.dump(settings, f, indent=2)
    
    print('✅ Added Stop hooks section')
    
except Exception as e:
    print(f'❌ Error adding Stop hooks: {e}')
    exit(1)
"
        fi
    else
        echo "🔧 Adding hooks section to existing settings..."
        # Add entire hooks section
        python3 -c "
import json

try:
    with open('$SETTINGS_FILE', 'r') as f:
        settings = json.load(f)
    
    settings['hooks'] = {
        'Stop': [{
            'matcher': '.*',
            'hooks': [{
                'type': 'command',
                'command': '$HOOKS_DIR/claude-env-nudger.sh',
                'description': 'Nudge Claude to keep working'
            }]
        }]
    }
    
    with open('$SETTINGS_FILE', 'w') as f:
        json.dump(settings, f, indent=2)
    
    print('✅ Added hooks section to settings')
    
except Exception as e:
    print(f'❌ Error adding hooks section: {e}')
    exit(1)
"
    fi
else
    echo "📝 Creating new Claude settings file..."
    cat > "$SETTINGS_FILE" << EOF
{
  "hooks": {
    "Stop": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "$HOOKS_DIR/claude-env-nudger.sh",
            "description": "Nudge Claude to keep working"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$HOOKS_DIR/user-prompt-submit"
          }
        ]
      }
    ]
  }
}
EOF
fi

echo
echo -e "${GREEN}✅ Installation complete!${NC}"
echo "🎉 The nudger is now active!"
echo

echo "🔧 What was installed:"
echo "   • Script: $HOOKS_DIR/claude-env-nudger.sh"
echo "   • Settings: $SETTINGS_FILE"
if [ -f "$BACKUP_FILE" ]; then
    echo "   • Backup: $BACKUP_FILE"
fi

echo
echo "🎮 How to use:"
echo "   • The nudger will now run automatically when Claude stops"
echo "   • It'll nudge up to 3 times per project"
echo "   • Auto-resets after 10 minutes of inactivity"

echo
echo "🛠️  Management commands:"
echo "   • Reset current project: rm ~/.claude/nudge_state_*"
echo "   • Disable current project: touch ~/.claude/stop_nudge_*"
echo "   • Uninstall: rm $HOOKS_DIR/claude-env-nudger.sh"

echo
echo -e "${GREEN}🚀 You're all set! Claude won't be slacking off anymore.${NC}"

# Test the installation
echo
echo -e "${BLUE}🧪 Testing installation...${NC}"
if "$HOOKS_DIR/claude-env-nudger.sh" 2>/dev/null; then
    echo -e "${GREEN}✅ Nudger script works perfectly!${NC}"
else
    echo -e "${YELLOW}⚠️  Nudger test returned an error (this is normal - it means it's working!)${NC}"
fi