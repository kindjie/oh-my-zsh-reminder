# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a zsh plugin that displays TODO reminders above the terminal prompt. It's a beautiful, configurable zsh plugin with persistent task storage and colorized display.

## Architecture

- **Single File Plugin**: All functionality is contained in `reminder.plugin.zsh`
- **Persistent Storage**: Tasks and colors stored in single file `~/.todo.save`
- **Hook System**: Uses zsh's `precmd` hook to display tasks before each prompt
- **Color Management**: Cycles through configurable colors for task differentiation (default: red, green, yellow, blue, magenta, cyan)
- **Separate Border/Content Colors**: Independent foreground/background color control for borders vs content areas
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
- `todo_colors`: Interactive color reference showing 256-color codes for customization
- `format_affirmation`: Handles configurable heart positioning (left/right/both/none)
- `wrap_todo_text`: Text wrapping with emoji-aware width calculation
- `load_tasks`/`todo_save`: Handle persistent storage

## Development Notes

- This is a pure zsh script - no build process required
- The plugin uses zsh-specific features like typeset arrays and precmd hooks
- External dependency: `curl` and `jq` for affirmations feature

## Testing Workflow

**Test Data Safety**: All tests use temporary files via `TODO_SAVE_FILE` configuration to protect user data. Tests automatically isolate themselves in `$TMPDIR` and clean up on exit.

### Testing Conventions

**Test Structure**:
- Each test module is a standalone executable zsh script in `tests/`
- Tests use numbered functions with descriptive names: `test_feature_name()`
- Test output uses standardized format: `✅ PASS:` and `❌ FAIL:` for parsing
- Tests include both positive and negative validation cases
- Edge cases and boundary conditions are thoroughly tested

**Test Categories**:
- `display.zsh`: Display functionality, layout, text wrapping, emoji handling
- `configuration.zsh`: Padding, dimensions, show/hide states, box styling  
- `color.zsh`: Color validation, border/content colors, legacy compatibility
- `interface.zsh`: Commands, toggles, help system, user interactions
- `character.zsh`: Character width detection, Unicode/emoji support
- `performance.zsh`: Speed validation, async behavior, network resilience
- `ux.zsh`: User experience, onboarding, progressive disclosure (optional with --ux)
- `documentation.zsh`: Documentation accuracy, example validation (optional with --docs)

**Integration**:
- `test.zsh` orchestrates all test execution with summary reporting
- Individual tests can be run independently for focused development
- Performance tests separated with `--perf` flag due to longer execution time
- All tests designed to run in CI/automated environments

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

5. **Run complete functional test suite**:
   ```bash
   ./tests/test.zsh
   ```
   (Runs ALL tests by default: functional, performance, UX, documentation - ~60 seconds)

6. **Run only functional tests**:
   ```bash
   ./tests/test.zsh --only-functional
   ```
   (Runs only core functional tests - ~10 seconds)

7. **Run specific test categories**:
   ```bash
   ./tests/test.zsh --skip-perf        # Run all except performance tests
   ./tests/test.zsh --skip-docs --skip-ux  # Run only functional + performance
   ./tests/test.zsh --only-functional --meta  # Functional tests + Claude analysis
   ```

8. **Run individual test modules**:
   ```bash
   ./tests/display.zsh        # Display functionality and layout tests
   ./tests/configuration.zsh  # Padding, characters, and config tests
   ./tests/color.zsh          # Color configuration and validation tests
   ./tests/interface.zsh      # Commands, toggles, and help tests
   ./tests/character.zsh      # Character width and emoji handling tests
   ./tests/performance.zsh    # Performance and network behavior tests
   ./tests/ux.zsh             # User experience and onboarding tests
   ./tests/documentation.zsh  # Documentation accuracy and example validation
   ```

9. **Performance testing specifically**:
   ```bash
   ./tests/performance.zsh
   ```
   (16 performance tests validating display speed, network behavior, and async design)

10. **UX testing specifically**:
   ```bash
   ./tests/ux.zsh
   ```
   (18 UX tests validating onboarding, progressive disclosure, and usability)

11. **Documentation testing specifically**:
   ```bash
   ./tests/documentation.zsh
   ```
   (12 documentation tests validating accuracy and example functionality)

12. **Visual padding demonstration**:
   ```bash
   ./demo_padding.zsh
   ```
   (Shows all padding configurations with visual borders)

## Performance Test Coverage

The performance test suite validates the plugin's async design and ensures display performance remains optimal:

**Display Performance Tests:**
- Basic display speed (< 50ms threshold)
- Large task lists (50 items, < 100ms)
- Text wrapping with complex Unicode/emoji content
- Configuration overhead testing
- Memory usage monitoring (leak detection)

**Network & Async Behavior Tests:**
- Network timeout simulation (validates non-blocking design)
- Cache vs network performance comparison
- Missing dependencies graceful degradation (curl/jq)
- Network isolation and failure handling
- Background process cleanup verification
- Request throttling (prevents network storms)

**Key Validation Points:**
- Display always completes in <50ms regardless of network conditions
- Network operations never block the display pipeline
- Background affirmation fetching is properly async
- Cache reads are fast (<30ms)
- System works correctly without external dependencies

## Display Layout

- Right side: Todo box (configurable width, default 50%) with configurable borders
- Left side: Motivational affirmation with configurable heart positioning
- Configurable title (default: "REMEMBER") displays in bright color
- Regular tasks display with customizable bullet characters (default: ▪) and gray text
- Text wraps within box boundaries with proper emoji-aware indentation
- Dual-color system: bright bullets for visual emphasis, configurable text/border colors for readability
- Independent border and content background colors for visual distinction
- Configurable box drawing characters (corners, lines) for style customization
- Configurable padding on all sides (top/right/bottom/left)
- Runtime show/hide controls for all components
- Full emoji and Unicode support with proper terminal width calculation
- No screen clearing - preserves command output

## User Experience Philosophy & Target Audience

### Multi-Tier User Base Design

This plugin is designed to serve a diverse user base through **progressive disclosure** and **dual-track UX strategy**:

#### Primary Users (90%): Casual Developers & Terminal Newcomers
- **Profile**: MacBook users, VSCode terminal, minimal zsh experience beyond basic commands
- **Mental Model**: Coming from GUI todo apps, expect visual feedback and immediate gratification
- **Needs**: Simple installation, clear commands, works without configuration
- **Pain Points**: Intimidated by terminal configuration, fear of breaking things
- **Success Metrics**: Can add/remove tasks successfully within 2 minutes of installation

#### Secondary Users (10%): Advanced Terminal Power Users  
- **Profile**: Complex zsh setups, plugin managers, extensive terminal workflows
- **Mental Model**: Expect powerful configuration, performance, and integration
- **Needs**: Rich customization, aesthetic control, efficient muscle-memory commands
- **Pain Points**: Want full control without compromising functionality
- **Success Metrics**: Can customize appearance and integrate into existing workflow

### UX Design Principles

#### 1. **Layer 1: Essential Commands (Beginner Success)**
```bash
todo "task description"          # Add a task
todo_remove "partial match"      # Remove a task (clearer than task_done)
todo_hide                       # Hide everything
todo_show                       # Show everything
todo_help                       # Quick help (5-6 lines only)
```
- **Goal**: 90% of users should never need beyond Layer 1
- **Principle**: Immediate success with zero configuration

#### 2. **Layer 2: Customization (Natural Discovery)**
```bash
todo_setup                      # Interactive setup wizard
todo_colors                     # Show color options  
todo_toggle                     # Toggle visibility states
todo_help --more               # Full documentation
```
- **Goal**: Users naturally discover when ready for customization
- **Principle**: Progressive disclosure through contextual hints

#### 3. **Layer 3: Advanced (Power User Preservation)**
```bash
todo_config export              # Export settings
todo_config preset colorful     # Apply themes
# All current 30+ configuration variables preserved
```
- **Goal**: Preserve all existing power features
- **Principle**: Advanced features don't intimidate beginners

### Critical UX Issues to Address

#### 1. **Onboarding Experience (CRITICAL)**
- **Current Issue**: Plugin loads silently with no guidance
- **Solution**: First-run welcome message with clear next steps
- **Success Feedback**: Immediate confirmation when tasks are added/removed

#### 2. **Command Discovery (HIGH)**
- **Current Issue**: Essential features buried in complex help output  
- **Solution**: Simplified `todo_help` showing only 5-6 essential commands
- **Tab Completion**: Currently broken (commented out) - must be fixed

#### 3. **Command Naming Clarity (HIGH)**
- **Current Issue**: `task_done` implies completion, actually means deletion
- **Solution**: Rename to `todo_remove` or provide clearer aliases
- **Consistency**: Ensure all main commands follow `todo_*` pattern

#### 4. **Progressive Hints (MEDIUM)**
- **Empty State**: Show helpful message when no tasks exist
- **Growth Guidance**: Suggest customization after several tasks added
- **Error Recovery**: Clear guidance when things go wrong

### Implementation Guidelines

#### Preserve Power, Add Approachability
- **Never remove** existing advanced features
- **Add** beginner-friendly entry points
- **Maintain** backward compatibility for existing users

#### Dual-Track Help System
- `todo_help` → Essential commands only (beginner focus)
- `todo_help --more` → Current comprehensive documentation
- `todo_help <topic>` → Contextual help for specific areas

#### Smart Defaults Strategy
- **Works immediately** after installation with no configuration
- **Gentle introduction** to advanced features through contextual hints
- **Fallback gracefully** when dependencies (curl/jq) missing

#### First-Run Experience Design
```bash
# After sourcing plugin for first time
┌─ Welcome to Todo Reminder! ─────────────────────────┐
│ ✨ Get started: todo "Your first task"              │
│ 📚 Quick help: todo_help                           │
│ ⚙️  Customize: todo_setup                          │
└─────────────────────────────────────────────────────┘
```

This approach **expands the user base** to include terminal newcomers while **preserving all existing functionality** for power users. The key insight is that advanced users will naturally discover deeper features, while beginners need immediate success with simple commands.