#!/usr/bin/env zsh

# Help Examples Testing - Validates that all examples in help output actually work
# Part of the pragmatic development workflow for preventing documentation drift

script_dir="${0:A:h}"
source "$script_dir/test_utils.zsh"

# Color definitions for output
autoload -U colors
colors

echo "📖 Testing Help Examples"
echo "═══════════════════════"
echo

test_count=0
passed_count=0
failed_count=0

echo "This test suite validates:"
echo "  • All command examples in help output actually work"
echo "  • Help examples produce expected outputs"
echo "  • No broken or outdated examples in documentation"
echo

# Test help examples from todo help --full
function test_full_help_examples() {
    local test_name="Full help examples are executable"
    ((test_count++))
    
    local temp_save="$TMPDIR/test_help_examples_$$"
    local failed_examples=()
    
    # Get full help and extract command examples
    local help_output=$(zsh -c 'source reminder.plugin.zsh; todo help --full')
    
    # Extract lines that look like command examples (start with space, contain todo, have # comment)
    local examples=($(echo "$help_output" | grep -E '^\s+todo.*#' | sed 's/#.*//' | sed 's/export //' | xargs -I {} echo "{}"))
    
    echo "  Found ${#examples[@]} command examples to test"
    
    for example in "${examples[@]}"; do
        # Skip environment variable exports and complex multi-line examples
        if [[ "$example" == *"TODO_"* ]] || [[ "$example" == *"\\\\"* ]] || [[ "$example" == *'"'* ]]; then
            continue
        fi
        
        # Test the command
        local test_output=$(COLUMNS=80 TODO_SAVE_FILE="$temp_save" zsh -c "
            autoload -U colors; colors;
            source reminder.plugin.zsh;
            $example" 2>&1)
        
        if [[ $? -ne 0 ]] && [[ "$test_output" == *"error"* || "$test_output" == *"command not found"* ]]; then
            failed_examples+=("$example")
        fi
    done
    
    # Test specific documented examples that should work
    local core_examples=(
        'todo "Buy groceries"'
        'todo done "Buy"'
        'todo help'
        'todo help --full'
        'todo help --colors'
        'todo help --config'
        'todo toggle affirmation'
        'todo hide'
        'todo show'
        'todo setup'
    )
    
    for example in "${core_examples[@]}"; do
        local test_output=$(COLUMNS=80 TODO_SAVE_FILE="$temp_save" zsh -c "
            autoload -U colors; colors;
            source reminder.plugin.zsh;
            $example" 2>&1)
        
        if [[ $? -ne 0 ]] && [[ "$test_output" == *"error"* || "$test_output" == *"Unknown"* ]]; then
            failed_examples+=("$example")
        fi
    done
    
    if [[ ${#failed_examples[@]} -eq 0 ]]; then
        echo "✅ PASS: $test_name"
        echo "  All help examples are executable"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Failed examples:"
        for example in "${failed_examples[@]}"; do
            echo "    • $example"
        done
        ((failed_count++))
    fi
    
    # Cleanup
    [[ -f "$temp_save" ]] && rm -f "$temp_save"
}

# Test that help examples produce expected outputs
function test_help_example_outputs() {
    local test_name="Help examples produce expected outputs"
    ((test_count++))
    
    local temp_save="$TMPDIR/test_help_outputs_$$"
    local failed_outputs=()
    
    # Test todo command gives success feedback
    local add_output=$(COLUMNS=80 TODO_SAVE_FILE="$temp_save" zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        todo "Test task"')
    
    if [[ "$add_output" != *"✅ Task added"* ]]; then
        failed_outputs+=("todo add doesn't show success feedback")
    fi
    
    # Test todo done gives completion feedback
    local done_output=$(COLUMNS=80 TODO_SAVE_FILE="$temp_save" zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        todo done "Test"')
    
    if [[ "$done_output" != *"✅ Task completed"* ]]; then
        failed_outputs+=("todo done doesn't show completion feedback")
    fi
    
    # Test help commands show expected sections
    local help_output=$(zsh -c 'source reminder.plugin.zsh; todo help')
    if [[ "$help_output" != *"Commands:"* ]]; then
        failed_outputs+=("todo help doesn't show Commands section")
    fi
    
    local config_help=$(zsh -c 'source reminder.plugin.zsh; todo help --config')
    if [[ "$config_help" != *"Available Presets:"* ]]; then
        failed_outputs+=("todo help --config doesn't show presets")
    fi
    
    if [[ ${#failed_outputs[@]} -eq 0 ]]; then
        echo "✅ PASS: $test_name"
        echo "  All help examples produce expected outputs"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Output issues:"
        for issue in "${failed_outputs[@]}"; do
            echo "    • $issue"
        done
        ((failed_count++))
    fi
    
    # Cleanup
    [[ -f "$temp_save" ]] && rm -f "$temp_save"
}

# Test that no obsolete commands are referenced in help
function test_no_obsolete_commands() {
    local test_name="No obsolete commands in help text"
    ((test_count++))
    
    local obsolete_commands=("task_done" "todo_affirm" "todo_remove" "todo_hide" "todo_show" "todo_setup" "todo_colors")
    local found_obsolete=()
    
    # Check all help outputs for obsolete commands
    local all_help=$(zsh -c 'source reminder.plugin.zsh; echo "=== BASIC ==="; todo help; echo "=== CONFIG ==="; todo help --config; echo "=== FULL ==="; todo help --full')
    
    for cmd in "${obsolete_commands[@]}"; do
        # Only flag if it appears as a command (not in file paths like /tmp/todo_affirmation)
        if echo "$all_help" | grep -E "(^|\s)$cmd(\s|$)" | grep -v "/tmp/" >/dev/null; then
            found_obsolete+=("$cmd")
        fi
    done
    
    if [[ ${#found_obsolete[@]} -eq 0 ]]; then
        echo "✅ PASS: $test_name"
        echo "  No obsolete command references found"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Found obsolete commands: ${found_obsolete[*]}"
        ((failed_count++))
    fi
}

test_full_help_examples
test_help_example_outputs
test_no_obsolete_commands

echo
echo "🎯 Help Examples Test Results"
echo "════════════════════════════"
echo "Tests focused on help documentation accuracy and example validation"
echo

if [[ $failed_count -eq 0 ]]; then
    echo "${fg[green]}📖 All help examples work correctly!${reset_color}"
else
    echo "${fg[red]}⚠️  Some help examples need fixing.${reset_color}"
fi

echo
echo "📊 Summary:"
echo "  Total Help Example Tests: $test_count"
echo "  ${fg[green]}Passed:                  $passed_count${reset_color}"
echo "  ${fg[red]}Failed:                  $failed_count${reset_color}"

# Return appropriate exit code
if [[ $failed_count -eq 0 ]]; then
    exit 0
else
    exit 1
fi