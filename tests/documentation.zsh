#!/usr/bin/env zsh

# Documentation Testing Suite for Todo Reminder Plugin
# Tests that documentation accurately represents the implementation

# Initialize test environment
script_dir="${0:A:h}"
source "$script_dir/test_utils.zsh"

# Color definitions for output
autoload -U colors
colors

echo "📚 Testing Documentation Accuracy"
echo "═════════════════════════════════"
echo

# Test counter
test_count=0
passed_count=0
failed_count=0

echo "This test suite validates:"
echo "  • README examples match actual behavior"
echo "  • CLAUDE.md technical details are accurate"
echo "  • Help output matches documented features"
echo "  • Configuration variables exist and work"
echo "  • Command examples produce expected results"
echo

# ===== 1. README ACCURACY TESTS =====

echo "${fg[blue]}1. Testing README Example Accuracy${reset_color}"
echo "─────────────────────────────────────────"

# Test basic usage examples from README
function test_readme_basic_usage() {
    local test_name="README basic usage examples work"
    ((test_count++))
    
    local temp_save="$TMPDIR/test_readme_$$"
    local failed_examples=()
    
    # Test: todo "Buy groceries"
    local output1=$(COLUMNS=80 TODO_SAVE_FILE="$temp_save" zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        eval "todo \"Buy groceries\""
    ')
    
    if [[ "$output1" != *"✅ Task added"* ]]; then
        failed_examples+=("todo \"Buy groceries\"")
    fi
    
    # Test: task_done "Buy"
    local output2=$(COLUMNS=80 TODO_SAVE_FILE="$temp_save" zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        eval "task_done \"Buy\""
    ')
    
    if [[ "$output2" != *"✅ Task completed"* ]]; then
        failed_examples+=("task_done \"Buy\"")
    fi
    
    # Test: todo_help
    local output3=$(COLUMNS=80 zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        todo_help
    ')
    
    if [[ "$output3" != *"Essential Commands"* ]]; then
        failed_examples+=("todo_help")
    fi
    
    if [[ ${#failed_examples[@]} -eq 0 ]]; then
        echo "✅ PASS: $test_name"
        echo "  All README examples work as documented"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Failed examples: ${failed_examples[*]}"
        ((failed_count++))
    fi
    
    # Cleanup
    [[ -f "$temp_save" ]] && rm -f "$temp_save"
}

# Test configuration examples from README
function test_readme_config_examples() {
    local test_name="README configuration examples are valid"
    ((test_count++))
    
    local failed_configs=()
    
    # Test configuration variables mentioned in README
    local config_vars=(
        "TODO_TITLE"
        "TODO_BOX_WIDTH_FRACTION" 
        "TODO_HEART_CHAR"
        "TODO_BULLET_CHAR"
        "TODO_TASK_COLORS"
        "TODO_BORDER_COLOR"
        "TODO_SHOW_AFFIRMATION"
        "TODO_PADDING_LEFT"
    )
    
    for config_var in "${config_vars[@]}"; do
        # Test that variable is actually used in the implementation
        if ! grep -q "$config_var" reminder.plugin.zsh; then
            failed_configs+=("$config_var")
        fi
    done
    
    # Test specific README examples work
    local test_output=$(COLUMNS=80 TODO_TITLE="TASKS" TODO_HEART_CHAR="💖" zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        TODO_SAVE_FILE="/tmp/test_config_$$";
        todo_add_task "Test config" >/dev/null;
        todo_display 2>/dev/null | grep -E "(TASKS|💖)" | wc -l
    ')
    
    if [[ "$test_output" -lt 1 ]]; then
        failed_configs+=("Configuration variables not affecting output")
    fi
    
    if [[ ${#failed_configs[@]} -eq 0 ]]; then
        echo "✅ PASS: $test_name"
        echo "  All README configuration examples are valid"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Invalid configs: ${failed_configs[*]}"
        ((failed_count++))
    fi
}

# Test README command aliases
function test_readme_aliases() {
    local test_name="README mentions correct aliases"
    ((test_count++))
    
    # Check if README mentions aliases that actually exist
    local readme_content=""
    if [[ -f "README.md" ]]; then
        readme_content=$(cat README.md)
    else
        echo "❌ FAIL: $test_name"
        echo "  README.md not found"
        ((failed_count++))
        return
    fi
    
    # Get actual aliases from implementation
    local actual_aliases=$(zsh -c 'source reminder.plugin.zsh; alias | grep todo')
    
    # Check key aliases mentioned in README exist
    local documented_aliases=("todo" "task_done")
    local missing_aliases=()
    
    for alias_name in "${documented_aliases[@]}"; do
        if [[ "$actual_aliases" != *"$alias_name="* ]]; then
            missing_aliases+=("$alias_name")
        fi
    done
    
    if [[ ${#missing_aliases[@]} -eq 0 ]]; then
        echo "✅ PASS: $test_name"
        echo "  All documented aliases exist in implementation"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Missing aliases: ${missing_aliases[*]}"
        ((failed_count++))
    fi
}

test_readme_basic_usage
test_readme_config_examples
test_readme_aliases

# ===== 2. CLAUDE.MD TECHNICAL ACCURACY =====

echo
echo "${fg[blue]}2. Testing CLAUDE.md Technical Accuracy${reset_color}"
echo "──────────────────────────────────────────────"

# Test key functions mentioned in CLAUDE.md
function test_claude_md_functions() {
    local test_name="CLAUDE.md documented functions exist"
    ((test_count++))
    
    local claude_md_content=""
    if [[ -f "CLAUDE.md" ]]; then
        claude_md_content=$(cat CLAUDE.md)
    else
        echo "❌ FAIL: $test_name"
        echo "  CLAUDE.md not found"
        ((failed_count++))
        return
    fi
    
    # Extract function names mentioned in CLAUDE.md
    local documented_functions=(
        "todo_add_task"
        "todo_task_done" 
        "todo_display"
        "fetch_affirmation_async"
        "todo_toggle_affirmation"
        "todo_help"
        "todo_colors"
        "load_tasks"
        "todo_save"
    )
    
    local missing_functions=()
    
    for func_name in "${documented_functions[@]}"; do
        # Check main plugin file and wizard module for functions
        if ! grep -q "^function $func_name\|^$func_name()" reminder.plugin.zsh && \
           ! grep -q "^function $func_name\|^$func_name()" lib/wizard.zsh 2>/dev/null; then
            missing_functions+=("$func_name")
        fi
    done
    
    if [[ ${#missing_functions[@]} -eq 0 ]]; then
        echo "✅ PASS: $test_name"
        echo "  All documented functions exist in implementation"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Missing functions: ${missing_functions[*]}"
        ((failed_count++))
    fi
}

# Test architecture claims in CLAUDE.md
function test_claude_md_architecture() {
    local test_name="CLAUDE.md architecture claims are accurate"
    ((test_count++))
    
    local failed_claims=()
    
    # Test: "Single File Plugin" - now modular but primarily single file
    if [[ ! -f "reminder.plugin.zsh" ]]; then
        failed_claims+=("Main plugin file missing")
    fi
    
    # Test: Modular structure for optional components
    if [[ ! -d "lib" ]] || [[ ! -f "lib/wizard.zsh" ]]; then
        failed_claims+=("Modular structure claim - lib directory or wizard module missing")
    fi
    
    # Test: "Persistent Storage: Tasks and colors stored in single file ~/.todo.save"
    local save_file_usage=$(grep -c "TODO_SAVE_FILE" reminder.plugin.zsh)
    if [[ $save_file_usage -lt 3 ]]; then
        failed_claims+=("Persistent storage claim - insufficient save file usage")
    fi
    
    # Test: "Hook System: Uses zsh's precmd hook"
    if ! grep -q "add-zsh-hook precmd" reminder.plugin.zsh; then
        failed_claims+=("Hook system claim - precmd hook not found")
    fi
    
    # Test: "Color Management: Cycles through configurable colors"
    if ! grep -q "TODO_COLORS\|todo_color_index" reminder.plugin.zsh; then
        failed_claims+=("Color management claim - color cycling not found")
    fi
    
    # Test: "Emoji Support: Unicode character width detection with zsh native features"
    if ! grep -q '${(m)#' reminder.plugin.zsh; then
        failed_claims+=("Emoji support claim - zsh native width detection missing")
    fi
    
    if [[ ${#failed_claims[@]} -eq 0 ]]; then
        echo "✅ PASS: $test_name"
        echo "  All architecture claims verified in implementation"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Failed claims: ${failed_claims[*]}"
        ((failed_count++))
    fi
}

# Test testing instructions in CLAUDE.md
function test_claude_md_testing_instructions() {
    local test_name="CLAUDE.md testing instructions work"
    ((test_count++))
    
    local failed_instructions=()
    
    # Test: Basic functionality test command
    local basic_test_output=$(COLUMNS=80 zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh; todo_display' 2>&1)
    if [[ "$basic_test_output" == *"error"* ]]; then
        failed_instructions+=("Basic functionality test")
    fi
    
    # Test: test.zsh exists and is executable
    if [[ ! -x "tests/test.zsh" ]]; then
        failed_instructions+=("test.zsh not executable")
    fi
    
    # Test: Individual test files exist
    local test_files=("display.zsh" "color.zsh" "interface.zsh" "character.zsh" "ux.zsh")
    for test_file in "${test_files[@]}"; do
        if [[ ! -f "tests/$test_file" ]]; then
            failed_instructions+=("tests/$test_file missing")
        fi
    done
    
    if [[ ${#failed_instructions[@]} -eq 0 ]]; then
        echo "✅ PASS: $test_name"
        echo "  All testing instructions are accurate"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Failed instructions: ${failed_instructions[*]}"
        ((failed_count++))
    fi
}

test_claude_md_functions
test_claude_md_architecture
test_claude_md_testing_instructions

# ===== 3. HELP OUTPUT ACCURACY =====

echo
echo "${fg[blue]}3. Testing Help Output Matches Documentation${reset_color}"
echo "────────────────────────────────────────────────────"

# Test help output contains all documented commands
function test_help_command_coverage() {
    local test_name="Help output covers all documented commands"
    ((test_count++))
    
    local help_output=$(zsh -c 'source reminder.plugin.zsh; todo_help')
    local full_help_output=$(zsh -c 'source reminder.plugin.zsh; todo_help --more')
    
    # Commands that should be in basic help
    local basic_commands=("todo" "todo_remove" "todo_hide" "todo_show" "todo_setup")
    local missing_basic=()
    
    for cmd in "${basic_commands[@]}"; do
        if [[ "$help_output" != *"$cmd"* ]]; then
            missing_basic+=("$cmd")
        fi
    done
    
    # Commands that should be in full help
    local advanced_commands=("todo_config" "export" "import" "preset")
    local missing_advanced=()
    
    for cmd in "${advanced_commands[@]}"; do
        if [[ "$full_help_output" != *"$cmd"* ]]; then
            missing_advanced+=("$cmd")
        fi
    done
    
    # Special check: wizard should be mentioned in basic help (as "customization wizard")
    if [[ "$help_output" != *"wizard"* ]]; then
        missing_basic+=("wizard (in basic help)")
    fi
    
    if [[ ${#missing_basic[@]} -eq 0 && ${#missing_advanced[@]} -eq 0 ]]; then
        echo "✅ PASS: $test_name"
        echo "  All documented commands appear in appropriate help sections"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        if [[ ${#missing_basic[@]} -gt 0 ]]; then
            echo "  Missing from basic help: ${missing_basic[*]}"
        fi
        if [[ ${#missing_advanced[@]} -gt 0 ]]; then
            echo "  Missing from advanced help: ${missing_advanced[*]}"
        fi
        ((failed_count++))
    fi
}

# Test help examples actually work
function test_help_examples_work() {
    local test_name="Help examples produce expected results"
    ((test_count++))
    
    local temp_save="$TMPDIR/test_help_examples_$$"
    local failed_examples=()
    
    # Extract examples from help output
    local help_output=$(zsh -c 'source reminder.plugin.zsh; todo_help')
    
    # Test example: todo "Buy groceries"
    local example1_output=$(COLUMNS=80 TODO_SAVE_FILE="$temp_save" zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        eval "todo \"Buy groceries\""
    ')
    
    if [[ "$example1_output" != *"✅ Task added"* ]]; then
        failed_examples+=("todo \"Buy groceries\"")
    fi
    
    # Test example: todo_remove "Buy"
    local example2_output=$(COLUMNS=80 TODO_SAVE_FILE="$temp_save" zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        eval "todo_remove \"Buy\""
    ')
    
    if [[ "$example2_output" != *"✅ Task completed"* ]]; then
        failed_examples+=("todo_remove \"Buy\"")
    fi
    
    if [[ ${#failed_examples[@]} -eq 0 ]]; then
        echo "✅ PASS: $test_name"
        echo "  All help examples work as shown"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Failed examples: ${failed_examples[*]}"
        ((failed_count++))
    fi
    
    # Cleanup
    [[ -f "$temp_save" ]] && rm -f "$temp_save"
}

test_help_command_coverage
test_help_examples_work

# ===== 4. CONFIGURATION DOCUMENTATION ACCURACY =====

echo
echo "${fg[blue]}4. Testing Configuration Documentation${reset_color}"
echo "────────────────────────────────────────────"

# Test all documented configuration variables exist and work
function test_config_variables_documented() {
    local test_name="All configuration variables are documented and functional"
    ((test_count++))
    
    # Get user-facing TODO_* variables from implementation (exclude internal ones)
    local impl_vars=$(grep -o 'TODO_[A-Z_]*' reminder.plugin.zsh | sort -u)
    local documented_vars=()
    local undocumented_vars=()
    
    # Internal variables that don't need documentation
    local internal_vars=(
        "TODO_COLORS"                # Parsed array from TODO_TASK_COLORS
        "TODO_TASKS"                 # Runtime task storage
        "TODO_TASKS_COLORS"          # Runtime color storage
        "TODO_FIRST_RUN_FILE"        # Internal state tracking
        "TODO_CACHED_TASKS"          # Performance optimization - cache
        "TODO_CACHED_COLORS"         # Performance optimization - cache
        "TODO_CACHED_COLOR_INDEX"    # Performance optimization - cache
        "TODO_FILE_MTIME"            # Performance optimization - file tracking
        "TODO_PLUGIN_DIR"            # Internal path resolution
        "_TODO_LOADED_MODULES"       # Lazy loading tracking (underscore prefix)
        "TODO_LOADED_MODULES"        # Possible grep match of _TODO_LOADED_MODULES
    )
    
    # Check README and CLAUDE.md for variable documentation
    local doc_content=""
    if [[ -f "README.md" ]]; then
        doc_content+=$(cat README.md)
    fi
    if [[ -f "CLAUDE.md" ]]; then
        doc_content+=$(cat CLAUDE.md)
    fi
    
    # Check each implementation variable for documentation (skip internal ones)
    for var in ${(f)impl_vars}; do
        # Skip internal variables
        if [[ " ${internal_vars[*]} " =~ " $var " ]]; then
            continue
        fi
        
        if [[ "$doc_content" == *"$var"* ]]; then
            documented_vars+=("$var")
        else
            undocumented_vars+=("$var")
        fi
    done
    
    # Test that key configuration variables actually affect behavior
    local test_title_output=$(COLUMNS=80 TODO_TITLE="TEST_TITLE" zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        TODO_SAVE_FILE="/tmp/test_title_$$";
        todo_add_task "test" >/dev/null;
        todo_display 2>/dev/null | grep "TEST_TITLE" | wc -l
    ')
    
    local functional_test_passed=true
    if [[ "$test_title_output" -lt 1 ]]; then
        functional_test_passed=false
    fi
    
    if [[ ${#undocumented_vars[@]} -eq 0 && "$functional_test_passed" == true ]]; then
        echo "✅ PASS: $test_name"
        echo "  All variables documented and functional (${#documented_vars[@]} variables)"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        if [[ ${#undocumented_vars[@]} -gt 0 ]]; then
            echo "  Undocumented variables: ${undocumented_vars[*]}"
        fi
        if [[ "$functional_test_passed" == false ]]; then
            echo "  Configuration variables not affecting behavior"
        fi
        ((failed_count++))
    fi
}

# Test default values match documentation
function test_config_defaults_match() {
    local test_name="Documented default values match implementation"
    ((test_count++))
    
    local mismatched_defaults=()
    
    # Test specific defaults mentioned in documentation
    local impl_output=$(zsh -c 'source reminder.plugin.zsh; echo "$TODO_TITLE:$TODO_HEART_CHAR:$TODO_BULLET_CHAR"')
    
    # Extract actual defaults
    IFS=':' read -A actual_defaults <<< "$impl_output"
    local actual_title="${actual_defaults[1]}"
    local actual_heart="${actual_defaults[2]}"
    local actual_bullet="${actual_defaults[3]}"
    
    # Check against documented defaults
    if [[ "$actual_title" != "REMEMBER" ]]; then
        mismatched_defaults+=("TODO_TITLE: expected 'REMEMBER', got '$actual_title'")
    fi
    
    if [[ "$actual_heart" != "♥" ]]; then
        mismatched_defaults+=("TODO_HEART_CHAR: expected '♥', got '$actual_heart'")
    fi
    
    if [[ "$actual_bullet" != "▪" ]]; then
        mismatched_defaults+=("TODO_BULLET_CHAR: expected '▪', got '$actual_bullet'")
    fi
    
    if [[ ${#mismatched_defaults[@]} -eq 0 ]]; then
        echo "✅ PASS: $test_name"
        echo "  All documented defaults match implementation"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Mismatched defaults: ${mismatched_defaults[*]}"
        ((failed_count++))
    fi
}

test_config_variables_documented
test_config_defaults_match

# ===== 5. COMMAND BEHAVIOR DOCUMENTATION =====

echo
echo "${fg[blue]}5. Testing Command Behavior Documentation${reset_color}"
echo "────────────────────────────────────────────────"

# Test that documented command behaviors match actual behavior
function test_command_behavior_accuracy() {
    local test_name="Documented command behaviors are accurate"
    ((test_count++))
    
    local temp_save="$TMPDIR/test_behavior_$$"
    local behavior_mismatches=()
    
    # Test documented behavior: "todo adds tasks with success feedback"
    local add_output=$(COLUMNS=80 TODO_SAVE_FILE="$temp_save" zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        eval "todo \"Test task\""
    ')
    
    if [[ "$add_output" != *"✅ Task added"* ]]; then
        behavior_mismatches+=("todo command doesn't provide documented success feedback")
    fi
    
    # Test documented behavior: "task_done removes tasks with tab completion"
    local remove_output=$(COLUMNS=80 TODO_SAVE_FILE="$temp_save" zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        eval "task_done \"Test\""
    ')
    
    if [[ "$remove_output" != *"✅ Task completed"* ]]; then
        behavior_mismatches+=("task_done doesn't provide documented completion feedback")
    fi
    
    # Test documented behavior: "todo_help shows essential commands"
    local help_output=$(zsh -c 'source reminder.plugin.zsh; todo_help')
    
    if [[ "$help_output" != *"Essential Commands"* ]]; then
        behavior_mismatches+=("todo_help doesn't show documented 'Essential Commands' section")
    fi
    
    # Test documented behavior: "todo_colors shows color reference"
    local colors_output=$(zsh -c 'source reminder.plugin.zsh; todo_colors' | head -5)
    
    if [[ "$colors_output" != *"Color Reference"* ]]; then
        behavior_mismatches+=("todo_colors doesn't show documented color reference")
    fi
    
    if [[ ${#behavior_mismatches[@]} -eq 0 ]]; then
        echo "✅ PASS: $test_name"
        echo "  All documented command behaviors are accurate"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        for mismatch in "${behavior_mismatches[@]}"; do
            echo "  • $mismatch"
        done
        ((failed_count++))
    fi
    
    # Cleanup
    [[ -f "$temp_save" ]] && rm -f "$temp_save"
}

# Test edge cases mentioned in documentation
function test_documented_edge_cases() {
    local test_name="Documented edge cases behave as described"
    ((test_count++))
    
    local temp_save="$TMPDIR/test_edge_$$"
    local edge_case_failures=()
    
    # Test documented behavior: "Empty task list produces no output (or only contextual hints)"
    local empty_output=$(COLUMNS=80 TODO_SAVE_FILE="$temp_save" zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        todo_display
    ')
    
    # Empty output OR only contextual hints (UX improvement) are acceptable
    if [[ -n "$empty_output" && "$empty_output" != *"💡"* ]]; then
        edge_case_failures+=("Empty task list should produce no output or only contextual hints")
    fi
    
    # Test documented behavior: "Missing arguments show usage"
    local usage_output=$(zsh -c 'source reminder.plugin.zsh; todo_add_task 2>&1')
    
    if [[ "$usage_output" != *"Usage:"* ]]; then
        edge_case_failures+=("Missing arguments should show usage information")
    fi
    
    # Test documented behavior: "Invalid task removal shows helpful error"
    local error_output=$(COLUMNS=80 TODO_SAVE_FILE="$temp_save" zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        todo_task_done "nonexistent" 2>&1
    ')
    
    if [[ "$error_output" != *"No task found"* ]]; then
        edge_case_failures+=("Invalid task removal should show helpful error")
    fi
    
    if [[ ${#edge_case_failures[@]} -eq 0 ]]; then
        echo "✅ PASS: $test_name"
        echo "  All documented edge cases behave correctly"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        for failure in "${edge_case_failures[@]}"; do
            echo "  • $failure"
        done
        ((failed_count++))
    fi
    
    # Cleanup
    [[ -f "$temp_save" ]] && rm -f "$temp_save"
}

test_command_behavior_accuracy
test_documented_edge_cases

# ===== RESULTS SUMMARY =====

echo
echo "🎯 Documentation Test Results"
echo "═══════════════════════════════"
echo "Tests focused on documentation accuracy and implementation alignment"
echo

if [[ $failed_count -eq 0 ]]; then
    echo "${fg[green]}📖 All documentation tests passed! Documentation accurately represents implementation.${reset_color}"
else
    echo "${fg[red]}⚠️  Documentation discrepancies detected. Some docs need updating.${reset_color}"
fi

echo
echo "📊 Summary:"
echo "  Total Documentation Tests: $test_count"
echo "  ${fg[green]}Passed:                    $passed_count${reset_color}"
echo "  ${fg[red]}Failed:                    $failed_count${reset_color}"

if [[ $failed_count -gt 0 ]]; then
    echo
    echo "${fg[yellow]}Documentation Improvement Recommendations:${reset_color}"
    echo "  • Update README examples to match current implementation"
    echo "  • Verify all configuration variables are documented"
    echo "  • Ensure help output matches documented command descriptions"
    echo "  • Check that technical architecture claims are accurate"
    echo "  • Validate that all examples in documentation actually work"
    echo "  • Consider automating documentation updates from code comments"
fi

echo
echo "💡 Documentation Quality Notes:"
echo "  • Documentation is a user interface - it must be accurate"
echo "  • Outdated docs are worse than no docs - they mislead users"  
echo "  • Examples in docs should be copy-pasteable and functional"
echo "  • Technical claims should be verifiable in implementation"
echo "  • Help output is documentation - keep it synchronized"

# Return appropriate exit code
if [[ $failed_count -eq 0 ]]; then
    exit 0
else
    exit 1
fi