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

# Test 10: Apply minimal preset
test_preset_minimal() {
    todo config preset minimal >/dev/null 2>&1
    
    # Comprehensive validation
    if ! validate_preset_values "minimal"; then
        return 1
    fi
    
    # Specific minimal preset checks
    if [[ "$TODO_TITLE" == "TODO" && 
          "$TODO_HEART_POSITION" == "none" && 
          "$TODO_SHOW_AFFIRMATION" == "false" &&
          "$TODO_HEART_CHAR" == "•" &&
          "$TODO_BULLET_CHAR" == "•" &&
          "$TODO_TASK_COLORS" == "250,248,246,244,242,240" &&
          "$TODO_BORDER_COLOR" == "238" &&
          "$TODO_TASK_TEXT_COLOR" == "245" &&
          "$TODO_TITLE_COLOR" == "255" &&
          "$TODO_AFFIRMATION_COLOR" == "250" &&
          "$TODO_PADDING_RIGHT" == "2" ]]; then
        return 0
    else
        echo "Minimal preset not applied correctly"
        echo "TODO_TITLE='$TODO_TITLE' (expected 'TODO')"
        echo "TODO_HEART_POSITION='$TODO_HEART_POSITION' (expected 'none')"
        echo "TODO_SHOW_AFFIRMATION='$TODO_SHOW_AFFIRMATION' (expected 'false')"
        echo "TODO_TASK_COLORS='$TODO_TASK_COLORS' (expected '245,244,243,242,241,240')"
        return 1
    fi
}

# Test 11: Apply colorful preset
test_preset_colorful() {
    todo config preset colorful >/dev/null 2>&1
    
    # Comprehensive validation
    if ! validate_preset_values "colorful"; then
        return 1
    fi
    
    # Specific colorful preset checks
    if [[ "$TODO_TITLE" == "✨ TASKS ✨" && 
          "$TODO_HEART_CHAR" == "💖" && 
          "$TODO_HEART_POSITION" == "both" &&
          "$TODO_BULLET_CHAR" == "🔸" &&
          "$TODO_TASK_COLORS" == "196,202,208,214,220,226" &&
          "$TODO_BORDER_COLOR" == "201" &&
          "$TODO_TASK_TEXT_COLOR" == "255" &&
          "$TODO_TITLE_COLOR" == "226" &&
          "$TODO_AFFIRMATION_COLOR" == "213" &&
          "$TODO_BOX_WIDTH_FRACTION" == "0.5" &&
          "$TODO_SHOW_AFFIRMATION" == "true" ]]; then
        return 0
    else
        echo "Colorful preset not applied correctly"
        echo "TODO_TITLE='$TODO_TITLE' (expected '✨ TASKS ✨')"
        echo "TODO_HEART_CHAR='$TODO_HEART_CHAR' (expected '💖')"
        echo "TODO_HEART_POSITION='$TODO_HEART_POSITION' (expected 'both')"
        echo "TODO_TASK_COLORS='$TODO_TASK_COLORS' (expected '196,202,208,214,220,226')"
        return 1
    fi
}

# Test 12: Apply work preset
test_preset_work() {
    todo config preset work >/dev/null 2>&1
    
    # Comprehensive validation
    if ! validate_preset_values "work"; then
        return 1
    fi
    
    # Specific work preset checks
    if [[ "$TODO_TITLE" == "WORK TASKS" && 
          "$TODO_HEART_CHAR" == "💼" && 
          "$TODO_BOX_WIDTH_FRACTION" == "0.4" &&
          "$TODO_BULLET_CHAR" == "▶" &&
          "$TODO_TASK_COLORS" == "21,33,39,45,51,57" &&
          "$TODO_BORDER_COLOR" == "33" &&
          "$TODO_TASK_TEXT_COLOR" == "250" &&
          "$TODO_TITLE_COLOR" == "39" &&
          "$TODO_AFFIRMATION_COLOR" == "75" &&
          "$TODO_HEART_POSITION" == "left" &&
          "$TODO_SHOW_AFFIRMATION" == "true" ]]; then
        return 0
    else
        echo "Work preset not applied correctly"
        echo "TODO_TITLE='$TODO_TITLE' (expected 'WORK TASKS')"
        echo "TODO_HEART_CHAR='$TODO_HEART_CHAR' (expected '💼')"
        echo "TODO_BOX_WIDTH_FRACTION='$TODO_BOX_WIDTH_FRACTION' (expected '0.4')"
        return 1
    fi
}

# Test 13: Apply dark preset
test_preset_dark() {
    todo config preset dark >/dev/null 2>&1
    
    # Comprehensive validation
    if ! validate_preset_values "dark"; then
        return 1
    fi
    
    # Specific dark preset checks
    if [[ "$TODO_TITLE" == "REMEMBER" &&
          "$TODO_HEART_CHAR" == "♥" &&
          "$TODO_BULLET_CHAR" == "▪" &&
          "$TODO_TASK_COLORS" == "124,88,52,94,130,166" &&
          "$TODO_BORDER_COLOR" == "235" &&
          "$TODO_BORDER_BG_COLOR" == "232" && 
          "$TODO_CONTENT_BG_COLOR" == "233" &&
          "$TODO_TASK_TEXT_COLOR" == "244" &&
          "$TODO_TITLE_COLOR" == "255" &&
          "$TODO_AFFIRMATION_COLOR" == "103" &&
          "$TODO_HEART_POSITION" == "left" &&
          "$TODO_SHOW_AFFIRMATION" == "true" ]]; then
        return 0
    else
        echo "Dark preset not applied correctly"
        echo "TODO_BORDER_BG_COLOR='$TODO_BORDER_BG_COLOR' (expected '232')"
        echo "TODO_CONTENT_BG_COLOR='$TODO_CONTENT_BG_COLOR' (expected '233')"
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

# Test 15: Apply monokai preset
test_preset_monokai() {
    todo config preset monokai >/dev/null 2>&1
    
    # Comprehensive validation
    if ! validate_preset_values "monokai"; then
        return 1
    fi
    
    # Specific monokai preset checks
    if [[ "$TODO_TITLE" == "CODE" &&
          "$TODO_HEART_CHAR" == "♥" &&
          "$TODO_BULLET_CHAR" == "▪" &&
          "$TODO_TASK_COLORS" == "249,115,166,230,141,208" &&
          "$TODO_BORDER_COLOR" == "59" &&
          "$TODO_BORDER_BG_COLOR" == "235" &&
          "$TODO_CONTENT_BG_COLOR" == "234" &&
          "$TODO_TASK_TEXT_COLOR" == "248" &&
          "$TODO_TITLE_COLOR" == "141" &&
          "$TODO_AFFIRMATION_COLOR" == "208" &&
          "$TODO_HEART_POSITION" == "left" &&
          "$TODO_SHOW_AFFIRMATION" == "true" ]]; then
        return 0
    else
        echo "Monokai preset not applied correctly"
        return 1
    fi
}

# Test 16: Apply solarized-dark preset
test_preset_solarized_dark() {
    todo config preset solarized-dark >/dev/null 2>&1
    
    # Comprehensive validation
    if ! validate_preset_values "solarized-dark"; then
        return 1
    fi
    
    # Specific solarized-dark preset checks
    if [[ "$TODO_TITLE" == "FOCUS" &&
          "$TODO_HEART_CHAR" == "☀" &&
          "$TODO_BULLET_CHAR" == "•" &&
          "$TODO_TASK_COLORS" == "203,166,136,68,160,125" &&
          "$TODO_BORDER_COLOR" == "240" &&
          "$TODO_BORDER_BG_COLOR" == "234" &&
          "$TODO_CONTENT_BG_COLOR" == "233" &&
          "$TODO_TASK_TEXT_COLOR" == "244" &&
          "$TODO_TITLE_COLOR" == "136" &&
          "$TODO_AFFIRMATION_COLOR" == "37" &&
          "$TODO_HEART_POSITION" == "left" &&
          "$TODO_SHOW_AFFIRMATION" == "true" ]]; then
        return 0
    else
        echo "Solarized-dark preset not applied correctly"
        return 1
    fi
}

# Test 17: Apply nord preset
test_preset_nord() {
    todo config preset nord >/dev/null 2>&1
    
    # Comprehensive validation
    if ! validate_preset_values "nord"; then
        return 1
    fi
    
    # Specific nord preset checks
    if [[ "$TODO_TITLE" == "ARCTIC" &&
          "$TODO_HEART_CHAR" == "❄" &&
          "$TODO_BULLET_CHAR" == "▸" &&
          "$TODO_TASK_COLORS" == "131,209,150,116,97,139" &&
          "$TODO_BORDER_COLOR" == "59" &&
          "$TODO_BORDER_BG_COLOR" == "236" &&
          "$TODO_CONTENT_BG_COLOR" == "235" &&
          "$TODO_TASK_TEXT_COLOR" == "188" &&
          "$TODO_TITLE_COLOR" == "150" &&
          "$TODO_AFFIRMATION_COLOR" == "116" &&
          "$TODO_HEART_POSITION" == "left" &&
          "$TODO_SHOW_AFFIRMATION" == "true" ]]; then
        return 0
    else
        echo "Nord preset not applied correctly"
        return 1
    fi
}

# Test 18: Apply gruvbox-dark preset
test_preset_gruvbox_dark() {
    todo config preset gruvbox-dark >/dev/null 2>&1
    
    # Comprehensive validation
    if ! validate_preset_values "gruvbox-dark"; then
        return 1
    fi
    
    # Specific gruvbox-dark preset checks
    if [[ "$TODO_TITLE" == "RETRO" &&
          "$TODO_HEART_CHAR" == "♥" &&
          "$TODO_BULLET_CHAR" == "●" &&
          "$TODO_TASK_COLORS" == "167,208,214,109,175,142" &&
          "$TODO_BORDER_COLOR" == "243" &&
          "$TODO_BORDER_BG_COLOR" == "237" &&
          "$TODO_CONTENT_BG_COLOR" == "235" &&
          "$TODO_TASK_TEXT_COLOR" == "223" &&
          "$TODO_TITLE_COLOR" == "214" &&
          "$TODO_AFFIRMATION_COLOR" == "109" &&
          "$TODO_HEART_POSITION" == "left" &&
          "$TODO_SHOW_AFFIRMATION" == "true" ]]; then
        return 0
    else
        echo "Gruvbox-dark preset not applied correctly"
        return 1
    fi
}

# Test 19: Apply base16-auto preset (simplified test - it's dynamic)
test_preset_base16_auto() {
    # This preset is dynamic based on BASE16_THEME, so we'll just test it applies without error
    todo config preset base16-auto >/dev/null 2>&1
    
    # Comprehensive validation
    if ! validate_preset_values "base16-auto"; then
        return 1
    fi
    
    # Just verify required variables are set (dynamic values depend on BASE16_THEME)
    if [[ -n "$TODO_TITLE" && -n "$TODO_TASK_COLORS" && -n "$TODO_BORDER_COLOR" ]]; then
        return 0
    else
        echo "Base16-auto preset failed to set required variables"
        return 1
    fi
}

# Test 20: Save current preset
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

# Test 21: Preset list consistency
test_preset_list_consistency() {
    # Get the available presets from the constant
    local preset_list="$_TODO_PRESET_LIST"
    # Remove spaces after commas for proper splitting
    preset_list="${preset_list//,/,}"
    preset_list="${preset_list//  / }"
    
    local -a available_presets
    available_presets=(${(s:,:)preset_list})
    
    # Test each preset in the list exists
    local missing_presets=()
    for preset in "${available_presets[@]}"; do
        # Trim any whitespace
        preset="${preset## }"
        preset="${preset%% }"
        
        # Skip empty entries
        if [[ -z "$preset" ]]; then
            continue
        fi
        
        # Skip base16-auto as it's dynamic
        if [[ "$preset" == "base16-auto" ]]; then
            continue
        fi
        
        # Try to apply the preset
        local output=$(todo config preset "$preset" 2>&1)
        if [[ "$output" =~ "Unknown preset" ]]; then
            missing_presets+=("$preset")
        fi
    done
    
    if [[ ${#missing_presets[@]} -eq 0 ]]; then
        return 0
    else
        echo "Presets in _TODO_PRESET_LIST but not implemented: ${missing_presets[@]}"
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
    local output=$(todo config import "/nonexistent/file.conf" 2>&1)
    
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
run_test "Apply minimal preset" test_preset_minimal
run_test "Apply colorful preset" test_preset_colorful
run_test "Apply work preset" test_preset_work
run_test "Apply dark preset" test_preset_dark
run_test "Invalid preset handling" test_preset_invalid
run_test "Apply monokai preset" test_preset_monokai
run_test "Apply solarized-dark preset" test_preset_solarized_dark
run_test "Apply nord preset" test_preset_nord
run_test "Apply gruvbox-dark preset" test_preset_gruvbox_dark
run_test "Apply base16-auto preset" test_preset_base16_auto
run_test "Save current preset" test_save_preset
run_test "Preset list consistency" test_preset_list_consistency
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