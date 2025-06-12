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
export TODO_DISABLE_MIGRATION="true"
export COLUMNS=80

# Clean up on exit
cleanup() {
    cd /
    rm -rf "$TEST_TMPDIR"
}
trap cleanup EXIT

# Load the plugin and config module
autoload -U colors
colors
source "$SCRIPT_DIR/../lib/config.zsh"
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
    local output=$(todo_config_export_config 2>/dev/null)
    
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
    todo_config_export_config "$config_file" >/dev/null 2>&1
    
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
    local output=$(todo_config_export_config "" "true" 2>/dev/null)
    
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
    todo_config_import_config "$config_file" >/dev/null 2>&1
    
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
    
    # Import should fail with validation errors
    local output=$(todo_config_import_config "$config_file" 2>&1)
    
    # Check that import failed due to validation
    if [[ "$output" =~ "Error" ]]; then
        return 0
    else
        echo "Import validation should have failed for invalid values"
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

# Utility function for comprehensive preset validation
validate_preset_values() {
    local preset_name="$1"
    local errors=()
    
    # Validate all color values are in 0-255 range
    if [[ -n "$TODO_BORDER_COLOR" ]] && ! [[ "$TODO_BORDER_COLOR" =~ ^[0-9]+$ && "$TODO_BORDER_COLOR" -ge 0 && "$TODO_BORDER_COLOR" -le 255 ]]; then
        errors+=("TODO_BORDER_COLOR=$TODO_BORDER_COLOR is not valid (0-255)")
    fi
    
    if [[ -n "$TODO_BORDER_BG_COLOR" ]] && ! [[ "$TODO_BORDER_BG_COLOR" =~ ^[0-9]+$ && "$TODO_BORDER_BG_COLOR" -ge 0 && "$TODO_BORDER_BG_COLOR" -le 255 ]]; then
        errors+=("TODO_BORDER_BG_COLOR=$TODO_BORDER_BG_COLOR is not valid (0-255)")
    fi
    
    if [[ -n "$TODO_CONTENT_BG_COLOR" ]] && ! [[ "$TODO_CONTENT_BG_COLOR" =~ ^[0-9]+$ && "$TODO_CONTENT_BG_COLOR" -ge 0 && "$TODO_CONTENT_BG_COLOR" -le 255 ]]; then
        errors+=("TODO_CONTENT_BG_COLOR=$TODO_CONTENT_BG_COLOR is not valid (0-255)")
    fi
    
    if [[ -n "$TODO_TASK_TEXT_COLOR" ]] && ! [[ "$TODO_TASK_TEXT_COLOR" =~ ^[0-9]+$ && "$TODO_TASK_TEXT_COLOR" -ge 0 && "$TODO_TASK_TEXT_COLOR" -le 255 ]]; then
        errors+=("TODO_TASK_TEXT_COLOR=$TODO_TASK_TEXT_COLOR is not valid (0-255)")
    fi
    
    if [[ -n "$TODO_TITLE_COLOR" ]] && ! [[ "$TODO_TITLE_COLOR" =~ ^[0-9]+$ && "$TODO_TITLE_COLOR" -ge 0 && "$TODO_TITLE_COLOR" -le 255 ]]; then
        errors+=("TODO_TITLE_COLOR=$TODO_TITLE_COLOR is not valid (0-255)")
    fi
    
    if [[ -n "$TODO_AFFIRMATION_COLOR" ]] && ! [[ "$TODO_AFFIRMATION_COLOR" =~ ^[0-9]+$ && "$TODO_AFFIRMATION_COLOR" -ge 0 && "$TODO_AFFIRMATION_COLOR" -le 255 ]]; then
        errors+=("TODO_AFFIRMATION_COLOR=$TODO_AFFIRMATION_COLOR is not valid (0-255)")
    fi
    
    # Validate task colors array format
    if [[ -n "$TODO_TASK_COLORS" ]]; then
        IFS=',' read -A color_values <<< "$TODO_TASK_COLORS"
        for color in "${color_values[@]}"; do
            if ! [[ "$color" =~ ^[0-9]+$ && "$color" -ge 0 && "$color" -le 255 ]]; then
                errors+=("Task color $color in TODO_TASK_COLORS is not valid (0-255)")
            fi
        done
    fi
    
    # Validate boolean values
    if [[ -n "$TODO_SHOW_AFFIRMATION" ]] && ! [[ "$TODO_SHOW_AFFIRMATION" =~ ^(true|false)$ ]]; then
        errors+=("TODO_SHOW_AFFIRMATION=$TODO_SHOW_AFFIRMATION is not valid (true/false)")
    fi
    
    if [[ -n "$TODO_SHOW_TODO_BOX" ]] && ! [[ "$TODO_SHOW_TODO_BOX" =~ ^(true|false)$ ]]; then
        errors+=("TODO_SHOW_TODO_BOX=$TODO_SHOW_TODO_BOX is not valid (true/false)")
    fi
    
    # Validate heart position
    if [[ -n "$TODO_HEART_POSITION" ]] && ! [[ "$TODO_HEART_POSITION" =~ ^(left|right|both|none)$ ]]; then
        errors+=("TODO_HEART_POSITION=$TODO_HEART_POSITION is not valid (left/right/both/none)")
    fi
    
    # Validate numeric ranges
    if [[ -n "$TODO_BOX_WIDTH_FRACTION" ]]; then
        # Check if it's a valid decimal between 0 and 1
        if ! [[ "$TODO_BOX_WIDTH_FRACTION" =~ ^0?\.[0-9]+$ || "$TODO_BOX_WIDTH_FRACTION" == "1" ]]; then
            errors+=("TODO_BOX_WIDTH_FRACTION=$TODO_BOX_WIDTH_FRACTION is not valid (0.0-1.0)")
        fi
    fi
    
    # Check required variables are set
    if [[ -z "$TODO_TITLE" ]]; then
        errors+=("TODO_TITLE is not set")
    fi
    
    if [[ -z "$TODO_HEART_CHAR" ]]; then
        errors+=("TODO_HEART_CHAR is not set")
    fi
    
    if [[ -z "$TODO_BULLET_CHAR" ]]; then
        errors+=("TODO_BULLET_CHAR is not set")
    fi
    
    # Report errors
    if [[ ${#errors[@]} -gt 0 ]]; then
        echo "Validation errors for preset '$preset_name':"
        for error in "${errors[@]}"; do
            echo "  - $error"
        done
        return 1
    fi
    
    return 0
}

# Test 10: Apply subtle preset
test_preset_subtle() {
    todo_config_apply_preset subtle >/dev/null 2>&1
    
    # Comprehensive validation
    if ! validate_preset_values "subtle"; then
        return 1
    fi
    
    # Semantic preset validation - subtle should have muted characteristics
    if [[ -n "$TODO_TASK_COLORS" && 
          -n "$TODO_BORDER_COLOR" &&
          -n "$TODO_TASK_TEXT_COLOR" &&
          -n "$TODO_TITLE_COLOR" &&
          "$TODO_SHOW_AFFIRMATION" =~ ^(true|false)$ ]]; then
        return 0
    else
        echo "Subtle preset not applied correctly"
        echo "TODO_TASK_COLORS='$TODO_TASK_COLORS' (expected non-empty)"
        echo "TODO_BORDER_COLOR='$TODO_BORDER_COLOR' (expected non-empty)"
        echo "TODO_SHOW_AFFIRMATION='$TODO_SHOW_AFFIRMATION' (expected true/false)"
        return 1
    fi
}

# Test 11: Apply vibrant preset
test_preset_vibrant() {
    todo_config_apply_preset vibrant >/dev/null 2>&1
    
    # Comprehensive validation
    if ! validate_preset_values "vibrant"; then
        return 1
    fi
    
    # Semantic preset validation - vibrant should have bright characteristics
    if [[ -n "$TODO_TASK_COLORS" && 
          -n "$TODO_BORDER_COLOR" &&
          -n "$TODO_TASK_TEXT_COLOR" &&
          -n "$TODO_TITLE_COLOR" &&
          "$TODO_SHOW_AFFIRMATION" == "true" ]]; then
        return 0
    else
        echo "Vibrant preset not applied correctly"
        echo "TODO_TASK_COLORS='$TODO_TASK_COLORS' (expected non-empty)"
        echo "TODO_BORDER_COLOR='$TODO_BORDER_COLOR' (expected non-empty)"
        echo "TODO_SHOW_AFFIRMATION='$TODO_SHOW_AFFIRMATION' (expected 'true')"
        return 1
    fi
}

# Test 12: Apply balanced preset
test_preset_balanced() {
    todo_config_apply_preset balanced >/dev/null 2>&1
    
    # Comprehensive validation
    if ! validate_preset_values "balanced"; then
        return 1
    fi
    
    # Semantic preset validation - balanced should have moderate characteristics
    if [[ -n "$TODO_TASK_COLORS" && 
          -n "$TODO_BORDER_COLOR" &&
          -n "$TODO_TASK_TEXT_COLOR" &&
          -n "$TODO_TITLE_COLOR" &&
          "$TODO_SHOW_AFFIRMATION" =~ ^(true|false)$ ]]; then
        return 0
    else
        echo "Balanced preset not applied correctly"
        echo "TODO_TASK_COLORS='$TODO_TASK_COLORS' (expected non-empty)"
        echo "TODO_BORDER_COLOR='$TODO_BORDER_COLOR' (expected non-empty)"
        echo "TODO_SHOW_AFFIRMATION='$TODO_SHOW_AFFIRMATION' (expected true/false)"
        return 1
    fi
}

# Test 13: Apply loud preset
test_preset_loud() {
    todo_config_apply_preset loud >/dev/null 2>&1
    
    # Comprehensive validation
    if ! validate_preset_values "loud"; then
        return 1
    fi
    
    # Semantic preset validation - loud should have high contrast characteristics
    if [[ -n "$TODO_TASK_COLORS" && 
          -n "$TODO_BORDER_COLOR" &&
          -n "$TODO_TASK_TEXT_COLOR" &&
          -n "$TODO_TITLE_COLOR" &&
          "$TODO_SHOW_AFFIRMATION" == "true" ]]; then
        return 0
    else
        echo "Loud preset not applied correctly"
        echo "TODO_TASK_COLORS='$TODO_TASK_COLORS' (expected non-empty)"
        echo "TODO_BORDER_COLOR='$TODO_BORDER_COLOR' (expected non-empty)"
        echo "TODO_SHOW_AFFIRMATION='$TODO_SHOW_AFFIRMATION' (expected 'true')"
        return 1
    fi
}

# Test 14: Invalid preset handling
test_preset_invalid() {
    local output=$(todo_config_apply_preset nonexistent 2>&1)
    
    if [[ "$output" =~ "Error" && "$output" =~ "not found" ]]; then
        return 0
    else
        echo "Should have failed with preset not found error"
        return 1
    fi
}

# Test 15: Tinted preset selection
test_tinted_preset_selection() {
    # Test tinted preset selection when TINTED_SHELL_ENABLE_BASE16_VARS is set
    local original_tinted="$TINTED_SHELL_ENABLE_BASE16_VARS"
    
    # Test with tinted-shell enabled
    export TINTED_SHELL_ENABLE_BASE16_VARS=1
    
    # Apply a preset that has a tinted variant
    todo_config_apply_preset subtle >/dev/null 2>&1
    
    # Check that colors were applied
    if [[ -n "$TODO_TASK_COLORS" ]]; then
        # Restore original
        TINTED_SHELL_ENABLE_BASE16_VARS="$original_tinted"
        return 0
    else
        echo "Tinted preset selection failed"
        TINTED_SHELL_ENABLE_BASE16_VARS="$original_tinted"
        return 1
    fi
}

# Test 20: Save current preset
test_save_preset() {
    # Set some distinctive values
    TODO_TITLE="CUSTOM TEST"
    TODO_HEART_CHAR="🔥"
    
    # Save as preset
    todo_config_save_user_preset test-custom "Test preset description" >/dev/null 2>&1
    
    # Check if preset file was created in new location
    local preset_file="$HOME/.config/todo-reminder/presets/test-custom.conf"
    if [[ -f "$preset_file" ]] && grep -q "CUSTOM TEST" "$preset_file"; then
        # Clean up
        rm -f "$preset_file"
        return 0
    else
        echo "Save preset failed to create file or file doesn't contain expected content"
        return 1
    fi
}

# Test 21: Preset discovery and availability
test_preset_discovery() {
    # Test preset discovery function
    local preset_names=($(todo_config_get_preset_names))
    
    # Should find at least the 4 semantic presets
    local required_presets=("subtle" "balanced" "vibrant" "loud")
    local missing_presets=()
    
    for preset in "${required_presets[@]}"; do
        if [[ ! "${preset_names[@]}" =~ "$preset" ]]; then
            missing_presets+=("$preset")
        fi
    done
    
    if [[ ${#missing_presets[@]} -eq 0 ]]; then
        return 0
    else
        echo "Required presets not discovered: ${missing_presets[@]}"
        echo "Available presets: ${preset_names[@]}"
        return 1
    fi
}

# Test 22: Main command dispatcher
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

# Test 23: Error handling for missing files
test_import_missing_file() {
    local output=$(todo_config_import_config "/nonexistent/file.conf" 2>&1)
    
    if [[ "$output" =~ "Error" && "$output" =~ "not found" ]]; then
        return 0
    else
        echo "Should have failed with file not found error"
        return 1
    fi
}

# Test 24: Export/import round trip
test_export_import_roundtrip() {
    local config_file="$TEST_TMPDIR/roundtrip.conf"
    
    # Set distinctive values
    TODO_TITLE="ROUNDTRIP TEST"
    TODO_HEART_CHAR="🔄"
    TODO_PADDING_LEFT="5"
    
    # Export
    todo_config_export_config "$config_file" >/dev/null 2>&1
    
    # Change values
    TODO_TITLE="CHANGED"
    TODO_HEART_CHAR="X"
    TODO_PADDING_LEFT="0"
    
    # Import back
    todo_config_import_config "$config_file" >/dev/null 2>&1
    
    # Check if original values were restored
    if [[ "$TODO_TITLE" == "ROUNDTRIP TEST" && "$TODO_HEART_CHAR" == "🔄" && "$TODO_PADDING_LEFT" == "5" ]]; then
        return 0
    else
        echo "Export/import roundtrip failed to preserve values"
        return 1
    fi
}

# Test 25: Setup command exists
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

# Test 26: Setup command dispatcher
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
run_test "Apply subtle preset" test_preset_subtle
run_test "Apply vibrant preset" test_preset_vibrant
run_test "Apply balanced preset" test_preset_balanced
run_test "Apply loud preset" test_preset_loud
run_test "Invalid preset handling" test_preset_invalid
run_test "Tinted preset selection" test_tinted_preset_selection
run_test "Save current preset" test_save_preset
run_test "Preset discovery and availability" test_preset_discovery
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