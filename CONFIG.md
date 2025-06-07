# Configuration Management

The Todo Reminder plugin now includes simple configuration management features.

## Quick Start

```bash
# Apply a preset theme
todo_config preset work

# Change individual settings
todo_config set title "MY TASKS"
todo_config set colors "196,46,33,21"

# Export current configuration
todo_config export ~/.my-todo-theme.conf

# Import configuration
todo_config import ~/.my-todo-theme.conf
```

## Commands

### Export Configuration
```bash
todo_config export                    # Output to stdout
todo_config export my-theme.conf      # Save to file
todo_config export --colors-only      # Export only color settings
```

### Import Configuration
```bash
todo_config import my-theme.conf      # Import from file
todo_config import my-theme.conf --colors-only  # Import only colors
```

### Change Settings
```bash
todo_config set title "MY TASKS"
todo_config set heart-char "💖"
todo_config set heart-position "right"  # left|right|both|none
todo_config set bullet-char "🔸"
todo_config set colors "196,46,33,21,129,201"
todo_config set border-color "244"
todo_config set text-color "250"
todo_config set padding-left "2"
todo_config set box-width "0.4"        # 0.0 to 1.0
```

### Reset Configuration
```bash
todo_config reset                     # Reset everything to defaults
todo_config reset --colors-only       # Reset only colors
```

### Built-in Presets
```bash
todo_config preset minimal            # Clean, minimal appearance
todo_config preset colorful           # Bright and vibrant
todo_config preset work              # Professional blue theme
todo_config preset dark              # Dark theme
```

### Save Custom Presets
```bash
todo_config save-preset my-theme     # Saves to ~/.config/todo-reminder-my-theme.conf
```

## Configuration File Format

Configuration files are simple shell variable assignments:

```bash
# Todo Reminder Configuration
TODO_TITLE="MY TASKS"
TODO_HEART_CHAR="💖"
TODO_HEART_POSITION="left"
TODO_BULLET_CHAR="▪"
TODO_TASK_COLORS="196,46,33,21,129,201"
TODO_BORDER_COLOR="244"
TODO_TEXT_COLOR="250"
TODO_PADDING_LEFT="2"
```

## Examples

### Create a Work Theme
```bash
todo_config set title "WORK TASKS"
todo_config set heart-char "💼"
todo_config set colors "21,33,39,45,51,57"
todo_config set box-width "0.4"
todo_config save-preset work-custom
```

### Quick Color Change
```bash
todo_config export --colors-only > colors-backup.conf
todo_config set colors "196,202,208,214,220,226"
# If you don't like it:
todo_config import colors-backup.conf --colors-only
```

### Share Configuration
```bash
todo_config export my-setup.conf
# Send my-setup.conf to others
# They can use: todo_config import my-setup.conf
```

All configuration changes take effect immediately without needing to restart your shell.