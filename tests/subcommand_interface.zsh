#!/usr/bin/env zsh

# Pure Subcommand Interface Tests
# Tests for the todo() main dispatcher and subcommand routing

echo "🎛️  Testing Pure Subcommand Interface"
echo "════════════════════════════════════════"

# Test setup
source_test_plugin() {
    autoload -U colors
    colors
    source reminder.plugin.zsh
}

# Test counters
test_count=0
pass_count=0
fail_count=0

# Test helper
run_test() {
    local test_name="$1"
    ((test_count++))
    echo -n "  Test $test_count: $test_name ... "
}

# ============================================================================
# Unit Tests - Main Dispatcher
# ============================================================================

echo -e "\n[Unit Tests] Main Dispatcher"
echo "─────────────────────────────"

# Test 1: Main dispatcher routes to help by default
test_main_dispatcher_default() {
    run_test "Main dispatcher defaults to help"
    
    source_test_plugin
    local output=$(todo 2>&1)
    
    if [[ "$output" == *"Commands:"* ]] && [[ "$output" == *"Examples:"* ]]; then
        echo "✅ PASS"
        ((pass_count++))
    else
        echo "❌ FAIL: Expected help output"
        ((fail_count++))
    fi
}

# Test 2: Task addition through dispatcher
test_dispatcher_task_addition() {
    run_test "Dispatcher handles task addition"
    
    source_test_plugin
    local temp_save="$TMPDIR/test_dispatcher_$$"
    local output=$(TODO_SAVE_FILE="$temp_save" todo "Test task" 2>&1)
    
    if [[ "$output" == *"Task added"* ]]; then
        echo "✅ PASS"
        ((pass_count++))
    else
        echo "❌ FAIL: Expected task addition confirmation"
        ((fail_count++))
    fi
    
    [[ -f "$temp_save" ]] && rm -f "$temp_save"
}

# Test 3: Subcommand routing
test_subcommand_routing() {
    run_test "Subcommand routing works"
    
    source_test_plugin
    
    # Test various subcommands
    local hide_output=$(todo hide 2>&1)
    local show_output=$(todo show 2>&1)
    local help_output=$(todo help 2>&1)
    
    if [[ "$hide_output" == *"disabled"* ]] && \
       [[ "$show_output" == *"enabled"* ]] && \
       [[ "$help_output" == *"Commands:"* ]]; then
        echo "✅ PASS"
        ((pass_count++))
    else
        echo "❌ FAIL: Subcommand routing failed"
        ((fail_count++))
    fi
}

# Test 4: Invalid subcommand handling
test_invalid_subcommand() {
    run_test "Invalid subcommand handling"
    
    source_test_plugin
    local temp_save="$TMPDIR/test_invalid_subcommand_$$"
    local output=$(TODO_SAVE_FILE="$temp_save" todo invalid_command 2>&1)
    
    # Should add task called "invalid_command" since unrecognized commands become tasks
    if [[ "$output" == *"Task added"* ]] && [[ "$output" == *"invalid_command"* ]]; then
        echo "✅ PASS"
        ((pass_count++))
    else
        echo "❌ FAIL: Expected task addition for unrecognized command"
        ((fail_count++))
    fi
    
    # Cleanup
    [[ -f "$temp_save" ]] && rm -f "$temp_save"
}

# ============================================================================
# Unit Tests - Nested Subcommands
# ============================================================================

echo -e "\n\n[Unit Tests] Nested Subcommands"
echo "────────────────────────────────"

# Test 5: Config subcommand dispatcher
test_config_dispatcher() {
    run_test "Config subcommand dispatcher"
    
    source_test_plugin
    local output=$(todo config 2>&1)
    
    if [[ "$output" == *"Usage: todo config"* ]] && \
       [[ "$output" == *"export"* ]] && \
       [[ "$output" == *"import"* ]]; then
        echo "✅ PASS"
        ((pass_count++))
    else
        echo "❌ FAIL: Expected config usage help"
        ((fail_count++))
    fi
}

# Test 6: Toggle subcommand dispatcher
test_toggle_dispatcher() {
    run_test "Toggle subcommand dispatcher"
    
    source_test_plugin
    local output=$(todo toggle 2>&1)
    
    # Toggle without args should toggle all
    if [[ "$output" == *"disabled"* ]] || [[ "$output" == *"enabled"* ]]; then
        echo "✅ PASS"
        ((pass_count++))
    else
        echo "❌ FAIL: Expected toggle output"
        ((fail_count++))
    fi
}

# Test 7: Nested config commands
test_nested_config_commands() {
    run_test "Nested config command routing"
    
    source_test_plugin
    local temp_file="$TMPDIR/test_config_$$"
    
    # Test config export
    local export_output=$(todo config export "$temp_file" 2>&1)
    
    if [[ -f "$temp_file" ]]; then
        echo "✅ PASS"
        ((pass_count++))
        rm -f "$temp_file"
    else
        echo "❌ FAIL: Config export failed"
        ((fail_count++))
    fi
}

# Test 8: Nested toggle commands
test_nested_toggle_commands() {
    run_test "Nested toggle command routing"
    
    source_test_plugin
    
    # Test toggle affirmation
    local toggle_aff=$(todo toggle affirmation 2>&1)
    local toggle_box=$(todo toggle box 2>&1)
    
    if [[ "$toggle_aff" == *"Affirmations"* ]] && \
       [[ "$toggle_box" == *"Todo box"* ]]; then
        echo "✅ PASS"
        ((pass_count++))
    else
        echo "❌ FAIL: Nested toggle commands failed"
        ((fail_count++))
    fi
}

# ============================================================================
# Integration Tests - Tab Completion
# ============================================================================

echo -e "\n\n[Integration Tests] Tab Completion"
echo "──────────────────────────────────"

# Test 9: Tab completion setup
test_tab_completion_setup() {
    run_test "Tab completion registered"
    
    source_test_plugin
    
    # Check if completion is registered
    if command -v _todo_completion >/dev/null 2>&1; then
        echo "✅ PASS"
        ((pass_count++))
    else
        echo "❌ FAIL: Completion function not found"
        ((fail_count++))
    fi
}

# Test 10: Completion data structure
test_completion_data() {
    run_test "Completion provides correct options"
    
    source_test_plugin
    
    # Check that compdef registered the completion
    if whence -f _todo_completion >/dev/null 2>&1; then
        echo "✅ PASS"
        ((pass_count++))
    else
        echo "❌ FAIL: Completion function not properly registered"
        ((fail_count++))
    fi
}

# ============================================================================
# Integration Tests - Help System
# ============================================================================

echo -e "\n\n[Integration Tests] Help System"
echo "───────────────────────────────"

# Test 11: Help at all command levels
test_help_levels() {
    run_test "Help available at all levels"
    
    source_test_plugin
    
    # Root level help
    local root_help=$(todo help 2>&1)
    local config_help=$(todo help --config 2>&1)
    local color_help=$(todo help --colors 2>&1)
    
    if [[ "$root_help" == *"Commands:"* ]] && \
       [[ "$config_help" == *"Configuration"* ]] && \
       [[ "$color_help" == *"Color"* ]]; then
        echo "✅ PASS"
        ((pass_count++))
    else
        echo "❌ FAIL: Help not available at all levels"
        ((fail_count++))
    fi
}

# Test 12: Progressive help system
test_progressive_help() {
    run_test "Progressive help (basic → full)"
    
    source_test_plugin
    
    local basic_help=$(todo help 2>&1)
    local full_help=$(todo help --full 2>&1)
    
    # Full help should be longer than basic
    local basic_lines=$(echo "$basic_help" | wc -l)
    local full_lines=$(echo "$full_help" | wc -l)
    
    if [[ $full_lines -gt $basic_lines ]] && \
       [[ "$full_help" == *"Configuration Management"* ]]; then
        echo "✅ PASS"
        ((pass_count++))
    else
        echo "❌ FAIL: Progressive help not working"
        ((fail_count++))
    fi
}

# ============================================================================
# Integration Tests - Error Handling
# ============================================================================

echo -e "\n\n[Integration Tests] Error Handling"
echo "──────────────────────────────────"

# Test 13: Error propagation through dispatcher
test_error_propagation() {
    run_test "Errors propagate correctly"
    
    source_test_plugin
    
    # Try to import non-existent file
    local error_output=$(todo config import /nonexistent/file 2>&1)
    
    if [[ "$error_output" == *"Error"* ]] || [[ "$error_output" == *"not found"* ]]; then
        echo "✅ PASS"
        ((pass_count++))
    else
        echo "❌ FAIL: Error not propagated"
        ((fail_count++))
    fi
}

# Test 14: Invalid nested commands
test_invalid_nested_commands() {
    run_test "Invalid nested command handling"
    
    source_test_plugin
    
    # Try invalid config command
    local output=$(todo config invalid_action 2>&1)
    
    if [[ "$output" == *"Unknown config action"* ]]; then
        echo "✅ PASS"
        ((pass_count++))
    else
        echo "❌ FAIL: Invalid command not handled"
        ((fail_count++))
    fi
}

# ============================================================================
# Run all tests
# ============================================================================

echo -e "\n\n[Running All Tests]"
echo "═══════════════════"

test_main_dispatcher_default
test_dispatcher_task_addition
test_subcommand_routing
test_invalid_subcommand
test_config_dispatcher
test_toggle_dispatcher
test_nested_config_commands
test_nested_toggle_commands
test_tab_completion_setup
test_completion_data
test_help_levels
test_progressive_help
test_error_propagation
test_invalid_nested_commands

# ============================================================================
# Summary
# ============================================================================

echo -e "\n\n🎯 Subcommand Interface Test Summary"
echo "═══════════════════════════════════"
echo "Total Tests:    $test_count"
echo "Passed:         $pass_count"
echo "Failed:         $fail_count"
echo
if [[ $fail_count -eq 0 ]]; then
    echo "✅ All subcommand interface tests passed!"
else
    echo "❌ Some tests failed. Please review the output above."
fi