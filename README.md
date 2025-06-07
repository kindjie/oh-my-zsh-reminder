# zsh-todo-reminder

A beautiful, configurable zsh plugin that displays your TODO tasks in a right-aligned box with motivational affirmations.

![Basic Display](docs/images/basic-display.png)

## 📸 Screenshots

### Default Display
![Basic Display](docs/images/basic-display.png)
*Clean todo box with motivational affirmations*

### Customization Options
![Customization Themes](docs/images/customization-themes.png)
*Different themes showing title, bullet, and styling flexibility*

### Runtime Controls
![Toggle Controls](docs/images/toggle-controls.png)
*Show/hide components on-the-fly without restart*

## ✨ Features

- **🎨 Beautiful Display**: Right-aligned todo box with Unicode borders and color-coded tasks
- **💝 Motivational Affirmations**: Fetches daily affirmations to keep you motivated
- **⚙️ Fully Configurable**: Customize title, colors, box width, and more
- **🚀 Non-Blocking**: Never slows down your terminal, even with network issues
- **📦 Single File Storage**: Clean, consolidated save format
- **🔍 Smart Completion**: Tab completion for task removal
- **📱 Responsive**: Adapts to terminal width changes

## 🚀 Quick Start

### Installation

**With Antidote:**
```bash
# Add to your .zsh_plugins.txt
kindjie/zsh-todo-reminder kind:defer
```

**With Oh My Zsh:**
```bash
git clone https://github.com/kindjie/zsh-todo-reminder ~/.oh-my-zsh/custom/plugins/reminder
# Add 'reminder' to your plugins list in ~/.zshrc
```

**Manual Installation:**
```bash
git clone https://github.com/kindjie/zsh-todo-reminder
# Source the plugin in your .zshrc:
source /path/to/zsh-todo-reminder/reminder.plugin.zsh
```

### Basic Usage

```bash
# Get help anytime
$ todo_help

# Add a task (because your brain is not a hard drive)
$ todo "Stop procrastinating and finish that thing"
$ todo "Feed the cat before it stages a revolt"
$ todo "Reply to mom's texts from 2 weeks ago"

# Remove a completed task (with tab completion because we're fancy)
$ task_done "Stop proc"  # Tab completion saves your sanity

# Tasks haunt you automatically before each prompt ✨
```

## 📖 Usage

### Quick Help

```bash
# Show all available commands and configuration options
$ todo_help
```

The help command provides a quick reference with:
- All available commands and their usage
- Configuration options with defaults
- File locations 
- Practical examples
- Link to full documentation

### Adding Tasks
```bash
todo "Learn quantum physics (or at least pretend to)"
todo "Convince plants I'm a good plant parent"
todo "Figure out why the printer hates me specifically"
```

### Completing Tasks
```bash
# Remove by partial match (because typing is hard)
task_done "Learn quantum"

# Example: Victory dance after removing a task!
task_done "Convince"  # 🎉 Plant parent status: achieved
```

### Display
- Tasks appear in a right-aligned box before each prompt
- Motivational affirmations appear on the left side
- Color-coded bullets (▪) for visual organization
- Automatic text wrapping for long tasks

## ⚙️ Configuration

Set these variables **before** sourcing the plugin:

```bash
# Box appearance
export TODO_TITLE="TASKS"                    # Box title (default: "REMEMBER")
export TODO_BOX_WIDTH_FRACTION=0.4           # 40% of terminal width (default: 0.5)
export TODO_BOX_MIN_WIDTH=25                 # Minimum width (default: 30)
export TODO_BOX_MAX_WIDTH=70                 # Maximum width (default: 80)

# Character styling
export TODO_HEART_CHAR="💖"                  # Heart character (default: "♥")
export TODO_HEART_POSITION="both"            # "left", "right", "both", "none" (default: "left")
export TODO_BULLET_CHAR="🔸"                 # Task bullet character (default: "▪")

# Show/hide configuration  
export TODO_SHOW_AFFIRMATION="false"         # Show affirmations: "true", "false" (default: "true")
export TODO_SHOW_TODO_BOX="true"             # Show todo box: "true", "false" (default: "true")

# Padding/margin (in characters)
export TODO_PADDING_TOP=1                    # Top padding/margin (default: 0)
export TODO_PADDING_RIGHT=2                  # Right padding/margin (default: 4)
export TODO_PADDING_BOTTOM=1                 # Bottom padding/margin (default: 0)
export TODO_PADDING_LEFT=4                   # Left padding/margin (default: 0)

# File locations
export TODO_SAVE_FILE="$HOME/.my_todos"      # Save location (default: ~/.todo.save)
export TODO_AFFIRMATION_FILE="/tmp/affirm"   # Affirmation cache (default: /tmp/todo_affirmation)
```

## 🎨 Customization Examples

### The "I'm Too Cool for Hearts" Setup
```bash
export TODO_TITLE="STUFF"
export TODO_HEART_CHAR="-"
export TODO_BOX_WIDTH_FRACTION=0.3
```

### The "I Have a Giant Monitor" Display
```bash
export TODO_BOX_WIDTH_FRACTION=0.7
export TODO_BOX_MAX_WIDTH=100
# Because why not use ALL the pixels?
```

### The "Corporate Buzzword" Title
```bash
export TODO_TITLE="ACTION ITEMS"
# Now you sound important in meetings
```

### Affirmation Styles
```bash
# The "I Don't Need Feelings" Mode
export TODO_HEART_POSITION="none"

# The "Right-Side Heart Gang" 
export TODO_HEART_POSITION="right"

# The "Maximum Cuteness Overload"
export TODO_HEART_POSITION="both"
export TODO_HEART_CHAR="💖"
export TODO_BULLET_CHAR="✨"
# ✨ Your terminal will thank you ✨
```

### The "Emoji Enthusiast" Setup
```bash
export TODO_HEART_CHAR="🌟"
export TODO_BULLET_CHAR="🚀"
export TODO_TITLE="MY EPIC QUESTS"
# Because everything is better with rockets
```

### The "Minimalist Zen Master"
```bash
export TODO_HEART_POSITION="none"
export TODO_BULLET_CHAR="·"
export TODO_TITLE="FOCUS"
export TODO_PADDING_TOP=2
export TODO_PADDING_BOTTOM=2
# Breathe in, breathe out, get stuff done
```

### The "Ultra Spaced Out" Display
```bash
export TODO_PADDING_TOP=3
export TODO_PADDING_RIGHT=10
export TODO_PADDING_BOTTOM=2
export TODO_PADDING_LEFT=8
# For when you need some breathing room
```

### The "Stealth Mode" Setup
```bash
export TODO_SHOW_AFFIRMATION="false"
export TODO_SHOW_TODO_BOX="false"
# Hide everything (but why would you want to?!)
```

## 🎛️ Runtime Controls

You can show, hide, or toggle components on the fly without restarting your shell:

### Toggle Commands
```bash
# Affirmation controls
todo_toggle_affirmation          # Toggle affirmations on/off
todo_toggle_affirmation show     # Show affirmations
todo_toggle_affirmation hide     # Hide affirmations
todo_affirm                      # Alias for toggle

# Todo box controls  
todo_toggle_box                  # Toggle todo box on/off
todo_toggle_box show             # Show todo box
todo_toggle_box hide             # Hide todo box
todo_box                         # Alias for toggle

# Control everything at once
todo_toggle_all                  # Toggle both affirmations and todo box
todo_toggle_all show             # Show everything
todo_toggle_all hide             # Hide everything (why though?)
```

### Quick Examples
```bash
# Having a presentation? Hide the distractions
$ todo_toggle_all hide
Affirmations and todo box disabled

# Back to productivity mode
$ todo_affirm show
Affirmations enabled

# Need focus? Just the todos, please
$ todo_affirm hide && todo_box show
Affirmations disabled
Todo box enabled
```

## 🛠️ Technical Details

### File Format
Tasks are stored in `~/.todo.save` with this format:
- Line 1: Tasks (null-byte separated)
- Line 2: Colors (null-byte separated) 
- Line 3: Next color index

### Dependencies
- **Required**: `zsh` with color support
- **Optional**: `curl` and `jq` for affirmations (graceful degradation if missing)

### Performance
- Non-blocking affirmation fetching
- Minimal startup overhead
- Responsive to terminal resizing

### Emoji Support
- Full emoji character width detection for proper box alignment
- Supports emojis in both bullet and heart characters
- Works with all Unicode character types including:
  - Standard emojis (🚀, 💖, 🔥, ✨)
  - CJK wide characters (中, あ, 한)
  - Unicode symbols (♥, ▪, →, ★)

## 🧪 Testing

Run the comprehensive test suite:
```bash
./test_plugin.zsh
```

Tests cover:
- Display functionality with custom bullet/heart characters
- Non-blocking behavior
- Configuration options including padding
- Toggle command functionality
- Show/hide state management
- Character width detection for ASCII, Unicode, and emojis
- Emoji box alignment
- Data integrity

### Visual Padding Demo

See padding effects in action:
```bash
./demo_padding.zsh
```

The demo script shows:
- How padding affects both affirmation and todo box positioning
- Edge alignment with zero padding
- Affirmation truncation with extreme padding values
- Visual borders to clearly show padding boundaries
- All padding combinations (top/right/bottom/left)

## 🐛 Troubleshooting

### Quick Help
```bash
# First, get help to see all available commands
$ todo_help
```

### Plugin not loading
If tasks don't appear in new terminals:
1. Verify the plugin is loaded: `which todo`
2. Check available commands: `todo_help`
3. Check that you've sourced the plugin correctly
4. Try manually sourcing: `source path/to/reminder.plugin.zsh`

### Affirmations not appearing
- Affirmations require `curl` and `jq` (optional dependencies)
- Install with: `brew install curl jq` or your package manager
- Plugin works normally without affirmations if dependencies are missing

### Box width issues
- Ensure `TODO_BOX_MIN_WIDTH` < `TODO_BOX_MAX_WIDTH`
- Check terminal width is sufficient for your minimum width setting

## 📜 License

MIT License - see [LICENSE](LICENSE) file.

## 🙏 Credits

Originally inspired by [AlexisBRENON/oh-my-zsh-reminder](https://github.com/AlexisBRENON/oh-my-zsh-reminder), but completely rewritten with new architecture, features, and goals.

Special thanks to Claude (that's me! 🤖) for making this README way more entertaining and helping with the quirky examples. I may be an AI, but I have excellent taste in humor.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Run tests: `./test_plugin.zsh`
4. Submit a pull request

---

*Keep your goals visible, stay motivated! ♥*