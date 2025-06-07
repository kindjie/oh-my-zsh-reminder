# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an oh-my-zsh plugin that displays TODO reminders above the terminal prompt. It's a simple zsh plugin with persistent task storage and colorized display.

## Architecture

- **Single File Plugin**: All functionality is contained in `reminder.plugin.zsh`
- **Persistent Storage**: Tasks stored in `~/.todo.sav`, colors in `~/.todo_color.sav`
- **Hook System**: Uses zsh's `precmd` hook to display tasks before each prompt
- **Color Management**: Cycles through 6 colors (red, green, yellow, blue, magenta, cyan) for task differentiation

## Key Functions

- `todo_add_task` (alias: `todo`): Adds new tasks
- `todo_task_done` (alias: `task_done`): Removes completed tasks with tab completion
- `todo_display`: Shows tasks before each prompt with right-aligned formatting
- `show_affirm`: Fetches and displays motivational affirmations asynchronously
- `load_tasks`/`todo_save`: Handle persistent storage

## Development Notes

- This is a pure zsh script - no build process required
- The plugin uses zsh-specific features like typeset arrays and precmd hooks
- External dependency: `curl` and `jq` for affirmations feature

## Testing Workflow

To test plugin modifications:

1. **Basic functionality test**:
   ```bash
   COLUMNS=80 zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh; todo_display'
   ```

2. **Test with sample data**:
   ```bash
   COLUMNS=80 zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh; todo "Test task"; todo_display'
   ```

3. **Test command output preservation**:
   ```bash
   COLUMNS=80 zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh; todo_display; echo "test output"'
   ```

4. **Verify task management**:
   - Add tasks: `todo "New task"`
   - Remove tasks: `task_done "partial match"`
   - Check storage: `cat ~/.todo.sav`

5. **Run idempotent test script**:
   ```bash
   ./test_plugin.zsh
   ```
   (Safely tests with sample data, restores original state)

## Display Layout

- Right side: Todo box (half terminal width) with low-contrast gray borders
- Left side: Motivational affirmation (single line)
- "REMEMBER" displays as title in bright color (no bullet)
- Regular tasks display with bright colored "●" bullets and gray text
- Text wraps within box boundaries with proper indentation
- Dual-color system: bright bullets for visual emphasis, gray text/borders for readability
- No screen clearing - preserves command output