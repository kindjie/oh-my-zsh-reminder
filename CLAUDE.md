# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.


## Project Overview

This is a zsh plugin that displays TODO reminders above the terminal prompt. It's a beautiful, configurable zsh plugin with persistent task storage and colorized display.

## Architecture

- **Pure Subcommand Interface**: All functionality accessible through `todo <subcommand>` pattern for consistency
- **Single File Plugin**: Core functionality in `reminder.plugin.zsh` with modular components in `lib/`
- **Persistent Storage**: Tasks and colors stored in single file `~/.todo.save`
- **Hook System**: Uses zsh's `precmd` hook to display tasks before each prompt
- **Color Management**: Cycles through configurable colors for task differentiation (default: red, green, yellow, blue, magenta, cyan)
- **Separate Border/Content Colors**: Independent foreground/background color control for borders vs content areas
- **Emoji Support**: Full Unicode character width detection for proper alignment with emojis
- **Configurable Display**: Customizable bullet/heart characters, padding, show/hide states, and box dimensions
- **Runtime Controls**: Toggle commands for showing/hiding components without restart
- **Progressive Disclosure**: Layered help system (basic → full → specialized) for different user skill levels

## Key Functions

### Primary Interface
- `todo` (dispatcher): Main entry point - routes all subcommands
- `todo_dispatcher`: Core routing function for pure subcommand interface
- `todo <task>`: Adds new tasks
- `todo done <pattern>`: Removes completed tasks with tab completion
- `todo help`: Shows essential commands (Layer 1 UX)
- `todo help --full`: Shows complete documentation (Layer 2 UX)
- `todo setup`: Interactive configuration wizard for beginners

### Subcommand Dispatchers
- `todo_config_dispatcher`: Routes `todo config` commands (export, import, preset, etc.)
- `todo_toggle_dispatcher`: Routes `todo toggle` commands (box, affirmation, all)

### Core Display & Logic
- `todo_display`: Shows tasks before each prompt with right-aligned formatting
- `fetch_affirmation_async`: Fetches and displays motivational affirmations asynchronously
- `format_affirmation`: Handles configurable heart positioning (left/right/both/none)
- `wrap_todo_text`: Text wrapping with emoji-aware width calculation
- `load_tasks`/`todo_save`: Handle persistent storage

### Advanced Features
- `todo_config_*`: Configuration management (export, import, presets)
- `todo_colors`: Interactive color reference showing 256-color codes
- `show_welcome_message`: First-run onboarding experience

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

**Test Data Setup**:
- Tests requiring task data should create temporary save files with proper task format
- Use `printf` with null separators (`\000`) to create test data: `printf 'Task 1\000Task 2\000Task 3\n\e[38;5;167m\000\e[38;5;71m\000\e[38;5;136m\n4\n' > "$temp_save"`
- Set `TODO_SAVE_FILE="$temp_save"` environment variable to point to test data
- Let `load_tasks` function read from the test file naturally (don't manually override task arrays)
- This approach ensures tests use the same data flow as real user scenarios

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

## Development Workflow - Documentation Consistency

### The Pragmatic Combo (High ROI Prevention Strategy)

To prevent help text and documentation inconsistencies, follow this **3-step workflow** whenever making interface changes:

#### 1. **Always Do: Comprehensive Search** (5 minutes, prevents 80%+ of issues)

Before completing any command interface changes:

```bash
# Check for specific old command references
./dev-tools/check-command-references.sh old_command_name

# Run comprehensive check for common issues  
./dev-tools/check-command-references.sh

# Example workflow when replacing 'task_done' with 'todo done':
./dev-tools/check-command-references.sh task_done
# Fix all found references, then verify:
./dev-tools/check-command-references.sh task_done  # Should show "No references found"
```

**Why this works:** Catches interface inconsistencies immediately, uses existing tools, scales to any codebase size.

#### 2. **Do Once: Help Example Validation** (30 minutes setup, permanent protection)

Validate that all help examples actually work:

```bash
# Test that help examples are executable and produce expected outputs
./tests/help_examples.zsh

# Add to main test suite for continuous protection
./tests/test.zsh  # (includes help_examples.zsh automatically)
```

This test suite:
- Extracts command examples from help output
- Validates they execute without errors
- Checks for expected output patterns (success messages, help sections)
- Detects obsolete command references in help text

#### 3. **Do Eventually: Single Source of Truth** (centralized configuration)

Presets, command lists, and repeated content now use centralized constants:

```bash
# Available presets defined once in reminder.plugin.zsh:
_TODO_AVAILABLE_PRESETS=("subtle" "balanced" "vibrant" "loud")
_TODO_PRESET_LIST="${(j:, :)_TODO_AVAILABLE_PRESETS}"

# Used consistently in all help functions:
echo "Available presets: ${_TODO_PRESET_LIST}"
```

**Future additions:** Define command lists, color options, and other repeated content centrally.

### Development Checklist

When making interface changes:

- [ ] **Make the change** (modify commands, functions, interfaces)
- [ ] **Run comprehensive search** (`./dev-tools/check-command-references.sh`)
- [ ] **Fix all found references** (help text, examples, documentation)  
- [ ] **Validate help examples** (`./tests/help_examples.zsh`)
- [ ] **Run test suite** (`./tests/test.zsh --only-functional`)
- [ ] **Update centralized constants** (if adding new presets/commands)

### Error Prevention Classes

This workflow prevents:

1. **Interface Evolution Inconsistency** - Old command names in help text
2. **Incomplete Updates** - Missing references during refactoring  
3. **Data Synchronization Issues** - Different preset lists across functions
4. **Test-Implementation Drift** - Tests expecting old behavior
5. **Documentation Inconsistency** - Conflicting information between help commands

**Success Metric:** Zero broken examples in help output, consistent command syntax throughout all user-facing text.

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
   - Remove tasks: `todo done "partial match"`
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
   ./tests/display.zsh              # Display functionality and layout tests
   ./tests/configuration.zsh        # Padding, characters, and config tests
   ./tests/config_management.zsh    # Configuration export/import/presets
   ./tests/color.zsh                # Color configuration and validation tests
   ./tests/interface.zsh            # Commands, toggles, and help tests
   ./tests/subcommand_interface.zsh # Pure subcommand interface testing
   ./tests/character.zsh            # Character width and emoji handling tests
   ./tests/wizard_noninteractive.zsh # Setup wizard functionality
   ./tests/performance.zsh          # Performance and network behavior tests
   ./tests/ux.zsh                   # User experience and onboarding tests
   ./tests/user_workflows.zsh       # End-to-end user workflow scenarios
   ./tests/documentation.zsh        # Documentation accuracy and example validation
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

## Test Coverage Summary

The test suite provides comprehensive coverage with **164 functional tests** achieving 100% pass rate:

### **Functional Tests (164 total)**
- **Display Tests (7)**: Basic rendering, layout, text wrapping
- **Configuration Tests (14)**: Padding, dimensions, character settings  
- **Config Management Tests (20)**: Export/import, presets, wizard functionality
- **Color Tests (31)**: Validation, 256-color support, legacy compatibility
- **Interface Tests (46)**: Commands, help system, error handling  
- **Subcommand Interface Tests (14)**: Pure subcommand routing and completion
- **Character Tests (16)**: Unicode/emoji width detection and alignment
- **Wizard Tests (11)**: Non-interactive setup wizard validation
- **User Workflows (5)**: End-to-end scenario testing

### **Extended Test Suites**
- **Performance Tests (16)**: Network behavior, display speed, async operations
- **UX Tests (18)**: Onboarding, progressive disclosure, usability  
- **Documentation Tests (12)**: Accuracy validation, example verification

### **Enhanced Test Runner Features**
- Compact progress indicators: `[1/8] display.zsh ... ✅ 7 passed`
- Smart failure reporting with context  
- Verbose debugging mode preserved
- Fast functional-only mode (~10s) vs comprehensive mode (~60s)

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
todo_config preset vibrant      # Apply themes
# All current 30+ configuration variables preserved
```
- **Goal**: Preserve all existing power features
- **Principle**: Advanced features don't intimidate beginners

### Critical UX Issues to Address

#### 1. **Onboarding Experience (CRITICAL)**
- **Current Issue**: Plugin loads silently with no guidance
- **Solution**: First-run welcome message with clear next steps
- **Success Feedback**: Immediate confirmation when tasks are added/removed

#### 2. **Command Discovery (COMPLETED ✅)**
- **Resolved**: Simplified help system with essential commands
- **Resolved**: Tab completion fully functional for all commands
- **Resolved**: Pure subcommand interface for consistency

#### 3. **Command Naming Clarity (COMPLETED ✅)**
- **Resolved**: All commands follow consistent `todo <subcommand>` pattern
- **Resolved**: Clear command naming throughout interface

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

---

# Semantic Preset System - COMPLETED ✅

## Summary
Successfully replaced 9 theme-based presets with 4 semantic intensity presets that provide better user experience and reduced maintenance:

**Before**: `minimal`, `colorful`, `work`, `dark`, `monokai`, `solarized-dark`, `nord`, `gruvbox-dark`, `base16-auto`
**After**: `subtle`, `balanced`, `vibrant`, `loud`

## Completed Changes

### ✅ Code Simplification
- Removed `/presets/extended/` directory (4 .conf files)
- Deleted `_todo_load_preset_file()` and `_hex_to_256()` functions  
- Simplified `todo_config_preset()` with semantic mapping
- Reduced main script from ~2200 to 2138 lines

### ✅ Test Suite Updates
- Updated 26 test functions across 4 files
- All tests passing consistently (100% success rate)
- Added semantic preset validation logic
- Maintained comprehensive test coverage (166 functional tests)

### ✅ Documentation Updates
- Updated README.md with semantic preset examples
- Added tinty integration guidance
- Updated help text with preset descriptions and tinty tips
- Centralized preset constants for consistency

### ✅ User Experience Improvements
- Clear semantic naming (`subtle` vs obscure theme names)
- Tinty integration messaging for advanced users
- Maintained export/import functionality
- Backward compatibility preserved

## Success Metrics Achieved
- **Reduced maintenance**: 9 presets → 4 presets (55% reduction)
- **Code quality**: Eliminated external .conf files
- **User clarity**: Semantic intensity levels vs theme-specific names
- **Theme integration**: Clear path to 200+ themes via tinty
- **Test reliability**: 100% pass rate across 3 consecutive runs

---