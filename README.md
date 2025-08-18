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

## Customizing Nudge Prompts

The nudger now supports configurable prompts! You can customize the messages to match your preferred style.

### Configuration File Locations

The nudger looks for configuration files in this order:
1. `~/.claude/nudger-config.json` (global config)
2. `./nudger-config.json` (project-specific config)

### Quick Templates

Use environment variables for quick template switching:

```bash
# Polite nudging
export NUDGER_TEMPLATE=polite

# Aggressive nudging  
export NUDGER_TEMPLATE=aggressive

# Minimal nudging
export NUDGER_TEMPLATE=minimal

# Back to default
export NUDGER_TEMPLATE=default
```

### Custom Configuration

Create a `nudger-config.json` file to fully customize your prompts:

```json
{
  "prompts": {
    "header": "🤖 Hey Claude, before you're done: (Nudge {{nudge_count}}/{{max_nudges}})",
    "project_line": "   Project: {{project_name}}",
    "required_actions": [
      "Did you actually test your work?",
      "Please check task-tree MCP server to see if there are any tasks left for the current session if you are truly done with the current task",
      "Ask the user: 'What would you like me to work on next?'",
      "Do NOT make up additional tasks",
      "Wait for user direction"
    ],
    "footer": "To stop nudging: touch \"{{done_file}}\""
  }
}
```

### Template Variables

Available template variables:
- `{{nudge_count}}` - Current nudge number
- `{{max_nudges}}` - Maximum nudges allowed
- `{{project_name}}` - Current project name
- `{{done_file}}` - Path to session completion file

### Built-in Templates

The configuration file includes several built-in templates:

- **default**: Standard nudging messages
- **polite**: Gentler, more courteous language
- **aggressive**: More forceful reminders (perfect for tight deadlines!)
- **minimal**: Short and sweet

Copy `nudger-config.json` to `~/.claude/` to use globally, or keep it in your project directory for project-specific customization.

## Management Commands

- **Reset nudging for current project:** `rm ~/.claude/nudge_state_*`
- **Disable nudging for current project:** `touch ~/.claude/stop_nudge_*`
- **Reset all projects:** `rm ~/.claude/nudge_state_* ~/.claude/stop_nudge_*`
- **Test configuration:** `./test-configurable-nudger.sh`
- **Uninstall:** `rm ~/.claude/hooks/claude-env-nudger.sh`