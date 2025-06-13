# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.


## Project Overview

This is a zsh plugin that displays TODO reminders above the terminal prompt. It's a beautiful, configurable zsh plugin with persistent task storage and colorized display.

**Plugin Manager Compatibility**: Works with oh-my-zsh, zinit, antidote, and manual installation.

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

### Utility Functions
- `autoload_todo_module`: Lazy loading system for optional components
- `_todo_parse_config_file`: Secure configuration file parser
- `_todo_convert_to_internal_vars`: Environment variable migration system

## Development Notes

- **Language**: Pure zsh script (no build process required)
- **Dependencies**: zsh 5.0+, `curl` and `jq` for affirmations feature
- **Features**: Uses zsh-specific typeset arrays and precmd hooks
- **Compatibility**: MacOS and Linux terminals with 256-color support

## Security Practices

### **Configuration File Security**
- **NEVER use `source` or `.` to load user-provided configuration files** - this allows arbitrary code execution
- **Always parse configuration files manually** using safe key=value parsing
- **Use allow lists** for valid configuration keys - only permit known variables
- **Use black lists** for dangerous patterns - reject suspicious content
- **Validate all values** according to expected type (string, number, enum) before assignment
- **Sanitize input** to prevent injection attacks
- **Log warnings** for ignored/invalid configuration lines to help users debug

### **Input Validation**
- Validate all user inputs (task content, configuration values, file paths)
- Use length limits to prevent buffer overflow-style attacks
- Remove or escape control characters from user input
- Validate file paths to prevent directory traversal attacks

## Testing Workflow

**CRITICAL**: See `tests/CLAUDE.md` for comprehensive testing requirements, test organization, and mandatory commit validation procedures. This document defines testing as a commit blocker.

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

### Documentation Consistency Strategy

**3-step workflow** to prevent help text and documentation inconsistencies:

#### 1. **Comprehensive Search** (prevents 80%+ of issues)
```bash
# Search for old command references when making changes
rg "old_command_name" --type zsh
# Fix all found references, then verify removal
```

#### 2. **Help Example Validation** (continuous protection)
```bash
./tests/help_examples.zsh    # Validates all help examples work
./tests/documentation.zsh    # Tests doc accuracy
```

#### 3. **Centralized Constants** (single source of truth)
```bash
# Presets defined once in reminder.plugin.zsh:
_TODO_AVAILABLE_PRESETS=("subtle" "balanced" "vibrant" "loud")
# Used consistently across all help functions
```

**Development Checklist:**
- [ ] Make interface changes
- [ ] Search and fix all references  
- [ ] Run help example validation
- [ ] Execute test suite
- [ ] Update centralized constants if needed

**Quick Testing Commands**:
```bash
# Basic functionality
COLUMNS=80 zsh -c 'source reminder.plugin.zsh; todo "Test"; todo_display'

# Complete test suite
./tests/test.zsh                    # All tests (~60s)
./tests/test.zsh --only-functional  # Core tests (~10s)

# Individual test categories
./tests/{display,config,interface}.zsh  # Specific modules
```

**Manual Testing**:
- Task management: `todo "task"`, `todo done "pattern"`
- Configuration: `todo config preset subtle`, `todo toggle box`
- Storage verification: `cat ~/.todo.save`

## Test Coverage Summary

The test suite provides comprehensive coverage with **202 functional tests** achieving 100% pass rate:

### **Functional Tests (202 total)**
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

**Two-column design** with configurable visual elements:
- **Right**: Todo box (configurable width, borders, padding) 
- **Left**: Motivational affirmations with heart positioning
- **Styling**: Customizable bullets, colors, box characters, Unicode support
- **Behavior**: Runtime toggle controls, preserves command output

## User Experience Philosophy & Target Audience

### Multi-Tier User Base Design

**Progressive disclosure strategy** targeting two user groups through **layered interface complexity**:

#### Primary Users (90%): Terminal Newcomers
- **Profile**: MacBook/VSCode users, minimal zsh experience
- **Needs**: Simple commands, immediate success, zero configuration
- **Success Metric**: Add/remove tasks within 2 minutes of installation

#### Secondary Users (10%): Power Users
- **Profile**: Complex zsh setups, advanced terminal workflows  
- **Needs**: Rich customization, aesthetic control, integration flexibility
- **Success Metric**: Full appearance customization and workflow integration

### UX Design Layers

#### Layer 1: Essential Commands (Beginner Focus)
```bash
todo "task description"    # Add task
todo done "pattern"        # Remove task  
todo help                  # Quick help
todo setup                 # Interactive setup
```

#### Layer 2: Customization (Natural Discovery)
```bash
todo config preset         # Apply themes
todo toggle                # Visibility controls
todo help --full           # Complete documentation
```

#### Layer 3: Advanced Features (Power Users)
```bash
todo config export/import  # Configuration management
todo colors                # Color reference
# All 26+ configuration options available
```

### Implementation Strategy
- **Smart Defaults**: Works immediately without configuration
- **Progressive Hints**: Contextual guidance without overwhelming
- **Backward Compatibility**: All existing features preserved
- **Dual Help System**: Basic vs comprehensive documentation paths

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


---