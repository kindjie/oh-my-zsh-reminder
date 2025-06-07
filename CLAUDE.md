# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an oh-my-zsh plugin that displays TODO reminders above the terminal prompt. It's a simple zsh plugin with persistent task storage and colorized display.

## Architecture

- **Single File Plugin**: All functionality is contained in `reminder.plugin.zsh`
- **Persistent Storage**: Tasks and colors stored in single file `~/.todo.save`
- **Hook System**: Uses zsh's `precmd` hook to display tasks before each prompt
- **Color Management**: Cycles through 6 colors (red, green, yellow, blue, magenta, cyan) for task differentiation
- **Emoji Support**: Full Unicode character width detection for proper alignment with emojis
- **Configurable Display**: Customizable bullet/heart characters, padding, show/hide states, and box dimensions
- **Runtime Controls**: Toggle commands for showing/hiding components without restart

## Key Functions

- `todo_add_task` (alias: `todo`): Adds new tasks
- `todo_task_done` (alias: `task_done`): Removes completed tasks with tab completion
- `todo_display`: Shows tasks before each prompt with right-aligned formatting
- `fetch_affirmation_async`: Fetches and displays motivational affirmations asynchronously
- `todo_toggle_affirmation/todo_toggle_box/todo_toggle_all`: Runtime visibility controls
- `todo_help`: Abbreviated help command with quick reference
- `format_affirmation`: Handles configurable heart positioning (left/right/both/none)
- `wrap_todo_text`: Text wrapping with emoji-aware width calculation
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
   - Check storage: `cat ~/.todo.save`

5. **Run comprehensive test suite**:
   ```bash
   ./test_plugin.zsh
   ```
   (Tests all features: emoji support, padding, toggles, character width detection)

6. **Visual padding demonstration**:
   ```bash
   ./demo_padding.zsh
   ```
   (Shows all padding configurations with visual borders)

## Display Layout

- Right side: Todo box (configurable width, default 50%) with low-contrast gray borders
- Left side: Motivational affirmation with configurable heart positioning
- Configurable title (default: "REMEMBER") displays in bright color
- Regular tasks display with customizable bullet characters (default: ▪) and gray text
- Text wraps within box boundaries with proper emoji-aware indentation
- Dual-color system: bright bullets for visual emphasis, gray text/borders for readability
- Configurable padding on all sides (top/right/bottom/left)
- Runtime show/hide controls for all components
- Full emoji and Unicode support with proper terminal width calculation
- No screen clearing - preserves command output