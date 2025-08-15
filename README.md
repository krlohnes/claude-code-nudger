# Claude Code Nudger

A simple Claude Code hook that gives Claude a gentle nudge to keep working when it stops responding. No fancy logic - just a friendly reminder that says "Hey, you sure you're done?"

## What it does

This tool hooks into Claude Code's "Stop" event and automatically sends a nudge message asking Claude to consider if there's more work to be done. It's like having a project manager who taps you on the shoulder and asks "What's next?"

## How it works

- Triggers every time Claude stops responding in a conversation
- Sends up to 3 nudges per project session
- Each project gets its own nudge counter (won't interfere with other projects)
- Auto-resets the counter after 10 minutes of inactivity
- State files are stored in `~/.claude/` with project-specific naming

## Installation

### Easy Install (Recommended)
```bash
./install.sh
```

### Manual Install
1. **Copy the script:**
   ```bash
   mkdir -p ~/.claude/hooks
   cp claude-env-nudger.sh ~/.claude/hooks/
   chmod +x ~/.claude/hooks/claude-env-nudger.sh
   ```

2. **Add to Claude Code settings** (`~/.claude/settings.json`):
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

## Management Commands

- **Reset nudging for current project:** `rm ~/.claude/nudge_state_*`
- **Disable nudging for current project:** `touch ~/.claude/stop_nudge_*`
- **Reset all projects:** `rm ~/.claude/nudge_state_* ~/.claude/stop_nudge_*`
- **Uninstall:** `rm ~/.claude/hooks/claude-env-nudger.sh`