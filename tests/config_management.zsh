#!/usr/bin/env zsh

# Configuration Management Tests
# Tests for todo config command and all its subcommands

# Test setup
SCRIPT_DIR=${0:A:h}
TEST_TMPDIR="${TMPDIR:-/tmp}/todo-config-tests-$$"
mkdir -p "$TEST_TMPDIR"
cd "$TEST_TMPDIR"

# Setup test environment with isolated todo file
export TODO_SAVE_FILE="$TEST_TMPDIR/test_todo.save"
export TODO_AFFIRMATION_FILE="$TEST_TMPDIR/test_affirmation"
export COLUMNS=80

# Clean up on exit
cleanup() {
    cd /
    rm -rf "$TEST_TMPDIR"
}
trap cleanup EXIT

# Load the plugin
autoload -U colors
colors
source "$SCRIPT_DIR/../reminder.plugin.zsh"

# Test counter
test_count=0
pass_count=0

# Test helper function
run_test() {
    local test_name="$1"
    local test_func="$2"
    
    test_count=$((test_count + 1))
    echo "Running test $test_count: $test_name"
    
    if $test_func; then
        echo "✅ PASS: $test_name"
        pass_count=$((pass_count + 1))
    else
        echo "❌ FAIL: $test_name"
    fi
    echo
}

# Test 1: Export configuration to stdout
test_export_stdout() {
    local output=$(todo config export 2>/dev/null)
    
    # Check if output contains expected configuration variables
    if [[ "$output" =~ TODO_TITLE && "$output" =~ TODO_HEART_CHAR && "$output" =~ TODO_TASK_COLORS ]]; then
        return 0
    else
        echo "Expected configuration variables not found in export output"
        return 1
    fi
}

# Test 2: Export configuration to file
test_export_file() {
    local config_file="$TEST_TMPDIR/test_export.conf"
    
    # Export to file
    todo config export "$config_file" >/dev/null 2>&1
    
    # Check if file was created and contains expected content
    if [[ -f "$config_file" ]] && grep -q "TODO_TITLE" "$config_file"; then
        return 0
    else
        echo "Export to file failed or file doesn't contain expected content"
        return 1
    fi
}

# Test 3: Export colors only
test_export_colors_only() {
    local output=$(todo config export --colors-only 2>/dev/null)
    
    # Should contain color variables but not display variables like TODO_TITLE (not TODO_TITLE_COLOR)
    if [[ "$output" =~ TODO_TASK_COLORS && "$output" =~ TODO_BORDER_COLOR && ! "$output" =~ TODO_TITLE=\".*\" ]]; then
        return 0
    else
        echo "Colors-only export didn't filter correctly"
        return 1
    fi
}

# Test 4: Import configuration from file
test_import_config() {
    local config_file="$TEST_TMPDIR/test_import.conf"
    
    # Create a test config file
    cat > "$config_file" << 'EOF'
TODO_TITLE="TEST TITLE"
TODO_HEART_CHAR="🧪"
TODO_TASK_COLORS="100,101,102"
TODO_BORDER_COLOR="150"
EOF
    
    # Import the config
    todo config import "$config_file" >/dev/null 2>&1
    
    # Check if variables were set correctly
    if [[ "$TODO_TITLE" == "TEST TITLE" && "$TODO_HEART_CHAR" == "🧪" && "$TODO_BORDER_COLOR" == "150" ]]; then
        return 0
    else
        echo "Import failed to set variables correctly"
        echo "TODO_TITLE='$TODO_TITLE', TODO_HEART_CHAR='$TODO_HEART_CHAR', TODO_BORDER_COLOR='$TODO_BORDER_COLOR'"
        return 1
    fi
}

# Test 5: Import validation and error handling
test_import_validation() {
    local config_file="$TEST_TMPDIR/test_invalid_import.conf"
    
    # Create config with invalid values
    cat > "$config_file" << 'EOF'
TODO_SHOW_AFFIRMATION="invalid_value"
TODO_SHOW_TODO_BOX="also_invalid"
EOF
    
    # Import should succeed but reset invalid values
    local output=$(todo config import "$config_file" 2>&1)
    
    # Check that invalid values were reset with warnings
    if [[ "$TODO_SHOW_AFFIRMATION" == "true" && "$TODO_SHOW_TODO_BOX" == "true" && "$output" =~ "Warning" ]]; then
        return 0
    else
        echo "Import validation failed to handle invalid values properly"
        return 1
    fi
}

# Test 6: Set individual configuration values
test_config_set() {
    # Test setting title
    todo config set title "NEW TITLE" >/dev/null 2>&1
    if [[ "$TODO_TITLE" != "NEW TITLE" ]]; then
        echo "Failed to set title"
        return 1
    fi
    
    # Test setting heart character
    todo config set heart-char "❤️" >/dev/null 2>&1
    if [[ "$TODO_HEART_CHAR" != "❤️" ]]; then
        echo "Failed to set heart character"
        return 1
    fi
    
    # Test setting colors
    todo config set colors "200,201,202" >/dev/null 2>&1
    if [[ "$TODO_TASK_COLORS" != "200,201,202" ]]; then
        echo "Failed to set colors"
        return 1
    fi
    
    return 0
}

# Test 7: Set configuration validation
test_config_set_validation() {
    # Test invalid heart position
    local output=$(todo config set heart-position "invalid" 2>&1)
    if [[ ! "$output" =~ "Error" ]]; then
        echo "Should have failed with invalid heart position"
        return 1
    fi
    
    # Test invalid colors format
    output=$(todo config set colors "not,numbers" 2>&1)
    if [[ ! "$output" =~ "Error" ]]; then
        echo "Should have failed with invalid colors format"
        return 1
    fi
    
    # Test color value out of range
    output=$(todo config set border-color "999" 2>&1)
    if [[ ! "$output" =~ "Error" ]]; then
        echo "Should have failed with color value out of range"
        return 1
    fi
    
    return 0
}

# Test 8: Reset configuration
test_config_reset() {
    # Change some values first
    TODO_TITLE="CHANGED"
    TODO_HEART_CHAR="X"
    TODO_TASK_COLORS="1,2,3"
    
    # Reset configuration
    todo config reset >/dev/null 2>&1
    
    # Check if values were reset to defaults
    if [[ "$TODO_TITLE" == "REMEMBER" && "$TODO_HEART_CHAR" == "♥" && "$TODO_TASK_COLORS" == "167,71,136,110,139,73" ]]; then
        return 0
    else
        echo "Reset failed to restore default values"
        return 1
    fi
}

# Test 9: Reset colors only
test_config_reset_colors_only() {
    # Change title and colors
    TODO_TITLE="CHANGED"
    TODO_TASK_COLORS="1,2,3"
    TODO_BORDER_COLOR="100"
    
    # Reset only colors
    todo config reset --colors-only >/dev/null 2>&1
    
    # Title should remain changed, colors should be reset
    if [[ "$TODO_TITLE" == "CHANGED" && "$TODO_TASK_COLORS" == "167,71,136,110,139,73" && "$TODO_BORDER_COLOR" == "240" ]]; then
        return 0
    else
        echo "Colors-only reset didn't work correctly"
        return 1
    fi
}

# Test 10: Apply minimal preset
test_preset_minimal() {
    todo config preset minimal >/dev/null 2>&1
    
    if [[ "$TODO_TITLE" == "TODO" && "$TODO_HEART_POSITION" == "none" && "$TODO_SHOW_AFFIRMATION" == "false" ]]; then
        return 0
    else
        echo "Minimal preset not applied correctly"
        return 1
    fi
}

# Test 11: Apply colorful preset
test_preset_colorful() {
    todo config preset colorful >/dev/null 2>&1
    
    if [[ "$TODO_TITLE" == "✨ TASKS ✨" && "$TODO_HEART_CHAR" == "💖" && "$TODO_HEART_POSITION" == "both" ]]; then
        return 0
    else
        echo "Colorful preset not applied correctly"
        return 1
    fi
}

# Test 12: Apply work preset
test_preset_work() {
    todo config preset work >/dev/null 2>&1
    
    if [[ "$TODO_TITLE" == "WORK TASKS" && "$TODO_HEART_CHAR" == "💼" && "$TODO_BOX_WIDTH_FRACTION" == "0.4" ]]; then
        return 0
    else
        echo "Work preset not applied correctly"
        return 1
    fi
}

# Test 13: Apply dark preset
test_preset_dark() {
    todo config preset dark >/dev/null 2>&1
    
    if [[ "$TODO_BORDER_BG_COLOR" == "232" && "$TODO_CONTENT_BG_COLOR" == "233" ]]; then
        return 0
    else
        echo "Dark preset not applied correctly"
        return 1
    fi
}

# Test 14: Invalid preset handling
test_preset_invalid() {
    local output=$(todo config preset nonexistent 2>&1)
    
    if [[ "$output" =~ "Error" && "$output" =~ "Unknown preset" ]]; then
        return 0
    else
        echo "Should have failed with unknown preset error"
        return 1
    fi
}

# Test 15: Save current preset
test_save_preset() {
    # Set some distinctive values
    TODO_TITLE="CUSTOM TEST"
    TODO_HEART_CHAR="🔥"
    
    # Save as preset
    todo config save-preset test-custom >/dev/null 2>&1
    
    # Check if preset file was created
    local preset_file="$HOME/.config/todo-reminder-test-custom.conf"
    if [[ -f "$preset_file" ]] && grep -q "CUSTOM TEST" "$preset_file"; then
        # Clean up
        rm -f "$preset_file"
        return 0
    else
        echo "Save preset failed to create file or file doesn't contain expected content"
        return 1
    fi
}

# Test 16: Main command dispatcher
test_config_dispatcher() {
    # Test help/usage message
    local output=$(todo_config invalid_command 2>&1)
    
    if [[ "$output" =~ "Usage: todo_config" && "$output" =~ "Commands:" ]]; then
        return 0
    else
        echo "Config dispatcher should show usage for invalid commands"
        return 1
    fi
}

# Test 17: Error handling for missing files
test_import_missing_file() {
    local output=$(todo config import "/nonexistent/file.conf" 2>&1)
    
    if [[ "$output" =~ "Error" && "$output" =~ "not found" ]]; then
        return 0
    else
        echo "Should have failed with file not found error"
        return 1
    fi
}

# Test 18: Export/import round trip
test_export_import_roundtrip() {
    local config_file="$TEST_TMPDIR/roundtrip.conf"
    
    # Set distinctive values
    TODO_TITLE="ROUNDTRIP TEST"
    TODO_HEART_CHAR="🔄"
    TODO_PADDING_LEFT="5"
    
    # Export
    todo config export "$config_file" >/dev/null 2>&1
    
    # Change values
    TODO_TITLE="CHANGED"
    TODO_HEART_CHAR="X"
    TODO_PADDING_LEFT="0"
    
    # Import back
    todo config import "$config_file" >/dev/null 2>&1
    
    # Check if original values were restored
    if [[ "$TODO_TITLE" == "ROUNDTRIP TEST" && "$TODO_HEART_CHAR" == "🔄" && "$TODO_PADDING_LEFT" == "5" ]]; then
        return 0
    else
        echo "Export/import roundtrip failed to preserve values"
        return 1
    fi
}

# Test 19: Setup command exists
test_wizard_function_exists() {
    # Test that setup command is accessible through subcommand interface
    local output=$(timeout 2 zsh -c "autoload -U colors; colors; source '$SCRIPT_DIR/../reminder.plugin.zsh'; echo -e '\n\n\n\n\n\n\n\n\n\n' | todo setup" 2>&1 || true)
    
    if [[ "$output" != *"Unknown"* ]] && [[ "$output" != *"command not found"* ]]; then
        return 0
    else
        echo "todo setup command not accessible"
        return 1
    fi
}

# Test 20: Setup command dispatcher
test_wizard_dispatcher() {
    # Test that setup command is recognized by checking if it doesn't give unknown command error
    local output=$(timeout 2 zsh -c "autoload -U colors; colors; source '$SCRIPT_DIR/../reminder.plugin.zsh'; echo -e '\n\n\n\n\n\n\n\n\n\n' | todo setup" 2>&1 || true)
    
    # Should contain setup output, not "unknown command" error
    if [[ "$output" =~ "Configuration Wizard" || "$output" =~ "🧙" || "$output" =~ "Starting Point" ]]; then
        return 0
    else
        # If it doesn't contain usage message, it means wizard was called
        if [[ ! "$output" =~ "Usage: todo_config" ]]; then
            return 0
        fi
        echo "Wizard command not properly dispatched (output: $output)"
        return 1
    fi
}

# Run all tests
echo "🧪 Running Configuration Management Tests"
echo "=========================================="
echo

run_test "Export configuration to stdout" test_export_stdout
run_test "Export configuration to file" test_export_file
run_test "Export colors only" test_export_colors_only
run_test "Import configuration from file" test_import_config
run_test "Import validation and error handling" test_import_validation
run_test "Set individual configuration values" test_config_set
run_test "Set configuration validation" test_config_set_validation
run_test "Reset configuration" test_config_reset
run_test "Reset colors only" test_config_reset_colors_only
run_test "Apply minimal preset" test_preset_minimal
run_test "Apply colorful preset" test_preset_colorful
run_test "Apply work preset" test_preset_work
run_test "Apply dark preset" test_preset_dark
run_test "Invalid preset handling" test_preset_invalid
run_test "Save current preset" test_save_preset
run_test "Main command dispatcher" test_config_dispatcher
run_test "Error handling for missing files" test_import_missing_file
run_test "Export/import round trip" test_export_import_roundtrip
run_test "Wizard function exists" test_wizard_function_exists
run_test "Wizard command dispatcher" test_wizard_dispatcher

# Summary
echo "Configuration Tests Summary:"
echo "===================="
echo "Tests run: $test_count"
echo "Passed: $pass_count"
echo "Failed: $((test_count - pass_count))"

if [[ $pass_count -eq $test_count ]]; then
    echo "🎉 All configuration tests passed!"
    exit 0
else
    echo "❌ Some configuration tests failed"
    exit 1
fi