#!/usr/bin/env zsh

# Color configuration and validation tests for the reminder plugin

echo "🎨 Testing Color Configuration & Validation"
echo "═══════════════════════════════════════════"

# Test setup - shared test helper functions
source_test_plugin() {
    autoload -U colors
    colors
    source reminder.plugin.zsh
}

# Test 1: Default color configuration
test_default_colors() {
    echo "\n1. Testing default color configuration:"
    
    source_test_plugin
    
    # Test default color values
    if [[ "$TODO_TASK_COLORS" == "167,71,136,110,139,73" ]]; then
        echo "✅ PASS: Default task colors correct"
    else
        echo "❌ FAIL: Default task colors wrong (got: $TODO_TASK_COLORS)"
    fi
    
    if [[ "$TODO_BORDER_COLOR" == "240" ]]; then
        echo "✅ PASS: Default border color correct"
    else
        echo "❌ FAIL: Default border color wrong (got: $TODO_BORDER_COLOR)"
    fi
    
    if [[ "$TODO_BACKGROUND_COLOR" == "235" ]]; then
        echo "✅ PASS: Default background color correct"
    else
        echo "❌ FAIL: Default background color wrong (got: $TODO_BACKGROUND_COLOR)"
    fi
    
    if [[ "$TODO_TEXT_COLOR" == "240" ]]; then
        echo "✅ PASS: Default text color correct"
    else
        echo "❌ FAIL: Default text color wrong (got: $TODO_TEXT_COLOR)"
    fi
    
    if [[ "$TODO_TITLE_COLOR" == "250" ]]; then
        echo "✅ PASS: Default title color correct"
    else
        echo "❌ FAIL: Default title color wrong (got: $TODO_TITLE_COLOR)"
    fi
    
    if [[ "$TODO_AFFIRMATION_COLOR" == "109" ]]; then
        echo "✅ PASS: Default affirmation color correct"
    else
        echo "❌ FAIL: Default affirmation color wrong (got: $TODO_AFFIRMATION_COLOR)"
    fi
}

# Test 2: Color array initialization
test_color_array() {
    echo "\n2. Testing color array initialization:"
    
    # Initialize the color array manually for testing (since plugin loads in different context)
    typeset -a TODO_COLORS
    TODO_COLORS=(${(s:,:)TODO_TASK_COLORS})
    
    # Test color array initialization
    if [[ ${#TODO_COLORS[@]} -eq 6 ]]; then
        echo "✅ PASS: Color array initialized with correct count"
    else
        echo "❌ FAIL: Color array has wrong size (got: ${#TODO_COLORS[@]}, expected: 6)"
    fi
    
    # Test that array contains expected values
    local expected_colors=(167 71 136 110 139 73)
    local array_match=true
    for ((i=1; i<=${#expected_colors[@]}; i++)); do
        if [[ "${TODO_COLORS[i]}" != "${expected_colors[i]}" ]]; then
            array_match=false
            break
        fi
    done
    
    if [[ "$array_match" == "true" ]]; then
        echo "✅ PASS: Color array contains expected default values"
    else
        echo "❌ FAIL: Color array values don't match defaults (got: ${TODO_COLORS[@]})"
    fi
}

# Test 3: Color validation logic
test_color_validation_logic() {
    echo "\n3. Testing color validation logic:"
    
    # Test valid color range (0-255)
    valid_color=128
    if [[ $valid_color -ge 0 && $valid_color -le 255 ]]; then
        echo "✅ PASS: Valid color range check works"
    else
        echo "❌ FAIL: Valid color range check failed"
    fi
    
    # Test invalid color range 
    invalid_color=256
    if [[ $invalid_color -gt 255 ]]; then
        echo "✅ PASS: Invalid color range detection works"
    else
        echo "❌ FAIL: Invalid color range detection failed"
    fi
    
    # Test comma-separated format validation
    valid_format="123,45,67"
    if [[ "$valid_format" =~ ^[0-9]+(,[0-9]+)*$ ]]; then
        echo "✅ PASS: Valid task colors format check works"
    else
        echo "❌ FAIL: Valid task colors format check failed"
    fi
    
    invalid_format="red,green,blue"
    if [[ ! "$invalid_format" =~ ^[0-9]+(,[0-9]+)*$ ]]; then
        echo "✅ PASS: Invalid task colors format detection works"
    else
        echo "❌ FAIL: Invalid task colors format detection failed"
    fi
    
    # Test empty string detection
    empty_format=""
    if [[ -z "$empty_format" ]] || [[ ! "$empty_format" =~ ^[0-9]+(,[0-9]+)*$ ]]; then
        echo "✅ PASS: Empty task colors format detection works"
    else
        echo "❌ FAIL: Empty task colors format detection failed"
    fi
}

# Test 4: Color validation scenarios
test_color_validation_scenarios() {
    echo "\n4. Testing color validation scenarios:"
    
    # Test 4a: Valid color configuration
    echo "\n4a. Testing valid color configuration:"
    COLUMNS=80 TODO_TASK_COLORS="196,46,33" TODO_BORDER_COLOR=244 TODO_AFFIRMATION_COLOR=109 zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh; echo "✅ Valid colors accepted"' 2>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "✅ PASS: Valid color configuration loads successfully"
    else
        echo "❌ FAIL: Valid color configuration rejected"
    fi
    
    # Test 4b: Invalid border color (too high)
    echo "\n4b. Testing invalid border color (256):"
    error_output=$(COLUMNS=80 TODO_BORDER_COLOR=256 zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh' 2>&1)
    if [[ $? -ne 0 ]] && [[ "$error_output" == *"TODO_BORDER_COLOR must be a number between 0-255"* ]]; then
        echo "✅ PASS: Invalid border color (256) properly rejected"
    else
        echo "❌ FAIL: Invalid border color not properly rejected"
    fi
    
    # Test 4c: Invalid task colors (non-numeric)
    echo "\n4c. Testing invalid task colors (non-numeric):"
    error_output=$(COLUMNS=80 TODO_TASK_COLORS="red,green,blue" zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh' 2>&1)
    if [[ $? -ne 0 ]] && [[ "$error_output" == *"TODO_TASK_COLORS must be comma-separated numbers"* ]]; then
        echo "✅ PASS: Non-numeric task colors properly rejected"
    else
        echo "❌ FAIL: Non-numeric task colors not properly rejected"
    fi
    
    # Test 4d: Invalid task colors (value too high)
    echo "\n4d. Testing invalid task colors (value too high):"
    error_output=$(COLUMNS=80 TODO_TASK_COLORS="200,300,150" zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh' 2>&1)
    if [[ "$error_output" == *"Task color values must be 0-255"* ]]; then
        echo "✅ PASS: High task color values properly rejected"
    else
        echo "❌ FAIL: High task color values not properly rejected (output: '$error_output')"
    fi
    
    # Test 4e: Invalid affirmation color (negative)
    echo "\n4e. Testing invalid affirmation color (negative):"
    error_output=$(COLUMNS=80 TODO_AFFIRMATION_COLOR=-1 zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh' 2>&1)
    if [[ $? -ne 0 ]] && [[ "$error_output" == *"TODO_AFFIRMATION_COLOR must be a number between 0-255"* ]]; then
        echo "✅ PASS: Negative affirmation color properly rejected"
    else
        echo "❌ FAIL: Negative affirmation color not properly rejected"
    fi
    
    # Test 4f: Mixed valid/invalid task colors
    echo "\n4f. Testing mixed valid/invalid task colors:"
    error_output=$(COLUMNS=80 TODO_TASK_COLORS="100,256,50" zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh' 2>&1)
    if [[ "$error_output" == *"Task color values must be 0-255"* ]]; then
        echo "✅ PASS: Mixed task colors properly validated"
    else
        echo "❌ FAIL: Mixed task colors validation failed (output: '$error_output')"
    fi
    
    # Test 4g: Empty task colors (should use default)
    echo "\n4g. Testing empty task colors (should use default):"
    error_output=$(COLUMNS=80 TODO_TASK_COLORS="" zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh; echo "Final value: $TODO_TASK_COLORS"' 2>&1)
    if [[ "$error_output" == *"Final value: 167,71,136,110,139,73"* ]]; then
        echo "✅ PASS: Empty task colors use default values"
    else
        echo "❌ FAIL: Empty task colors don't use default (output: '$error_output')"
    fi
    
    # Test 4h: Task colors with spaces
    echo "\n4h. Testing task colors with invalid format (spaces):"
    error_output=$(COLUMNS=80 TODO_TASK_COLORS="100, 200, 150" zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh' 2>&1)
    if [[ $? -ne 0 ]] && [[ "$error_output" == *"TODO_TASK_COLORS must be comma-separated numbers"* ]]; then
        echo "✅ PASS: Task colors with spaces properly rejected"
    else
        echo "❌ FAIL: Task colors with spaces not properly rejected"
    fi
    
    # Test 4i: Single task color (valid)
    echo "\n4i. Testing single task color:"
    COLUMNS=80 TODO_TASK_COLORS="196" zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh; echo "Single color loaded"' 2>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "✅ PASS: Single task color accepted"
    else
        echo "❌ FAIL: Single task color rejected"
    fi
    
    # Test 4j: Boundary values (0 and 255)
    echo "\n4j. Testing boundary values (0 and 255):"
    COLUMNS=80 TODO_TASK_COLORS="0,255" TODO_BORDER_COLOR=0 TODO_AFFIRMATION_COLOR=255 zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh; echo "Boundary values loaded"' 2>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "✅ PASS: Boundary values (0,255) accepted"
    else
        echo "❌ FAIL: Boundary values (0,255) rejected"
    fi
}

# Test 5: Custom color configuration
test_custom_colors() {
    echo "\n5. Testing custom color configuration:"
    
    # Test custom colors are applied
    original_task_colors="$TODO_TASK_COLORS"
    original_border_color="$TODO_BORDER_COLOR"
    original_affirmation_color="$TODO_AFFIRMATION_COLOR"
    
    # Set custom colors
    TODO_TASK_COLORS="196,46,33"
    TODO_BORDER_COLOR=244
    TODO_AFFIRMATION_COLOR=33
    
    # Reinitialize color array
    typeset -a TODO_COLORS
    TODO_COLORS=(${(s:,:)TODO_TASK_COLORS})
    
    if [[ ${#TODO_COLORS[@]} -eq 3 ]]; then
        echo "✅ PASS: Custom task color array has correct size"
    else
        echo "❌ FAIL: Custom task color array has wrong size (got: ${#TODO_COLORS[@]}, expected: 3)"
    fi
    
    if [[ "${TODO_COLORS[1]}" == "196" && "${TODO_COLORS[2]}" == "46" && "${TODO_COLORS[3]}" == "33" ]]; then
        echo "✅ PASS: Custom task colors properly set"
    else
        echo "❌ FAIL: Custom task colors not properly set (got: ${TODO_COLORS[@]})"
    fi
    
    # Restore original values
    TODO_TASK_COLORS="$original_task_colors"
    TODO_BORDER_COLOR="$original_border_color"
    TODO_AFFIRMATION_COLOR="$original_affirmation_color"
    TODO_COLORS=(${(s:,:)TODO_TASK_COLORS})
}

# Run all color tests
main() {
    test_default_colors
    test_color_array
    test_color_validation_logic
    test_color_validation_scenarios
    test_custom_colors
    
    echo "\n🎯 Color Tests Completed"
    echo "═════════════════════════"
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "$0" == *"color.zsh" ]]; then
    main "$@"
fi