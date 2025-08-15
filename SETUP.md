# Quick Setup Guide

## Install the Nudger

1. **Copy the script to your Claude hooks directory:**
   ```bash
   mkdir -p ~/.claude/hooks
   cp claude-env-nudger.sh ~/.claude/hooks/
   chmod +x ~/.claude/hooks/claude-env-nudger.sh
   ```

2. **Add to your Claude Code settings** (`~/.claude/settings.json`):
   ```json
   {
     "hooks": {
       "Stop": [
         {
           "matcher": ".*",
           "hooks": [
             {
               "type": "command",
               "command": "$HOME/.claude/hooks/claude-env-nudger.sh",
               "description": "Nudge Claude to keep working"
             }
           ]
         }
       ]
     }
   }
   ```

3. **Done!** Now every time Claude stops, it'll get nudged to continue.

## How it works

- Nudges Claude up to 3 times per session
- Each project gets its own counter (won't interfere with other projects)
- Auto-resets after 10 minutes of inactivity
- State stored in `~/.claude/nudge_state_*` files

## Control commands

- **Reset nudging for current project:** `rm ~/.claude/nudge_state_*current_project*`
- **Disable nudging for current project:** `touch ~/.claude/stop_nudge_*current_project*`
- **Reset all projects:** `rm ~/.claude/nudge_state_* ~/.claude/stop_nudge_*`