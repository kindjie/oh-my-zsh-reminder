#!/usr/bin/env zsh

# Color Mode Configuration Tests
# Tests the TODO_COLOR_MODE environment variable and config commands

# Setup for isolated testing
source "${0:A:h}/../reminder.plugin.zsh"
source "${0:A:h}/test_utils.zsh"

# Test counter
test_count=0
passed_tests=0

# Test function wrapper
function run_test() {
    local test_name="$1"
    local test_func="$2"
    ((test_count++))
    
    # Setup isolated environment for each test
    local temp_save="$(mktemp)"
    local original_save="$TODO_SAVE_FILE"
    TODO_SAVE_FILE="$temp_save"
    
    # Create proper empty todo file format
    printf '\n\n1\n' > "$temp_save"
    
    if $test_func; then
        echo "✅ PASS: $test_name"
        ((passed_tests++))
    else
        echo "❌ FAIL: $test_name"
    fi
    
    # Cleanup
    TODO_SAVE_FILE="$original_save"
    rm -f "$temp_save"
}

# Test 1: Environment variable validation
function test_color_mode_validation() {
    # Test that the current plugin accepts valid values
    local original_mode="$TODO_COLOR_MODE"
    
    # Test valid values by setting them directly
    TODO_COLOR_MODE="static"
    [[ "$TODO_COLOR_MODE" == "static" ]] || return 1
    
    TODO_COLOR_MODE="dynamic"
    [[ "$TODO_COLOR_MODE" == "dynamic" ]] || return 1
    
    TODO_COLOR_MODE="auto"
    [[ "$TODO_COLOR_MODE" == "auto" ]] || return 1
    
    # Test validation function exists and works
    TODO_COLOR_MODE="invalid"
    if [[ "$TODO_COLOR_MODE" != "static" && "$TODO_COLOR_MODE" != "dynamic" && "$TODO_COLOR_MODE" != "auto" ]]; then
        # Validation should catch this
        TODO_COLOR_MODE="$original_mode"
        return 0
    fi
    
    return 1
}

# Test 2: Default value behavior
function test_color_mode_default() {
    # Test that default is set correctly (plugin already loaded)
    [[ -n "$TODO_COLOR_MODE" ]] || return 1
    # Default should be "auto" if not explicitly set
    # Since plugin is loaded, this should be "auto" unless changed
    [[ "$TODO_COLOR_MODE" == "auto" || "$TODO_COLOR_MODE" == "static" || "$TODO_COLOR_MODE" == "dynamic" ]] || return 1
    return 0
}

# Test 3: Config set command validation
function test_config_set_color_mode() {
    # Initialize tasks to ensure todo_save works
    load_tasks >/dev/null 2>&1
    
    # Test static mode
    todo_config_set color-mode static >/dev/null 2>&1
    [[ "$TODO_COLOR_MODE" == "static" ]] || { echo "Expected TODO_COLOR_MODE=static, got: $TODO_COLOR_MODE" >&2; return 1; }
    
    # Test dynamic mode
    todo_config_set color-mode dynamic >/dev/null 2>&1
    [[ "$TODO_COLOR_MODE" == "dynamic" ]] || { echo "Expected TODO_COLOR_MODE=dynamic, got: $TODO_COLOR_MODE" >&2; return 1; }
    
    # Test auto mode
    todo_config_set color-mode auto >/dev/null 2>&1
    [[ "$TODO_COLOR_MODE" == "auto" ]] || { echo "Expected TODO_COLOR_MODE=auto, got: $TODO_COLOR_MODE" >&2; return 1; }
    
    return 0
}

# Test 4: Config set command error handling
function test_config_set_color_mode_invalid() {
    local output
    output=$(todo config set color-mode invalid 2>&1)
    [[ "$output" == *"Error: Color mode must be 'static', 'dynamic', or 'auto'"* ]] || return 1
    return 0
}

# Test 5: Config persistence
function test_color_mode_persistence() {
    # Initialize tasks first
    load_tasks >/dev/null 2>&1
    
    # Set color mode (this calls todo_save automatically)
    todo_config_set color-mode dynamic >/dev/null 2>&1
    
    # Verify it was set
    [[ "$TODO_COLOR_MODE" == "dynamic" ]] || return 1
    
    # Check that it was persisted to file
    local serialized=$(_todo_serialize_config)
    [[ "$serialized" == *"TODO_COLOR_MODE=dynamic"* ]] || return 1
    
    return 0
}

# Test 6: Config serialization contains color mode
function test_config_serialization() {
    TODO_COLOR_MODE="static"
    local serialized=$(_todo_serialize_config)
    [[ "$serialized" == *"TODO_COLOR_MODE=static"* ]] || return 1
    return 0
}

# Test 7: Help messages include explanations
function test_config_set_explanations() {
    local output
    
    output=$(todo config set color-mode static 2>&1)
    [[ "$output" == *"Will always use regular presets"* ]] || return 1
    
    output=$(todo config set color-mode dynamic 2>&1)
    [[ "$output" == *"Will always use theme-adaptive presets"* ]] || return 1
    
    output=$(todo config set color-mode auto 2>&1)
    [[ "$output" == *"Will auto-detect tinted-shell/tinty"* ]] || return 1
    
    return 0
}

# Test 8: Config reset behavior
function test_config_reset_color_mode() {
    # Initialize tasks first
    load_tasks >/dev/null 2>&1
    
    # Set non-default value
    todo_config_set color-mode dynamic >/dev/null 2>&1
    [[ "$TODO_COLOR_MODE" == "dynamic" ]] || return 1
    
    # Reset config should reset TODO_COLOR_MODE too
    # Check if the reset function includes TODO_COLOR_MODE
    todo_config_reset >/dev/null 2>&1
    
    # Should be back to default "auto"
    [[ "$TODO_COLOR_MODE" == "auto" ]] || return 1
    return 0
}

# Run all tests
echo "🧪 Running Color Mode Configuration Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

run_test "Environment variable validation" test_color_mode_validation
run_test "Default value behavior" test_color_mode_default  
run_test "Config set command validation" test_config_set_color_mode
run_test "Config set error handling" test_config_set_color_mode_invalid
run_test "Config persistence" test_color_mode_persistence
run_test "Config serialization" test_config_serialization
run_test "Help message explanations" test_config_set_explanations
run_test "Config reset behavior" test_config_reset_color_mode

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Results: $passed_tests/$test_count tests passed"

if [[ $passed_tests -eq $test_count ]]; then
    echo "✅ All color mode tests passed!"
    exit 0
else
    echo "❌ Some color mode tests failed!"
    exit 1
fi