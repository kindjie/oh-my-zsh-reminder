# zsh-todo-reminder

A beautiful, configurable zsh plugin that displays your TODO tasks in a right-aligned box with motivational affirmations above every terminal prompt.

```
                                                      ┌────────────────────────────┐
                                                      │ REMEMBER                   │
♥ You make a difference in the world by simply        │ ▪ Shell -> <C-s> <C-e> and │
  existing in it                                      │   <A-b> <A-f>              │
                                                      │ ▪ Elixir2 ratings investi- │
                                                      │   gation (low priority)    │
                                                      │ ▪ Refactor chessgpt-server │
                                                      │   static chess evals       │
                                                      └────────────────────────────┘
~/projects/awesome-app main*
❯ git status
# ... git output ...

                                                      ┌────────────────────────────┐
                                                      │ REMEMBER                   │
♥ You make a difference in the world by simply        │ ▪ Shell -> <C-s> <C-e> and │
  existing in it                                      │   <A-b> <A-f>              │
                                                      │ ▪ Elixir2 ratings investi- │
                                                      │   gation (low priority)    │
                                                      │ ▪ Refactor chessgpt-server │
                                                      │   static chess evals       │
                                                      └────────────────────────────┘
~/projects/awesome-app main*
❯ _
```

![Basic Display](docs/images/basic-display.png)

## 📸 Screenshots

### Default Display

![Basic Display](docs/images/basic-display.png)
_Clean todo box with motivational affirmations_

### Customization Options

![Customization Themes](docs/images/customization-themes.png)
_Different themes showing title, bullet, and styling flexibility_

### Runtime Controls

![Toggle Controls](docs/images/toggle-controls.png)
_Show/hide components on-the-fly without restart_

## ✨ Features

- **🎨 Beautiful Display**: Right-aligned todo box with Unicode borders that appears above every prompt
- **💝 Motivational Affirmations**: Fetches daily affirmations to keep you motivated
- **📜 Persistent Reminders**: Tasks stay visible in your terminal history as you work
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

### Example Terminal Session

```bash
~/projects main
❯ todo "Fix authentication bug"
Task added: Fix authentication bug

                                                      ┌────────────────────────────┐
                                                      │ REMEMBER                   │
♥ You are stronger than you think                     │ ▪ Fix authentication bug   │
                                                      └────────────────────────────┘
~/projects main
❯ cd awesome-app

                                                      ┌────────────────────────────┐
                                                      │ REMEMBER                   │
♥ You are stronger than you think                     │ ▪ Fix authentication bug   │
                                                      └────────────────────────────┘
~/projects/awesome-app main
❯ npm test
# ... test output ...

                                                      ┌────────────────────────────┐
                                                      │ REMEMBER                   │
♥ You are stronger than you think                     │ ▪ Fix authentication bug   │
                                                      └────────────────────────────┘
~/projects/awesome-app main
❯ task_done "Fix auth"
Task removed: Fix authentication bug

~/projects/awesome-app main
❯
```

Notice how your todos appear before every prompt, keeping them visible as you work! When all tasks are completed, the todo box disappears for a clean terminal experience.

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

# Color configuration (256-color terminal codes)
export TODO_TASK_COLORS="196,46,33,21,129,201"  # Task bullet colors (default: "167,71,136,110,139,73")
export TODO_BORDER_COLOR=244                 # Box border color (default: 240)
export TODO_BACKGROUND_COLOR=233             # Box background color (default: 235)
export TODO_TEXT_COLOR=245                   # Task text color (default: 240)
export TODO_TITLE_COLOR=255                  # Box title color (default: 250)
export TODO_AFFIRMATION_COLOR=33             # Affirmation text color (default: 109)

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

### The "Custom Color Scheme" Setup

```bash
export TODO_TASK_COLORS="196,46,33,21,129,201"  # Bright and vibrant task colors
export TODO_BORDER_COLOR=244                     # Lighter border
export TODO_BACKGROUND_COLOR=233                 # Darker background
export TODO_TITLE_COLOR=255                      # Bright white title
export TODO_AFFIRMATION_COLOR=33                 # Blue affirmations
# Make it uniquely yours
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

### Display Behavior

- **Empty todo list**: When all tasks are completed, the todo box disappears completely for a clean terminal
- **Long affirmations**: Automatically truncated with "..." when they exceed available space
  - Truncation accounts for heart position configuration
  - Ensures clean display even in narrow terminals
- **Text wrapping**: Long todo items wrap within the box boundaries
- **Responsive layout**: Box width adjusts based on terminal size and configuration

## 🧪 Testing

### Quick Functional Tests

Run the comprehensive functional test suite:

```bash
./tests/run_all.zsh
```

### Complete Test Suite (with Performance)

Run all tests including performance validation:

```bash
./tests/run_all.zsh --perf
```

### Individual Test Modules

Run specific test categories:

```bash
./tests/run_all.zsh display.zsh configuration.zsh  # Specific tests
./tests/performance.zsh                            # Performance only
```

### Test Coverage

**Functional Tests (100+ tests):**

- Display functionality with custom bullet/heart characters
- Configuration options including padding, colors, and dimensions
- Toggle command functionality and show/hide state management
- Character width detection for ASCII, Unicode, and emojis
- Interface commands, help system, and error handling
- Color validation and interactive color reference

**Performance Tests (16 tests):**

- Display performance under various conditions (< 50ms)
- Network timeout behavior (ensures non-blocking async design)
- Cache vs network performance validation
- Missing dependencies graceful degradation
- Memory usage monitoring and leak detection
- Background process cleanup verification

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

## 🔧 How It Works

The plugin uses zsh's `precmd` hook to display your todos before each prompt:

1. **precmd hook**: Runs `todo_display` before every prompt is drawn
2. **Display pipeline**: Fetches tasks → formats box → prints above prompt
3. **Persistent visibility**: Each display becomes part of your terminal history
4. **Non-blocking design**: Affirmations fetch asynchronously in background
5. **Smart rendering**: Calculates terminal width and wraps text accordingly

This means:

- Your todos appear automatically - no manual commands needed
- They stay visible in scrollback as you work through commands
- New terminals immediately show existing tasks from `~/.todo.save`
- Performance is optimized to never slow down your prompt

## 📜 License

MIT License - see [LICENSE](LICENSE) file.

## 💭 Motivation

This project started as an experiment in "vibe coding" - letting an AI agent handle the implementation while I focused on the vision. As someone who works with LLMs professionally, I was skeptical about their capabilities for real development work. But I needed a simple terminal todo list, and this seemed like the perfect low-stakes testing ground.

I purposely chose to build on an existing plugin rather than start from scratch, to test how well AI could understand and extend established code. What began as right-aligned text became something unexpectedly polished through countless iterations of guidance and refinement.

### Observations from the Process

- **Testing was critical**: Progress was nearly impossible without comprehensive automated tests. Setting up an environment that accurately reflected rendered terminal output took several attempts.
- **Context management matters**: With limited context windows, I had to encourage documentation and strategically break up tasks to use `/clear` instead of `/compact`. The project consumed hundreds of thousands of tokens - I consistently hit Pro limits and needed to upgrade.
- **Not everything worked**: Some features had to be abandoned after thousands of tokens of failed attempts, like a transient display mode that would only show above the current prompt. The AI struggled to reason about interactions with other zsh plugins like P10k.
- **Surprisingly engaging**: The process was far more fun than solo coding - whether due to novelty or something inherent to collaborative AI development remains to be seen.
- **Interesting side effects**: The motivational affirmations in test outputs seemed to subtly influence the AI's personality as contexts grew larger.

Whether this demonstrates AI as a capable development partner is for you to decide - I'd love to hear your thoughts via GitHub issues!

## 🙏 Credits

Originally inspired by [AlexisBRENON/oh-my-zsh-reminder](https://github.com/AlexisBRENON/oh-my-zsh-reminder), but completely rewritten with new architecture, features, and goals.

Special thanks to Claude (that's me! 🤖) for making this README way more entertaining and helping with the quirky examples. I may be an AI, but I have excellent taste in humor.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Run tests: `./tests/run_all.zsh --perf` (or `./tests/run_all.zsh` for faster functional tests)
4. Submit a pull request

### Development Testing

- **Quick validation:** `./tests/run_all.zsh` (~10s)
- **Comprehensive testing:** `./tests/run_all.zsh --perf` (~60s)
- **Performance testing:** `./tests/performance.zsh` (network, async, timing)
- **Visual testing:** `./demo_padding.zsh` (padding demonstration)

---

_Keep your goals visible, stay motivated! ♥_

