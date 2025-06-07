#!/usr/bin/env zsh

# User interface tests for the reminder plugin

echo "🎛️  Testing User Interface Commands"
echo "══════════════════════════════════════"

# Test setup - shared test helper functions
source_test_plugin() {
    autoload -U colors
    colors
    source reminder.plugin.zsh
}

# Test 1: Toggle commands
test_toggle_commands() {
    echo "\n1. Testing toggle commands:"
    
    source_test_plugin
    
    # Test affirmation toggle
    original_affirmation_state="$TODO_SHOW_AFFIRMATION"
    echo "Original affirmation state: $TODO_SHOW_AFFIRMATION"
    
    todo_toggle_affirmation hide >/dev/null
    if [[ "$TODO_SHOW_AFFIRMATION" == "false" ]]; then
        echo "✅ PASS: Affirmation hiding works"
    else
        echo "❌ FAIL: Affirmation hiding failed"
    fi
    
    todo_toggle_affirmation show >/dev/null
    if [[ "$TODO_SHOW_AFFIRMATION" == "true" ]]; then
        echo "✅ PASS: Affirmation showing works"
    else
        echo "❌ FAIL: Affirmation showing failed"
    fi
    
    # Test todo box toggle
    original_box_state="$TODO_SHOW_TODO_BOX"
    echo "Original todo box state: $TODO_SHOW_TODO_BOX"
    
    todo_toggle_box hide >/dev/null
    if [[ "$TODO_SHOW_TODO_BOX" == "false" ]]; then
        echo "✅ PASS: Todo box hiding works"
    else
        echo "❌ FAIL: Todo box hiding failed"
    fi
    
    todo_toggle_box show >/dev/null
    if [[ "$TODO_SHOW_TODO_BOX" == "true" ]]; then
        echo "✅ PASS: Todo box showing works"
    else
        echo "❌ FAIL: Todo box showing failed"
    fi
    
    # Test toggle all
    todo_toggle_all hide >/dev/null
    if [[ "$TODO_SHOW_AFFIRMATION" == "false" && "$TODO_SHOW_TODO_BOX" == "false" ]]; then
        echo "✅ PASS: Toggle all hide works"
    else
        echo "❌ FAIL: Toggle all hide failed"
    fi
    
    todo_toggle_all show >/dev/null
    if [[ "$TODO_SHOW_AFFIRMATION" == "true" && "$TODO_SHOW_TODO_BOX" == "true" ]]; then
        echo "✅ PASS: Toggle all show works"
    else
        echo "❌ FAIL: Toggle all show failed"
    fi
    
    # Test toggle without arguments (should toggle)
    original_affirmation_state2="$TODO_SHOW_AFFIRMATION"
    todo_toggle_affirmation >/dev/null  # Should toggle
    if [[ "$TODO_SHOW_AFFIRMATION" != "$original_affirmation_state2" ]]; then
        echo "✅ PASS: Toggle affirmation without arguments works"
    else
        echo "❌ FAIL: Toggle affirmation without arguments failed"
    fi
    
    # Test invalid arguments
    error_output=$(todo_toggle_affirmation invalid 2>&1)
    if [[ $? -ne 0 && "$error_output" == *"Usage:"* ]]; then
        echo "✅ PASS: Invalid toggle arguments produce error"
    else
        echo "❌ FAIL: Invalid toggle arguments don't produce proper error"
    fi
    
    # Test toggle all combinations
    todo_toggle_all hide >/dev/null
    todo_toggle_all toggle >/dev/null  # Should show both
    if [[ "$TODO_SHOW_AFFIRMATION" == "true" && "$TODO_SHOW_TODO_BOX" == "true" ]]; then
        echo "✅ PASS: Toggle all from hide to show works"
    else
        echo "❌ FAIL: Toggle all from hide to show failed"
    fi
    
    # Restore original states
    TODO_SHOW_AFFIRMATION="$original_affirmation_state"
    TODO_SHOW_TODO_BOX="$original_box_state"
}

# Test 2: Help command functionality
test_help_command() {
    echo "\n2. Testing help command:"
    
    # Test that help command exists and works
    if command -v todo_help >/dev/null 2>&1; then
        echo "✅ PASS: todo_help command exists"
    else
        echo "❌ FAIL: todo_help command not found"
    fi
    
    # Test that help command produces output
    help_output=$(todo_help 2>/dev/null)
    if [[ -n "$help_output" ]] && [[ "$help_output" == *"Quick Reference"* ]]; then
        echo "✅ PASS: todo_help produces help output"
    else
        echo "❌ FAIL: todo_help doesn't produce expected output"
    fi
    
    # Test that help includes key sections
    if [[ "$help_output" == *"Task Management"* ]] && [[ "$help_output" == *"Display Controls"* ]] && [[ "$help_output" == *"Configuration"* ]]; then
        echo "✅ PASS: Help includes all major sections"
    else
        echo "❌ FAIL: Help missing major sections"
    fi
    
    # Test that help includes new color features
    if [[ "$help_output" == *"todo_colors"* ]] && [[ "$help_output" == *"Color Configuration"* ]]; then
        echo "✅ PASS: Help includes color configuration features"
    else
        echo "❌ FAIL: Help missing color configuration features"
    fi
    
    # Test that help includes examples
    if [[ "$help_output" == *"Examples:"* ]] && [[ "$help_output" == *"todo \"Buy groceries\""* ]]; then
        echo "✅ PASS: Help includes usage examples"
    else
        echo "❌ FAIL: Help missing usage examples"
    fi
    
    # Test that help includes file locations
    if [[ "$help_output" == *"Files:"* ]] && [[ "$help_output" == *".todo.save"* ]]; then
        echo "✅ PASS: Help includes file information"
    else
        echo "❌ FAIL: Help missing file information"
    fi
}

# Test 3: todo_colors command
test_colors_command() {
    echo "\n3. Testing todo_colors command:"
    
    # Test todo_colors command exists
    if command -v todo_colors >/dev/null 2>&1; then
        echo "✅ PASS: todo_colors command exists"
    else
        echo "❌ FAIL: todo_colors command not found"
    fi
    
    # Test todo_colors produces output
    colors_output=$(todo_colors 16 2>/dev/null)
    if [[ -n "$colors_output" ]] && [[ "$colors_output" == *"Color Reference"* ]]; then
        echo "✅ PASS: todo_colors produces color reference output"
    else
        echo "❌ FAIL: todo_colors doesn't produce expected output"
    fi
    
    # Test that todo_colors shows current configuration
    if [[ "$colors_output" == *"Current plugin colors"* ]] && [[ "$colors_output" == *"Task colors: $TODO_TASK_COLORS"* ]]; then
        echo "✅ PASS: todo_colors shows current configuration"
    else
        echo "❌ FAIL: todo_colors doesn't show current configuration"
    fi
    
    # Test color display format
    if [[ "$colors_output" == *"Basic Colors (0-15):"* ]]; then
        echo "✅ PASS: todo_colors shows basic colors section"
    else
        echo "❌ FAIL: todo_colors missing basic colors section"
    fi
    
    # Test usage instructions
    if [[ "$colors_output" == *"Usage:"* ]] && [[ "$colors_output" == *"export TODO_TASK_COLORS"* ]]; then
        echo "✅ PASS: todo_colors includes usage instructions"
    else
        echo "❌ FAIL: todo_colors missing usage instructions"
    fi
    
    # Test tips section
    if [[ "$colors_output" == *"Tips:"* ]] && [[ "$colors_output" == *"Test your colors:"* ]]; then
        echo "✅ PASS: todo_colors includes helpful tips"
    else
        echo "❌ FAIL: todo_colors missing helpful tips"
    fi
    
    # Test parameter handling (limited colors)
    limited_output=$(todo_colors 16 2>/dev/null)
    if [[ "$limited_output" != *"Extended Colors"* ]] || [[ $(echo "$limited_output" | grep -c "048\|049\|050") -eq 0 ]]; then
        echo "✅ PASS: todo_colors respects max_colors parameter"
    else
        echo "❌ FAIL: todo_colors doesn't respect max_colors parameter"
    fi
}

# Test 4: Command aliases
test_command_aliases() {
    echo "\n4. Testing command aliases:"
    
    # Test that aliases are defined (check with alias command)
    if alias todo_affirm >/dev/null 2>&1; then
        echo "✅ PASS: todo_affirm alias exists"
    else
        echo "❌ FAIL: todo_affirm alias not found"
    fi
    
    if alias todo_box >/dev/null 2>&1; then
        echo "✅ PASS: todo_box alias exists"
    else
        echo "❌ FAIL: todo_box alias not found"
    fi
    
    # Test that alias points to correct function (check alias definition)
    affirm_alias_def=$(alias todo_affirm 2>/dev/null | cut -d'=' -f2- | tr -d "'")
    if [[ "$affirm_alias_def" == "todo_toggle_affirmation" ]]; then
        echo "✅ PASS: todo_affirm alias points to correct function"
    else
        echo "❌ FAIL: todo_affirm alias definition incorrect (got: $affirm_alias_def)"
    fi
    
    box_alias_def=$(alias todo_box 2>/dev/null | cut -d'=' -f2- | tr -d "'")
    if [[ "$box_alias_def" == "todo_toggle_box" ]]; then
        echo "✅ PASS: todo_box alias points to correct function"
    else
        echo "❌ FAIL: todo_box alias definition incorrect (got: $box_alias_def)"
    fi
}

# Test 5: Error handling
test_error_handling() {
    echo "\n5. Testing error handling:"
    
    # Test toggle commands with invalid arguments
    local error_tests=(
        "todo_toggle_affirmation invalid_arg"
        "todo_toggle_box invalid_arg"
        "todo_toggle_all invalid_arg"
    )
    
    for test_cmd in "${error_tests[@]}"; do
        error_output=$(eval "$test_cmd" 2>&1)
        if [[ $? -ne 0 ]] && [[ "$error_output" == *"Usage:"* ]]; then
            echo "✅ PASS: $test_cmd produces proper error"
        else
            echo "❌ FAIL: $test_cmd doesn't produce proper error"
        fi
    done
    
    # Test that commands handle empty parameters gracefully (should default to toggle)
    original_state="$TODO_SHOW_AFFIRMATION"
    todo_toggle_affirmation "" >/dev/null 2>&1
    if [[ $? -eq 0 && "$TODO_SHOW_AFFIRMATION" != "$original_state" ]]; then
        echo "✅ PASS: Empty arguments default to toggle behavior"
        # Restore original state
        TODO_SHOW_AFFIRMATION="$original_state"
    else
        echo "❌ FAIL: Empty arguments don't default to toggle behavior"
    fi
}

# Test 6: State persistence
test_state_persistence() {
    echo "\n6. Testing state persistence:"
    
    # Test that toggle states persist across function calls
    original_affirmation="$TODO_SHOW_AFFIRMATION"
    original_box="$TODO_SHOW_TODO_BOX"
    
    # Change states
    todo_toggle_affirmation hide >/dev/null
    todo_toggle_box hide >/dev/null
    
    # Check that states are preserved
    if [[ "$TODO_SHOW_AFFIRMATION" == "false" && "$TODO_SHOW_TODO_BOX" == "false" ]]; then
        echo "✅ PASS: Toggle states persist correctly"
    else
        echo "❌ FAIL: Toggle states don't persist"
    fi
    
    # Test that states can be restored
    todo_toggle_affirmation show >/dev/null
    todo_toggle_box show >/dev/null
    
    if [[ "$TODO_SHOW_AFFIRMATION" == "true" && "$TODO_SHOW_TODO_BOX" == "true" ]]; then
        echo "✅ PASS: Toggle states can be restored"
    else
        echo "❌ FAIL: Toggle states can't be restored"
    fi
    
    # Restore original states
    TODO_SHOW_AFFIRMATION="$original_affirmation"
    TODO_SHOW_TODO_BOX="$original_box"
}

# Run all interface tests
main() {
    test_toggle_commands
    test_help_command
    test_colors_command
    test_command_aliases
    test_error_handling
    test_state_persistence
    
    echo "\n🎯 Interface Tests Completed"
    echo "════════════════════════════"
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "$0" == *"interface.zsh" ]]; then
    main "$@"
fi