#!/usr/bin/env zsh

# Preset Filtering and Display Tests
# Tests the filtered preset lists and user experience consistency

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
    
    if $test_func; then
        echo "✅ PASS: $test_name"
        ((passed_tests++))
    else
        echo "❌ FAIL: $test_name"
    fi
}

# Test 1: User preset list filters tinted variants
function test_user_preset_filtering() {
    local user_presets=($(todo_config_get_user_preset_names))
    local full_presets=($(todo_config_get_preset_names))
    
    # User list should be smaller than full list
    [[ ${#user_presets[@]} -lt ${#full_presets[@]} ]] || return 1
    
    # User list should not contain _tinted variants
    for preset in "${user_presets[@]}"; do
        [[ "$preset" != *"_tinted" ]] || return 1
    done
    
    # Should contain base presets
    [[ "${user_presets[(r)balanced]}" == "balanced" ]] || return 1
    [[ "${user_presets[(r)subtle]}" == "subtle" ]] || return 1
    [[ "${user_presets[(r)vibrant]}" == "vibrant" ]] || return 1
    [[ "${user_presets[(r)loud]}" == "loud" ]] || return 1
    
    return 0
}

# Test 2: Full preset list includes all variants
function test_full_preset_list() {
    local full_presets=($(todo_config_get_preset_names))
    
    # Should contain both regular and tinted variants
    [[ "${full_presets[(r)balanced]}" == "balanced" ]] || return 1
    [[ "${full_presets[(r)balanced_tinted]}" == "balanced_tinted" ]] || return 1
    [[ "${full_presets[(r)vibrant]}" == "vibrant" ]] || return 1
    [[ "${full_presets[(r)vibrant_tinted]}" == "vibrant_tinted" ]] || return 1
    
    return 0
}

# Test 3: Help text shows filtered list
function test_help_text_filtering() {
    local help_output
    help_output=$(todo help --full 2>&1)
    
    # Should show base presets
    [[ "$help_output" == *"balanced, loud, subtle, vibrant"* ]] || return 1
    
    # Should NOT show tinted variants in the main list
    [[ "$help_output" != *"balanced_tinted"* ]] || return 1
    
    return 0
}

# Test 4: Error messages show filtered list
function test_error_message_filtering() {
    local error_output
    error_output=$(todo config preset invalid_preset 2>&1)
    
    # Should show only base presets in error
    [[ "$error_output" == *"Available presets: balanced loud subtle vibrant"* ]] || return 1
    
    # Should include explanation
    [[ "$error_output" == *"Theme-adaptive variants are selected automatically"* ]] || return 1
    
    return 0
}

# Test 5: Tab completion consistency (hardcoded presets)
function test_tab_completion_consistency() {
    # This test checks that the hardcoded tab completion matches our filtered list
    local user_presets=($(todo_config_get_user_preset_names | sort))
    local expected=("balanced" "loud" "subtle" "vibrant")
    
    # Check all expected presets are in user list
    for preset in "${expected[@]}"; do
        [[ "${user_presets[(r)$preset]}" == "$preset" ]] || return 1
    done
    
    # Should be exactly 4 presets
    [[ ${#user_presets[@]} -eq 4 ]] || return 1
    
    return 0
}

# Test 6: Preset list variable uses filtered list
function test_preset_list_variable() {
    # _TODO_PRESET_LIST should use filtered list
    [[ "$_TODO_PRESET_LIST" == "balanced, loud, subtle, vibrant" ]] || return 1
    return 0
}

# Test 7: Help explanation about automatic selection
function test_help_explanation() {
    local help_output
    help_output=$(todo help --full 2>&1)
    
    # Should explain automatic tinted selection
    [[ "$help_output" == *"Theme-adaptive variants (_tinted) are selected automatically"* ]] || return 1
    [[ "$help_output" == *"when tinted-shell or tinty are detected"* ]] || return 1
    
    return 0
}

# Test 8: All base presets have tinted variants
function test_preset_coverage() {
    local user_presets=($(todo_config_get_user_preset_names))
    
    # Each base preset should have a corresponding tinted variant
    for preset in "${user_presets[@]}"; do
        local tinted_file="$(__todo_find_preset_file "${preset}_tinted")"
        [[ -f "$tinted_file" ]] || return 1
    done
    
    return 0
}

# Test 9: Tinted presets have correct format
function test_tinted_preset_format() {
    local user_presets=($(todo_config_get_user_preset_names))
    
    for preset in "${user_presets[@]}"; do
        local tinted_file="$(__todo_find_preset_file "${preset}_tinted")"
        [[ -f "$tinted_file" ]] || continue
        
        # Should contain TODO_USE_TINTED_COLORS flag
        grep -q "TODO_USE_TINTED_COLORS.*true" "$tinted_file" || return 1
        
        # Should use base16 colors (numbers 0-15 only)
        local colors=$(grep "TODO_TASK_COLORS" "$tinted_file" | cut -d'"' -f2)
        if [[ -n "$colors" ]]; then
            # Split colors and check each is 0-15
            IFS=',' read -A color_array <<< "$colors"
            for color in "${color_array[@]}"; do
                [[ "$color" =~ ^([0-9]|1[0-5])$ ]] || return 1
            done
        fi
    done
    
    return 0
}

# Test 10: Display consistency across interfaces
function test_display_consistency() {
    # Help text count
    local help_preset_count=$(echo "$_TODO_PRESET_LIST" | tr ',' '\n' | wc -l | tr -d ' ')
    
    # Error message count  
    local error_output=$(todo config preset invalid 2>&1)
    local error_preset_count=$(echo "$error_output" | grep "Available presets:" | cut -d: -f2 | wc -w | tr -d ' ')
    
    # Should be consistent
    [[ "$help_preset_count" -eq "$error_preset_count" ]] || return 1
    [[ "$help_preset_count" -eq 4 ]] || return 1
    
    return 0
}

# Test 11: Preset descriptions preserved
function test_preset_descriptions() {
    local user_presets=($(todo_config_get_user_preset_names))
    
    for preset in "${user_presets[@]}"; do
        local desc=$(todo_config_get_preset_description "$preset")
        [[ -n "$desc" ]] || return 1
    done
    
    return 0
}

# Test 12: Internal vs user functions distinction  
function test_function_distinction() {
    # Internal function should show all presets
    local internal_count=$(todo_config_get_preset_names | wc -l | tr -d ' ')
    
    # User function should show filtered presets
    local user_count=$(todo_config_get_user_preset_names | wc -l | tr -d ' ')
    
    # Internal should have more presets than user
    [[ "$internal_count" -gt "$user_count" ]] || return 1
    [[ "$internal_count" -eq 8 ]] || return 1  # 4 base + 4 tinted
    [[ "$user_count" -eq 4 ]] || return 1     # 4 base only
    
    return 0
}

# Test 13: Filtered list alphabetical order
function test_filtered_list_order() {
    local user_presets=($(todo_config_get_user_preset_names))
    local sorted_presets=($(printf '%s\n' "${user_presets[@]}" | sort))
    
    # Lists should be identical (already sorted)
    for i in {1..${#user_presets[@]}}; do
        [[ "${user_presets[$i]}" == "${sorted_presets[$i]}" ]] || return 1
    done
    
    return 0
}

# Test 14: Config help includes color configuration
function test_config_help_color_mode() {
    local help_output
    help_output=$(todo help --config 2>&1)
    
    # Should mention color configuration via config interface
    [[ "$help_output" == *"todo config get colors"* ]] || return 1
    
    return 0
}

# Run all tests
echo "🧪 Running Preset Filtering and Display Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

run_test "User preset list filters tinted variants" test_user_preset_filtering
run_test "Full preset list includes all variants" test_full_preset_list
run_test "Help text shows filtered list" test_help_text_filtering
run_test "Error messages show filtered list" test_error_message_filtering
run_test "Tab completion consistency" test_tab_completion_consistency
run_test "Preset list variable uses filtered list" test_preset_list_variable
run_test "Help explanation about automatic selection" test_help_explanation
run_test "All base presets have tinted variants" test_preset_coverage
run_test "Tinted presets have correct format" test_tinted_preset_format
run_test "Display consistency across interfaces" test_display_consistency
run_test "Preset descriptions preserved" test_preset_descriptions
run_test "Internal vs user functions distinction" test_function_distinction
run_test "Filtered list alphabetical order" test_filtered_list_order
run_test "Config help includes color-mode" test_config_help_color_mode

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Results: $passed_tests/$test_count tests passed"

if [[ $passed_tests -eq $test_count ]]; then
    echo "✅ All preset filtering tests passed!"
    exit 0
else
    echo "❌ Some preset filtering tests failed!"
    exit 1
fi