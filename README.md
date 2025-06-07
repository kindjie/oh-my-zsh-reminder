# oh-my-zsh-reminder

A beautiful, configurable zsh plugin that displays your TODO tasks in a right-aligned box with motivational affirmations.

![Plugin Screenshot](screenshot.png)

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
kindjie/oh-my-zsh-reminder kind:defer
```

**With Oh My Zsh:**
```bash
git clone https://github.com/kindjie/oh-my-zsh-reminder ~/.oh-my-zsh/custom/plugins/reminder
# Add 'reminder' to your plugins list in ~/.zshrc
```

**Manual Installation:**
```bash
git clone https://github.com/kindjie/oh-my-zsh-reminder
# Source the plugin in your .zshrc:
source /path/to/oh-my-zsh-reminder/reminder.plugin.zsh
```

### Basic Usage

```bash
# Add a task
$ todo "Finish the quarterly report"
$ todo "Call dentist for appointment"

# Remove a completed task (with tab completion)
$ task_done "Finish"

# Tasks display automatically before each prompt
```

## 📖 Usage

### Adding Tasks
```bash
todo "Your task description"
todo "Another important task"
```

### Completing Tasks
```bash
# Remove by partial match (tab completion available)
task_done "partial task text"

# Example: removes "Finish the quarterly report"
task_done "Finish"
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

# Affirmation styling
export TODO_HEART_CHAR="*"                   # Heart character (default: "♥")
export TODO_HEART_POSITION="both"            # "left", "right", "both", "none" (default: "left")

# File locations
export TODO_SAVE_FILE="$HOME/.my_todos"      # Save location (default: ~/.todo.sav)
export TODO_AFFIRMATION_FILE="/tmp/affirm"   # Affirmation cache (default: /tmp/todo_affirmation)
```

## 🎨 Customization Examples

### Minimalist Setup
```bash
export TODO_TITLE="TODO"
export TODO_HEART_CHAR="-"
export TODO_BOX_WIDTH_FRACTION=0.3
```

### Wide Display
```bash
export TODO_BOX_WIDTH_FRACTION=0.7
export TODO_BOX_MAX_WIDTH=100
```

### Custom Title
```bash
export TODO_TITLE="PRIORITIES"
```

### Affirmation Styles
```bash
# Clean, minimal (no hearts)
export TODO_HEART_POSITION="none"

# Heart on the right side
export TODO_HEART_POSITION="right"

# Hearts on both sides (decorative)
export TODO_HEART_POSITION="both"
```

## 🛠️ Technical Details

### File Format
Tasks are stored in `~/.todo.sav` with this format:
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

## 🧪 Testing

Run the comprehensive test suite:
```bash
./test_plugin.zsh
```

Tests cover:
- Display functionality
- Non-blocking behavior
- Configuration options
- Data integrity

## 🐛 Troubleshooting

### Plugin not loading
If tasks don't appear in new terminals:
1. Verify the plugin is loaded: `which todo`
2. Check that you've sourced the plugin correctly
3. Try manually sourcing: `source path/to/reminder.plugin.zsh`

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

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Run tests: `./test_plugin.zsh`
4. Submit a pull request

---

*Keep your goals visible, stay motivated! ♥*