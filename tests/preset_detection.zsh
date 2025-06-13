#!/usr/bin/env zsh

# Preset Detection Logic Tests  
# Tests the _should_use_tinted_preset function and smart preset selection

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
    local original_save="$_TODO_INTERNAL_SAVE_FILE"
    local original_color_mode="$_TODO_INTERNAL_COLOR_MODE"
    local original_tinted_shell="$TINTED_SHELL_ENABLE_BASE16_VARS"
    
    _TODO_INTERNAL_SAVE_FILE="$temp_save"
    printf '\n\n1\n' > "$temp_save"
    
    if $test_func; then
        echo "✅ PASS: $test_name"
        ((passed_tests++))
    else
        echo "❌ FAIL: $test_name"
    fi
    
    # Cleanup
    _TODO_INTERNAL_SAVE_FILE="$original_save"
    _TODO_INTERNAL_COLOR_MODE="$original_color_mode"
    if [[ -n "$original_tinted_shell" ]]; then
        TINTED_SHELL_ENABLE_BASE16_VARS="$original_tinted_shell"
    else
        unset TINTED_SHELL_ENABLE_BASE16_VARS
    fi
    rm -f "$temp_save"
}

# Test 1: Static mode never uses tinted presets
function test_static_mode() {
    _TODO_INTERNAL_COLOR_MODE="static"
    
    # Should return false regardless of environment
    unset TINTED_SHELL_ENABLE_BASE16_VARS
    ! _should_use_tinted_preset || return 1
    
    TINTED_SHELL_ENABLE_BASE16_VARS=1
    ! _should_use_tinted_preset || return 1
    
    return 0
}

# Test 2: Dynamic mode always uses tinted presets  
function test_dynamic_mode() {
    _TODO_INTERNAL_COLOR_MODE="dynamic"
    
    # Should return true regardless of environment
    unset TINTED_SHELL_ENABLE_BASE16_VARS
    _should_use_tinted_preset || return 1
    
    TINTED_SHELL_ENABLE_BASE16_VARS=0
    _should_use_tinted_preset || return 1
    
    return 0
}

# Test 3: Auto mode with tinted-shell detection
function test_auto_tinted_shell() {
    _TODO_INTERNAL_COLOR_MODE="auto"
    
    # With tinted-shell enabled
    TINTED_SHELL_ENABLE_BASE16_VARS=1
    _should_use_tinted_preset || return 1
    
    # Without tinted-shell, but tinty might still be available
    unset TINTED_SHELL_ENABLE_BASE16_VARS
    # This test is environment-dependent - if tinty is available, it should still return true
    if command -v tinty >/dev/null 2>&1; then
        # tinty is available, so should still use tinted
        _should_use_tinted_preset || return 1
    else
        # No tinty available, should not use tinted
        ! _should_use_tinted_preset || return 1
    fi
    
    return 0
}

# Test 4: Auto mode with tinty detection (mocked)
function test_auto_tinty_detection() {
    _TODO_INTERNAL_COLOR_MODE="auto"
    unset TINTED_SHELL_ENABLE_BASE16_VARS
    
    # Mock tinty command availability
    function tinty() { return 0; }
    
    # Should detect tinty and use tinted
    _should_use_tinted_preset || return 1
    
    # Remove mock
    unset -f tinty
    
    return 0
}

# Test 5: Smart preset selection - regular to tinted
function test_smart_selection_to_tinted() {
    _TODO_INTERNAL_COLOR_MODE="dynamic"
    
    # Apply regular preset, should get tinted variant
    local output
    output=$(todo config preset vibrant 2>&1)
    [[ "$output" == *"vibrant → vibrant_tinted"* ]] || return 1
    
    return 0
}

# Test 6: Smart preset selection - tinted to regular  
function test_smart_selection_to_regular() {
    _TODO_INTERNAL_COLOR_MODE="static"
    
    # Apply tinted preset, should get regular variant
    local output
    output=$(todo config preset vibrant_tinted 2>&1)
    [[ "$output" == *"vibrant_tinted → vibrant"* ]] || return 1
    
    return 0
}

# Test 7: Auto mode detection feedback
function test_detection_feedback() {
    _TODO_INTERNAL_COLOR_MODE="auto"
    TINTED_SHELL_ENABLE_BASE16_VARS=1
    
    local output
    output=$(todo config preset subtle 2>&1)
    [[ "$output" == *"tinted-shell detected"* ]] || return 1
    
    return 0
}

# Test 8: Missing tinted variant fallback
function test_missing_tinted_fallback() {
    _TODO_INTERNAL_COLOR_MODE="dynamic"
    
    # Try to apply a preset that doesn't have tinted variant (create temp scenario)
    # This tests the fallback behavior when tinted variant is missing
    local output
    output=$(todo config preset balanced 2>&1)
    # Should either use balanced_tinted or show appropriate message
    [[ "$output" == *"Applied preset:"* ]] || return 1
    
    return 0
}

# Test 9: Explicit tinted request with static mode
function test_explicit_tinted_with_static() {
    _TODO_INTERNAL_COLOR_MODE="static"
    
    # Explicitly request tinted preset with static mode
    local output
    output=$(todo config preset vibrant_tinted 2>&1)
    # Should force to regular variant
    [[ "$output" == *"vibrant_tinted → vibrant"* ]] || return 1
    
    return 0
}

# Test 10: Color mode display in feedback
function test_color_mode_in_feedback() {
    _TODO_INTERNAL_COLOR_MODE="static"
    
    local output
    output=$(todo config preset balanced 2>&1)
    [[ "$output" == *"(color-mode: static)"* ]] || return 1
    
    return 0
}

# Test 11: Detection with both tinted-shell and tinty
function test_dual_detection() {
    _TODO_INTERNAL_COLOR_MODE="auto"
    TINTED_SHELL_ENABLE_BASE16_VARS=1
    
    # Mock tinty as well
    function tinty() { return 0; }
    
    # Should still work (prefer tinted-shell detection)
    _should_use_tinted_preset || return 1
    
    local output
    output=$(todo config preset subtle 2>&1) 
    [[ "$output" == *"tinted-shell detected"* ]] || return 1
    
    unset -f tinty
    return 0
}

# Test 12: No detection fallback
function test_no_detection_fallback() {
    _TODO_INTERNAL_COLOR_MODE="auto"
    unset TINTED_SHELL_ENABLE_BASE16_VARS
    
    # Mock tinty command to not be available by shadowing it
    function command() {
        if [[ "$1" == "-v" && "$2" == "tinty" ]]; then
            return 1  # Pretend tinty is not found
        else
            builtin command "$@"
        fi
    }
    
    # Should fallback to regular presets
    ! _should_use_tinted_preset || return 1
    
    local output
    output=$(todo config preset vibrant 2>&1)
    [[ "$output" == *"vibrant (color-mode: auto)"* ]] || return 1
    
    # Clean up mock
    unset -f command
    
    return 0
}

# Run all tests
echo "🧪 Running Preset Detection Logic Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

run_test "Static mode never uses tinted" test_static_mode
run_test "Dynamic mode always uses tinted" test_dynamic_mode
run_test "Auto mode tinted-shell detection" test_auto_tinted_shell
run_test "Auto mode tinty detection" test_auto_tinty_detection
run_test "Smart selection regular to tinted" test_smart_selection_to_tinted
run_test "Smart selection tinted to regular" test_smart_selection_to_regular
run_test "Auto mode detection feedback" test_detection_feedback
run_test "Missing tinted variant fallback" test_missing_tinted_fallback
run_test "Explicit tinted with static mode" test_explicit_tinted_with_static
run_test "Color mode display in feedback" test_color_mode_in_feedback
run_test "Detection with both tools" test_dual_detection
run_test "No detection fallback" test_no_detection_fallback

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Results: $passed_tests/$test_count tests passed"

if [[ $passed_tests -eq $test_count ]]; then
    echo "✅ All preset detection tests passed!"
    exit 0
else
    echo "❌ Some preset detection tests failed!"
    exit 1
fi