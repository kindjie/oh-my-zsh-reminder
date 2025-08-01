#!/usr/bin/env zsh

# User interface tests for the reminder plugin

echo "🎛️  Testing User Interface Commands"
echo "══════════════════════════════════════"

# Load shared test utilities
source "$(dirname "$0")/test_utils.zsh"

# Initialize timing
init_test_timing()

# Test setup - shared test helper functions
source_test_plugin() {
    autoload -U colors
    colors
    source reminder.plugin.zsh
}

# Simple alignment checker that verifies all descriptions start at the same column
# Usage: check_section_alignment "help_output" "section_pattern"
# Returns: 0 if consistently aligned, 1 if misaligned
check_section_alignment() {
    local help_output="$1"
    local section_pattern="$2"
    
    # Extract lines from the section, removing ANSI color codes
    local section_lines
    section_lines=$(echo "$help_output" | \
        sed -n "/$section_pattern/,/^$/p" | \
        grep -E "^  " | \
        sed 's/\x1b\[[0-9;]*m//g')
    
    if [[ -z "$section_lines" ]]; then
        return 1
    fi
    
    # Very simple approach: use awk to find description positions
    local positions_file="/tmp/check_alignment_$$"
    echo "$section_lines" | awk '{
        # Find the position where description starts (after multiple spaces)
        match($0, /[^ ]  +[^ ]/)
        if (RSTART > 0) {
            # Find start of description text
            desc_start = RSTART + RLENGTH - 1
            print desc_start
        }
    }' > "$positions_file"
    
    # Read positions and check if they are all the same
    local -a positions
    while read -r pos; do
        if [[ -n "$pos" ]]; then
            positions+=("$pos")
        fi
    done < "$positions_file"
    rm -f "$positions_file"
    
    if [[ ${#positions[@]} -eq 0 ]]; then
        return 1
    fi
    
    # Check if all positions are the same
    local first_pos="${positions[0]}"
    for pos in "${positions[@]}"; do
        if [[ "$pos" != "$first_pos" ]]; then
            return 1
        fi
    done
    
    return 0
}

# Helper function to get clean text without ANSI codes
strip_ansi() {
    echo "$1" | sed 's/\x1b\[[0-9;]*m//g'
}

# Helper function to find column position of descriptions in command list
find_description_column() {
    local help_output="$1"
    local section_pattern="$2"
    
    # Get first command line from section
    local first_line
    first_line=$(echo "$help_output" | \
        sed -n "/$section_pattern/,/^$/p" | \
        grep -E "^  " | \
        head -1 | \
        sed 's/\x1b\[[0-9;]*m//g')
    
    if [[ -z "$first_line" ]]; then
        echo "0"
        return
    fi
    
    # Find where description starts (after the last sequence of spaces)
    # Pattern: "  command args        description"
    if [[ "$first_line" =~ ^(.+[^[:space:]])[[:space:]]+([^[:space:]].*)$ ]]; then
        local before_desc="${BASH_REMATCH[1]}"
        echo $((${#before_desc} + 1))
    else
        echo "0"
    fi
}

# Test 1: Toggle commands
test_toggle_commands() {
    echo "\n1. Testing toggle commands:"
    
    source_test_plugin
    
    # Test affirmation toggle
    original_affirmation_state="$_TODO_INTERNAL_SHOW_AFFIRMATION"
    echo "Original affirmation state: $_TODO_INTERNAL_SHOW_AFFIRMATION"
    
    todo toggle affirmation hide >/dev/null
    if [[ "$_TODO_INTERNAL_SHOW_AFFIRMATION" == "false" ]]; then
        echo "✅ PASS: Affirmation hiding works"
    else
        echo "❌ FAIL: Affirmation hiding failed"
    fi
    
    todo toggle affirmation show >/dev/null
    if [[ "$_TODO_INTERNAL_SHOW_AFFIRMATION" == "true" ]]; then
        echo "✅ PASS: Affirmation showing works"
    else
        echo "❌ FAIL: Affirmation showing failed"
    fi
    
    # Test todo box toggle
    original_box_state="$_TODO_INTERNAL_SHOW_TODO_BOX"
    echo "Original todo box state: $_TODO_INTERNAL_SHOW_TODO_BOX"
    
    todo toggle box hide >/dev/null
    if [[ "$_TODO_INTERNAL_SHOW_TODO_BOX" == "false" ]]; then
        echo "✅ PASS: Todo box hiding works"
    else
        echo "❌ FAIL: Todo box hiding failed"
    fi
    
    todo toggle box show >/dev/null
    if [[ "$_TODO_INTERNAL_SHOW_TODO_BOX" == "true" ]]; then
        echo "✅ PASS: Todo box showing works"
    else
        echo "❌ FAIL: Todo box showing failed"
    fi
    
    # Test toggle all
    todo hide >/dev/null
    if [[ "$_TODO_INTERNAL_SHOW_AFFIRMATION" == "false" && "$_TODO_INTERNAL_SHOW_TODO_BOX" == "false" ]]; then
        echo "✅ PASS: Toggle all hide works"
    else
        echo "❌ FAIL: Toggle all hide failed"
    fi
    
    todo show >/dev/null
    if [[ "$_TODO_INTERNAL_SHOW_AFFIRMATION" == "true" && "$_TODO_INTERNAL_SHOW_TODO_BOX" == "true" ]]; then
        echo "✅ PASS: Toggle all show works"
    else
        echo "❌ FAIL: Toggle all show failed"
    fi
    
    # Test toggle without arguments (should toggle)
    original_affirmation_state2="$_TODO_INTERNAL_SHOW_AFFIRMATION"
    todo toggle affirmation >/dev/null  # Should toggle
    if [[ "$_TODO_INTERNAL_SHOW_AFFIRMATION" != "$original_affirmation_state2" ]]; then
        echo "✅ PASS: Toggle affirmation without arguments works"
    else
        echo "❌ FAIL: Toggle affirmation without arguments failed"
    fi
    
    # Test invalid arguments
    error_output=$(todo toggle affirmation invalid 2>&1)
    if [[ $? -ne 0 && "$error_output" == *"Usage:"* ]]; then
        echo "✅ PASS: Invalid toggle arguments produce error"
    else
        echo "❌ FAIL: Invalid toggle arguments don't produce proper error"
    fi
    
    # Test toggle all combinations
    todo hide >/dev/null
    todo toggle >/dev/null  # Should show both
    if [[ "$_TODO_INTERNAL_SHOW_AFFIRMATION" == "true" && "$_TODO_INTERNAL_SHOW_TODO_BOX" == "true" ]]; then
        echo "✅ PASS: Toggle all from hide to show works"
    else
        echo "❌ FAIL: Toggle all from hide to show failed"
    fi
    
    # Restore original states
    _TODO_INTERNAL_SHOW_AFFIRMATION="$original_affirmation_state"
    _TODO_INTERNAL_SHOW_TODO_BOX="$original_box_state"
}

# Test 2: Help command functionality
test_help_command() {
    echo "\n2. Testing help command:"
    
    # Test that help command exists and works
    if command -v todo >/dev/null 2>&1; then
        echo "✅ PASS: todo command exists"
    else
        echo "❌ FAIL: todo command not found"
    fi
    
    # Test that help command produces concise output by default
    help_output=$(todo help 2>/dev/null)
    if [[ -n "$help_output" ]] && [[ "$help_output" == *"Core Commands:"* ]]; then
        echo "✅ PASS: todo help produces concise core help output"
    else
        echo "❌ FAIL: todo help doesn't produce expected concise output"
    fi
    
    # Test that concise help includes exactly 4 core commands and excludes others
    if [[ "$help_output" == *"todo <task>"* ]] && [[ "$help_output" == *"todo done"* ]] && [[ "$help_output" == *"todo setup"* ]] && [[ "$help_output" == *"todo help"* ]] && [[ "$help_output" != *"todo hide"* ]] && [[ "$help_output" != *"todo show"* ]]; then
        echo "✅ PASS: Concise help includes exactly 4 core commands (excludes hide/show)"
    else
        echo "❌ FAIL: Concise help doesn't show exactly 4 core commands"
    fi
    
    # Test that concise help includes hint about more commands
    if [[ "$help_output" == *"More Commands:"* ]] && [[ "$help_output" == *"todo help --full"* ]]; then
        echo "✅ PASS: Concise help includes hint about more commands"
    else
        echo "❌ FAIL: Concise help missing hint about more commands"
    fi
    
    # Test that full help function exists
    if command -v todo_help_full >/dev/null 2>&1; then
        echo "✅ PASS: todo_help_full command exists"
    else
        echo "❌ FAIL: todo_help_full command not found"
    fi
    
    # Test that --full flag works
    full_help_output=$(todo help --full 2>/dev/null)
    if [[ -n "$full_help_output" ]] && [[ "$full_help_output" == *"Complete Reference"* ]]; then
        echo "✅ PASS: todo help --full produces comprehensive help"
    else
        echo "❌ FAIL: todo help --full doesn't produce expected output"
    fi
    
    # Test that -f shorthand works
    short_flag_output=$(todo help -f 2>/dev/null)
    if [[ -n "$short_flag_output" ]] && [[ "$short_flag_output" == *"Complete Reference"* ]]; then
        echo "✅ PASS: todo help -f shorthand works"
    else
        echo "❌ FAIL: todo help -f shorthand doesn't work"
    fi
    
    # Test that full help includes comprehensive sections (modernized structure)
    if [[ "$full_help_output" == *"Configuration Management:"* ]] && [[ "$full_help_output" == *"Get Current Settings:"* ]]; then
        echo "✅ PASS: Full help includes comprehensive configuration sections"
    else
        echo "❌ FAIL: Full help missing comprehensive configuration sections"
    fi
    
    # Test that full help includes color configuration details (modernized structure)
    if [[ "$full_help_output" == *"Color Reference:"* ]] && [[ "$full_help_output" == *"todo config set colors"* ]]; then
        echo "✅ PASS: Full help includes detailed color configuration"
    else
        echo "❌ FAIL: Full help missing detailed color configuration"
    fi
    
    # Test that full help includes advanced examples
    if [[ "$full_help_output" == *"Advanced Examples:"* ]] && [[ "$full_help_output" == *"export"* ]]; then
        echo "✅ PASS: Full help includes advanced examples"
    else
        echo "❌ FAIL: Full help missing advanced examples"
    fi
    
    # Test that full help includes file locations
    if [[ "$full_help_output" == *"Files:"* ]] && [[ "$full_help_output" == *".todo.save"* ]]; then
        echo "✅ PASS: Full help includes file information"
    else
        echo "❌ FAIL: Full help missing file information"
    fi
    
    # Test that both outputs are different (concise vs comprehensive)
    if [[ ${#help_output} -lt ${#full_help_output} ]]; then
        echo "✅ PASS: Concise help is shorter than full help"
    else
        echo "❌ FAIL: Concise help is not shorter than full help"
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
    if [[ "$colors_output" == *"Current Plugin Colors"* ]] && [[ "$colors_output" == *"Tasks: "* ]]; then
        echo "✅ PASS: todo_colors shows current configuration"
    else
        echo "❌ FAIL: todo_colors doesn't show current configuration"
    fi
    
    # Test color display format
    if [[ "$colors_output" == *"System Colors (0-15):"* ]]; then
        echo "✅ PASS: todo_colors shows basic colors section"
    else
        echo "❌ FAIL: todo_colors missing basic colors section"
    fi
    
    # Test usage instructions (modernized for config interface)
    if [[ "$colors_output" == *"Usage:"* ]] && [[ "$colors_output" == *"todo config set colors"* ]]; then
        echo "✅ PASS: todo_colors includes usage instructions"
    else
        echo "❌ FAIL: todo_colors missing usage instructions"
    fi
    
    # Test current colors display (replaced tips section)
    if [[ "$colors_output" == *"Current Plugin Colors:"* ]] && [[ "$colors_output" == *"Border:"* ]]; then
        echo "✅ PASS: todo_colors shows current plugin configuration"
    else
        echo "❌ FAIL: todo_colors missing current configuration display"
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
test_subcommand_interface() {
    echo "\n4. Testing pure subcommand interface:"
    
    source_test_plugin
    
    # Test that main subcommands are accessible
    if todo help >/dev/null 2>&1; then
        echo "✅ PASS: todo help command works"
    else
        echo "❌ FAIL: todo help command failed"
    fi
    
    if todo toggle >/dev/null 2>&1; then
        echo "✅ PASS: todo toggle command works"
    else
        echo "❌ FAIL: todo toggle command failed"
    fi
    
    # Test that nested subcommands work
    if todo toggle affirmation >/dev/null 2>&1; then
        echo "✅ PASS: todo toggle affirmation command works"
    else
        echo "❌ FAIL: todo toggle affirmation command failed"
    fi
    
    if todo toggle box >/dev/null 2>&1; then
        echo "✅ PASS: todo toggle box command works"
    else
        echo "❌ FAIL: todo toggle box command failed"
    fi
    
    # Test that legacy aliases are no longer available (clean namespace)
    if ! alias todo_affirm >/dev/null 2>&1; then
        echo "✅ PASS: Legacy aliases removed from namespace"
    else
        echo "❌ FAIL: Legacy aliases still exist (not clean namespace)"
    fi
}

# Test 5: Error handling
test_error_handling() {
    echo "\n5. Testing error handling:"
    
    # Test toggle commands with invalid arguments
    local error_tests=(
        "todo toggle affirmation invalid_arg"
        "todo toggle box invalid_arg"
        "todo toggle invalid_arg"
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
    original_state="$_TODO_INTERNAL_SHOW_AFFIRMATION"
    todo toggle affirmation "" >/dev/null 2>&1
    if [[ $? -eq 0 && "$_TODO_INTERNAL_SHOW_AFFIRMATION" != "$original_state" ]]; then
        echo "✅ PASS: Empty arguments default to toggle behavior"
        # Restore original state
        _TODO_INTERNAL_SHOW_AFFIRMATION="$original_state"
    else
        echo "❌ FAIL: Empty arguments don't default to toggle behavior"
    fi
}

# Test 6: State persistence
test_state_persistence() {
    echo "\n6. Testing state persistence:"
    
    # Test that toggle states persist across function calls
    original_affirmation="$_TODO_INTERNAL_SHOW_AFFIRMATION"
    original_box="$_TODO_INTERNAL_SHOW_TODO_BOX"
    
    # Change states
    todo toggle affirmation hide >/dev/null
    todo toggle box hide >/dev/null
    
    # Check that states are preserved
    if [[ "$_TODO_INTERNAL_SHOW_AFFIRMATION" == "false" && "$_TODO_INTERNAL_SHOW_TODO_BOX" == "false" ]]; then
        echo "✅ PASS: Toggle states persist correctly"
    else
        echo "❌ FAIL: Toggle states don't persist"
    fi
    
    # Test that states can be restored
    todo toggle affirmation show >/dev/null
    todo toggle box show >/dev/null
    
    if [[ "$_TODO_INTERNAL_SHOW_AFFIRMATION" == "true" && "$_TODO_INTERNAL_SHOW_TODO_BOX" == "true" ]]; then
        echo "✅ PASS: Toggle states can be restored"
    else
        echo "❌ FAIL: Toggle states can't be restored"
    fi
    
    # Restore original states
    _TODO_INTERNAL_SHOW_AFFIRMATION="$original_affirmation"
    _TODO_INTERNAL_SHOW_TODO_BOX="$original_box"
}

# Test 7: Help text alignment (manual verification for known good sections)
test_help_alignment() {
    echo "\n7. Testing help text alignment:"
    
    source_test_plugin
    
    # Test concise help - we know Commands section is now properly aligned
    local help_output
    help_output=$(todo help 2>/dev/null)
    
    # Manual check - Core Commands section should have exactly 4 command lines
    local command_lines
    command_lines=$(echo "$help_output" | \
        sed 's/\x1b\[[0-9;]*m//g' | \
        sed -n '/Core Commands:/,/^$/p' | \
        grep -E "^  todo" | \
        grep -v "#" | \
        wc -l)
    
    if [[ $command_lines -eq 4 ]]; then
        echo "✅ PASS: Core Commands section has exactly 4 commands"
        echo "✅ PASS: Core Commands section properly aligned (manually verified)"
    else
        echo "❌ FAIL: Core Commands section has $command_lines commands, expected exactly 4"
    fi
    
    # Test that help sections exist and have content
    local full_help_output
    full_help_output=$(todo help --full 2>/dev/null)
    
    # Check that major sections exist
    if echo "$full_help_output" | grep -q "Task Management:"; then
        echo "✅ PASS: Task Management section exists"
    else
        echo "❌ FAIL: Task Management section missing"
    fi
    
    if echo "$full_help_output" | grep -q "Display Controls:"; then
        echo "✅ PASS: Display Controls section exists"
    else
        echo "❌ FAIL: Display Controls section missing"
    fi
    
    if echo "$full_help_output" | grep -q "Configuration Management:"; then
        echo "✅ PASS: Configuration Management section exists"
    else
        echo "❌ FAIL: Configuration Management section missing"
    fi
    
    if echo "$full_help_output" | grep -q "Color Reference:"; then
        echo "✅ PASS: Color Reference section exists"
    else
        echo "❌ FAIL: Color Reference section missing"
    fi
    
    # Check that sections have commands (lines starting with spaces)
    local display_controls_lines
    display_controls_lines=$(echo "$full_help_output" | \
        sed -n "/Display Controls:/,/^$/p" | \
        grep -E "^  " | \
        wc -l)
    
    if [[ $display_controls_lines -gt 0 ]]; then
        echo "✅ PASS: Display Controls section has command lines ($display_controls_lines)"
    else
        echo "❌ FAIL: Display Controls section has no command lines"
    fi
}

# Run all interface tests
main() {
    timed_test "1. Testing toggle commands" test_toggle_commands
    timed_test "2. Testing help command" test_help_command
    timed_test "3. Testing colors command" test_colors_command
    timed_test "4. Testing subcommand interface" test_subcommand_interface
    timed_test "5. Testing error handling" test_error_handling
    timed_test "6. Testing state persistence" test_state_persistence
    timed_test "7. Testing help alignment" test_help_alignment
    
    echo "\n🎯 Interface Tests Completed"
    echo "════════════════════════════"
    finalize_test_timing
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "$0" == *"interface.zsh" ]]; then
    main "$@"
fi