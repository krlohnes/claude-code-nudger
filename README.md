# Claude Code Task Nudger

A Claude Code hook that reminds Claude to keep working when there are still tasks to complete.

## What it does

This tool hooks into Claude Code's "Stop" event and checks if there's still work to be done. If it finds incomplete tasks, it nudges Claude to continue working.

## How it works

- Monitors Claude Code's responses for task completion signals
- Checks for active todos, failed tests, or incomplete implementations
- Sends a gentle reminder when work remains unfinished

## Installation

1. Add the hook configuration to your Claude Code settings
2. Make the nudger script executable
3. Customize the nudging behavior as needed

## Configuration

The tool is configured via Claude Code's hooks system in your settings file.