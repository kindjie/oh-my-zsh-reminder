#!/usr/bin/env zsh

# UX Test Suite for Todo Reminder Plugin
# Tests user experience, onboarding, and progressive disclosure

# Initialize test environment
script_dir="${0:A:h}"
source "$script_dir/test_utils.zsh"

# Color definitions for output
autoload -U colors
colors

echo "🎨 Testing User Experience & Onboarding"
echo "════════════════════════════════════════"
echo

# Test counter
test_count=0
passed_count=0
failed_count=0

# UX Test Categories
echo "This test suite validates:"
echo "  • Beginner onboarding experience"
echo "  • Progressive disclosure design"
echo "  • Command clarity and discoverability"
echo "  • Success feedback and error handling"
echo "  • Help system effectiveness"
echo

# ===== 1. ONBOARDING EXPERIENCE TESTS =====

echo "${fg[blue]}1. Testing Onboarding Experience${reset_color}"
echo "─────────────────────────────────────"

# Test first-run welcome message
function test_first_run_welcome() {
    local test_name="First-run welcome message"
    ((test_count++))
    
    # Remove first-run marker to simulate new user
    local temp_first_run="$TMPDIR/test_first_run_$$"
    
    # Test by sourcing plugin with non-existent first-run file
    local output=$(COLUMNS=80 TODO_FIRST_RUN_FILE="$temp_first_run" zsh -c '
        autoload -U colors; colors; 
        source reminder.plugin.zsh;
        # Function should be defined when first-run file doesnt exist
        if declare -f show_welcome_message >/dev/null; then
            show_welcome_message 2>/dev/null
        else
            echo "show_welcome_message function not available"
        fi
    ')
    
    if [[ "$output" == *"Welcome to Todo Reminder!"* ]] && \
       [[ "$output" == *"Get started:"* ]] && \
       [[ "$output" == *"todo"* ]] && \
       [[ "$output" == *"Quick help:"* ]] && \
       [[ "$output" == *"todo_help"* ]] && \
       [[ "$output" == *"Customize:"* ]] && \
       [[ "$output" == *"todo_setup"* ]]; then
        echo "✅ PASS: $test_name"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Expected welcome message with key elements"
        echo "  Output: $output"
        ((failed_count++))
    fi
    
    # Cleanup
    [[ -f "$temp_first_run" ]] && rm -f "$temp_first_run"
}

# Test welcome message only shows once
function test_welcome_message_once() {
    local test_name="Welcome message shows only once"
    ((test_count++))
    
    local temp_first_run="$TMPDIR/test_first_run_once_$$"
    
    # First run - should show welcome
    local output1=$(COLUMNS=80 TODO_FIRST_RUN_FILE="$temp_first_run" zsh -c '
        autoload -U colors; colors; 
        source reminder.plugin.zsh;
        if [[ ! -f "'$temp_first_run'" ]]; then show_welcome_message 2>/dev/null; fi
    ')
    
    # Second run - should not show welcome (file exists)
    local output2=$(COLUMNS=80 TODO_FIRST_RUN_FILE="$temp_first_run" zsh -c '
        autoload -U colors; colors; 
        source reminder.plugin.zsh;
        if [[ ! -f "'$temp_first_run'" ]]; then show_welcome_message 2>/dev/null; fi
    ')
    
    if [[ "$output1" == *"Welcome to Todo Reminder!"* ]] && \
       [[ -z "$output2" || "$output2" != *"Welcome to Todo Reminder!"* ]]; then
        echo "✅ PASS: $test_name"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Welcome should show once, then be suppressed"
        ((failed_count++))
    fi
    
    # Cleanup
    [[ -f "$temp_first_run" ]] && rm -f "$temp_first_run"
}

test_first_run_welcome
test_welcome_message_once

# ===== 2. COMMAND CLARITY TESTS =====

echo
echo "${fg[blue]}2. Testing Command Clarity & Aliases${reset_color}"
echo "───────────────────────────────────────────"

# Test beginner-friendly aliases exist
function test_beginner_aliases() {
    local test_name="Beginner-friendly aliases exist"
    ((test_count++))
    
    local aliases_output=$(zsh -c 'source reminder.plugin.zsh; alias | grep -E "(todo_remove|todo_hide|todo_show|todo_setup|todo_toggle)"')
    
    local required_aliases=("todo_remove" "todo_hide" "todo_show" "todo_setup" "todo_toggle")
    local missing_aliases=()
    
    for alias_name in "${required_aliases[@]}"; do
        if [[ "$aliases_output" != *"$alias_name="* ]]; then
            missing_aliases+=("$alias_name")
        fi
    done
    
    if [[ ${#missing_aliases[@]} -eq 0 ]]; then
        echo "✅ PASS: $test_name"
        echo "  Found: todo_remove, todo_hide, todo_show, todo_setup, todo_toggle"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Missing aliases: ${missing_aliases[*]}"
        ((failed_count++))
    fi
}

# Test alias clarity (meaningful names)
function test_alias_clarity() {
    local test_name="Alias names are self-explanatory"
    ((test_count++))
    
    # Check that aliases point to logical functions
    local todo_remove_target=$(zsh -c 'source reminder.plugin.zsh; alias todo_remove' | cut -d= -f2)
    local todo_hide_target=$(zsh -c 'source reminder.plugin.zsh; alias todo_hide' | cut -d= -f2)
    
    if [[ "$todo_remove_target" == *"todo_task_done"* ]] && \
       [[ "$todo_hide_target" == *"hide"* ]]; then
        echo "✅ PASS: $test_name"
        echo "  todo_remove → task removal, todo_hide → hiding functionality"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Aliases don't point to expected functions"
        ((failed_count++))
    fi
}

# Test tab completion setup
function test_tab_completion() {
    local test_name="Tab completion is properly configured"
    ((test_count++))
    
    # Test that compdef wrapper exists and doesn't error
    local output=$(zsh -c 'autoload -U compinit; compinit; source reminder.plugin.zsh 2>&1')
    
    if [[ "$output" != *"command not found: compdef"* ]]; then
        echo "✅ PASS: $test_name"
        echo "  Tab completion configured without errors"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Tab completion setup has errors"
        ((failed_count++))
    fi
}

test_beginner_aliases
test_alias_clarity
test_tab_completion

# ===== 3. SUCCESS FEEDBACK TESTS =====

echo
echo "${fg[blue]}3. Testing Success Feedback & Error Handling${reset_color}"
echo "─────────────────────────────────────────────────────"

# Test task addition feedback
function test_task_addition_feedback() {
    local test_name="Task addition provides clear feedback"
    ((test_count++))
    
    local temp_save="$TMPDIR/test_feedback_$$"
    local output=$(COLUMNS=80 TODO_SAVE_FILE="$temp_save" zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        todo_add_task "Test task for feedback"
    ')
    
    if [[ "$output" == *"✅ Task added:"* ]] && \
       [[ "$output" == *"Test task for feedback"* ]] && \
       [[ "$output" == *"💡"* ]]; then
        echo "✅ PASS: $test_name"
        echo "  Includes success icon, task name, and helpful tip"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Missing expected feedback elements"
        echo "  Output: $output"
        ((failed_count++))
    fi
    
    # Cleanup
    [[ -f "$temp_save" ]] && rm -f "$temp_save"
}

# Test first task special feedback
function test_first_task_guidance() {
    local test_name="First task provides extra guidance"
    ((test_count++))
    
    local temp_save="$TMPDIR/test_first_task_$$"
    local output=$(COLUMNS=80 TODO_SAVE_FILE="$temp_save" zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        todo_add_task "First task ever"
    ')
    
    if [[ "$output" == *"appear above the prompt"* ]] && \
       [[ "$output" == *"Remove with: todo_remove"* ]]; then
        echo "✅ PASS: $test_name"
        echo "  First task includes explanation and removal example"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Missing first-task guidance"
        ((failed_count++))
    fi
    
    # Cleanup
    [[ -f "$temp_save" ]] && rm -f "$temp_save"
}

# Test task removal feedback
function test_task_removal_feedback() {
    local test_name="Task removal provides celebration feedback"
    ((test_count++))
    
    local temp_save="$TMPDIR/test_removal_$$"
    
    # Add and remove a task
    local output=$(COLUMNS=80 TODO_SAVE_FILE="$temp_save" zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        todo_add_task "Task to remove" >/dev/null;
        todo_task_done "Task to remove"
    ')
    
    if [[ "$output" == *"✅ Task completed:"* ]] && \
       [[ "$output" == *"🎉 All tasks done!"* ]]; then
        echo "✅ PASS: $test_name"
        echo "  Includes completion confirmation and celebration"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Missing expected removal feedback"
        ((failed_count++))
    fi
    
    # Cleanup
    [[ -f "$temp_save" ]] && rm -f "$temp_save"
}

# Test helpful error messages
function test_helpful_errors() {
    local test_name="Error messages provide helpful guidance"
    ((test_count++))
    
    local temp_save="$TMPDIR/test_errors_$$"
    local error_output=$(COLUMNS=80 TODO_SAVE_FILE="$temp_save" zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        todo_task_done "nonexistent" 2>&1
    ')
    
    if [[ "$error_output" == *"❌ No task found"* ]] && \
       [[ "$error_output" == *"💡"* ]] && \
       [[ "$error_output" == *"Add one with:"* ]]; then
        echo "✅ PASS: $test_name"
        echo "  Error includes clear icon, explanation, and next steps"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Error messages not helpful enough"
        ((failed_count++))
    fi
    
    # Cleanup
    [[ -f "$temp_save" ]] && rm -f "$temp_save"
}

# Test missing arguments guidance
function test_missing_args_help() {
    local test_name="Missing arguments provide usage examples"
    ((test_count++))
    
    local help_output=$(zsh -c 'source reminder.plugin.zsh; todo_add_task 2>&1')
    
    if [[ "$help_output" == *"Usage: todo"* ]] && \
       [[ "$help_output" == *"Example:"* ]]; then
        echo "✅ PASS: $test_name"
        echo "  Missing args show usage and examples"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Missing argument help insufficient"
        ((failed_count++))
    fi
}

test_task_addition_feedback
test_first_task_guidance
test_task_removal_feedback
test_helpful_errors
test_missing_args_help

# ===== 4. PROGRESSIVE DISCLOSURE TESTS =====

echo
echo "${fg[blue]}4. Testing Progressive Disclosure Design${reset_color}"
echo "───────────────────────────────────────────────"

# Test simplified help is truly simple
function test_simple_help_brevity() {
    local test_name="Simplified help is concise (< 20 lines)"
    ((test_count++))
    
    local help_lines=$(COLUMNS=80 zsh -c 'source reminder.plugin.zsh; todo_help' | wc -l)
    
    if [[ $help_lines -lt 20 ]]; then
        echo "✅ PASS: $test_name"
        echo "  Help is $help_lines lines (concise for beginners)"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Help is $help_lines lines (too verbose for beginners)"
        ((failed_count++))
    fi
}

# Test simplified help shows essential commands
function test_simple_help_essentials() {
    local test_name="Simplified help shows Layer 1 commands"
    ((test_count++))
    
    local help_output=$(COLUMNS=80 zsh -c 'source reminder.plugin.zsh; todo_help')
    local essential_commands=("todo" "todo_remove" "todo_hide" "todo_show" "todo_setup")
    local missing_commands=()
    
    for cmd in "${essential_commands[@]}"; do
        if [[ "$help_output" != *"$cmd"* ]]; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -eq 0 ]]; then
        echo "✅ PASS: $test_name"
        echo "  All Layer 1 commands present in simple help"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Missing essential commands: ${missing_commands[*]}"
        ((failed_count++))
    fi
}

# Test help discovery path
function test_help_discovery_path() {
    local test_name="Simple help points to advanced help"
    ((test_count++))
    
    local help_output=$(COLUMNS=80 zsh -c 'source reminder.plugin.zsh; todo_help')
    
    if [[ "$help_output" == *"--more"* ]] || [[ "$help_output" == *"todo_help --more"* ]]; then
        echo "✅ PASS: $test_name"
        echo "  Simple help includes path to advanced help"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  No clear path from simple to advanced help"
        ((failed_count++))
    fi
}

# Test advanced help preservation
function test_advanced_help_preserved() {
    local test_name="Advanced help preserves all features"
    ((test_count++))
    
    local full_help=$(COLUMNS=80 zsh -c 'source reminder.plugin.zsh; todo_help --more')
    local advanced_features=("todo_config" "export" "import" "preset" "TODO_TASK_COLORS" "TODO_BORDER_COLOR")
    local missing_features=()
    
    for feature in "${advanced_features[@]}"; do
        if [[ "$full_help" != *"$feature"* ]]; then
            missing_features+=("$feature")
        fi
    done
    
    if [[ ${#missing_features[@]} -eq 0 ]]; then
        echo "✅ PASS: $test_name"
        echo "  All advanced features documented in full help"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Missing advanced features: ${missing_features[*]}"
        ((failed_count++))
    fi
}

# Test contextual hints are non-intrusive
function test_contextual_hints_timing() {
    local test_name="Contextual hints appear occasionally (not spam)"
    ((test_count++))
    
    # Test empty state hint timing (should not appear every time)
    local hint_count=0
    local total_tests=10
    
    for i in {1..$total_tests}; do
        local output=$(COLUMNS=80 zsh -c "
            autoload -U colors; colors;
            source reminder.plugin.zsh;
            show_empty_state_hint
        ")
        if [[ "$output" == *"💡"* ]]; then
            ((hint_count++))
        fi
    done
    
    # Should appear sometimes but not always (testing randomness)
    if [[ $hint_count -gt 0 && $hint_count -lt $total_tests ]]; then
        echo "✅ PASS: $test_name"
        echo "  Hints appeared $hint_count/$total_tests times (appropriately occasional)"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Hints appeared $hint_count/$total_tests times (too frequent or never)"
        ((failed_count++))
    fi
}

test_simple_help_brevity
test_simple_help_essentials
test_help_discovery_path
test_advanced_help_preserved
test_contextual_hints_timing

# ===== 5. USABILITY WORKFLOW TESTS =====

echo
echo "${fg[blue]}5. Testing Complete Beginner Workflow${reset_color}"
echo "────────────────────────────────────────────"

# Test complete beginner workflow
function test_beginner_workflow() {
    local test_name="Complete beginner workflow (0 to productive)"
    ((test_count++))
    
    local temp_save="$TMPDIR/test_workflow_$$"
    local workflow_success=true
    local workflow_log=""
    
    # Step 1: Get help
    local help_output=$(COLUMNS=80 TODO_SAVE_FILE="$temp_save" zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        todo_help
    ')
    
    if [[ "$help_output" != *"todo"* ]]; then
        workflow_success=false
        workflow_log+="Step 1 FAIL: Help command didn't work\n"
    fi
    
    # Step 2: Add first task
    local add_output=$(COLUMNS=80 TODO_SAVE_FILE="$temp_save" zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        eval "todo \"Learn todo plugin\""
    ')
    
    if [[ "$add_output" != *"✅ Task added"* ]]; then
        workflow_success=false
        workflow_log+="Step 2 FAIL: Task addition didn't provide feedback\n"
    fi
    
    # Step 3: Remove task using new alias
    local remove_output=$(COLUMNS=80 TODO_SAVE_FILE="$temp_save" zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        eval "todo_remove \"Learn\""
    ')
    
    if [[ "$remove_output" != *"✅ Task completed"* ]]; then
        workflow_success=false
        workflow_log+="Step 3 FAIL: Task removal didn't work with alias\n"
    fi
    
    if [[ "$workflow_success" == true ]]; then
        echo "✅ PASS: $test_name"
        echo "  Beginner can: get help → add task → remove task successfully"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo -e "$workflow_log"
        ((failed_count++))
    fi
    
    # Cleanup
    [[ -f "$temp_save" ]] && rm -f "$temp_save"
}

# Test Layer 2 discovery
function test_layer_2_discovery() {
    local test_name="Layer 2 features discoverable from Layer 1"
    ((test_count++))
    
    local help_output=$(COLUMNS=80 zsh -c 'source reminder.plugin.zsh; todo_help')
    local layer_2_hints=("todo_setup" "todo_colors" "todo_hide" "todo_show")
    local missing_hints=()
    
    for hint in "${layer_2_hints[@]}"; do
        if [[ "$help_output" != *"$hint"* ]]; then
            missing_hints+=("$hint")
        fi
    done
    
    if [[ ${#missing_hints[@]} -eq 0 ]]; then
        echo "✅ PASS: $test_name"
        echo "  Layer 2 features visible in basic help for discovery"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Missing Layer 2 discovery hints: ${missing_hints[*]}"
        ((failed_count++))
    fi
}

# Test power user workflow preservation
function test_power_user_preservation() {
    local test_name="Power user workflows still work"
    ((test_count++))
    
    # Test advanced command still works
    local config_output=$(zsh -c 'source reminder.plugin.zsh; todo_config --help 2>&1 || todo_config help 2>&1')
    
    # Test alias access to advanced features
    local setup_output=$(zsh -c 'source reminder.plugin.zsh; which todo_setup')
    
    if [[ "$config_output" == *"todo_config"* ]] && \
       [[ "$setup_output" == *"todo_config_wizard"* ]]; then
        echo "✅ PASS: $test_name"
        echo "  Advanced features accessible via both original and alias commands"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Power user workflows broken"
        ((failed_count++))
    fi
}

test_beginner_workflow
test_layer_2_discovery
test_power_user_preservation

# ===== RESULTS SUMMARY =====

echo
echo "🎯 UX Test Results"
echo "════════════════════"
echo "Tests focused on user experience, onboarding, and usability"
echo

if [[ $failed_count -eq 0 ]]; then
    echo "${fg[green]}✨ All UX tests passed! The plugin provides excellent user experience.${reset_color}"
else
    echo "${fg[red]}⚠️  Some UX issues detected. User experience could be improved.${reset_color}"
fi

echo
echo "📊 Summary:"
echo "  Total UX Tests:    $test_count"
echo "  ${fg[green]}Passed:           $passed_count${reset_color}"
echo "  ${fg[red]}Failed:           $failed_count${reset_color}"

if [[ $failed_count -gt 0 ]]; then
    echo
    echo "${fg[yellow]}UX Improvement Recommendations:${reset_color}"
    echo "  • Review failed tests for specific UX gaps"
    echo "  • Focus on beginner onboarding experience"
    echo "  • Ensure progressive disclosure is working"
    echo "  • Validate success feedback is clear and helpful"
    echo "  • Test with actual new users for real-world validation"
fi

echo
echo "💡 UX Validation Notes:"
echo "  • These tests validate designed UX improvements"
echo "  • Real user testing is recommended for final validation"
echo "  • Progressive disclosure should make advanced features discoverable"
echo "  • Success feedback should build user confidence"
echo "  • Error messages should guide users to success"

# Return appropriate exit code
if [[ $failed_count -eq 0 ]]; then
    exit 0
else
    exit 1
fi