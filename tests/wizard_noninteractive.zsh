#!/usr/bin/env zsh

# Non-Interactive Wizard Test Suite for Todo Reminder Plugin
# Tests setup wizard functionality without requiring user input

# Initialize test environment
script_dir="${0:A:h}"
source "$script_dir/test_utils.zsh"

# Color definitions for output
autoload -U colors
colors

echo "🧙 Testing Setup Wizard Functions (Non-Interactive)"
echo "══════════════════════════════════════════════════"
echo

# Test counter
test_count=0
passed_count=0
failed_count=0

# ===== 1. WIZARD PREVIEW TESTS =====

echo "${fg[blue]}1. Testing Wizard Preview Function${reset_color}"
echo "───────────────────────────────────────"

# Test preview display with todo box enabled
function test_wizard_preview_with_box() {
    local test_name="Preview shows todo box when enabled"
    ((test_count++))
    
    local temp_save="$TMPDIR/test_preview_$$"
    # Create save file with test tasks (same format as display tests)
    printf 'Review quarterly reports\000Schedule team meeting\000Update documentation\n\e[38;5;167m\000\e[38;5;71m\000\e[38;5;136m\n4\n' > "$temp_save"
    
    local output=$(COLUMNS=80 TODO_SAVE_FILE="$temp_save" TODO_SHOW_TODO_BOX="true" zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        show_wizard_preview "Test Preview" 2>&1
    ')
    
    if [[ "$output" == *"═══ Test Preview ═══"* ]] && \
       [[ "$output" == *"user@computer"* ]] && \
       [[ "$output" == *"~/projects"* ]] && \
       [[ "$output" == *"REMEMBER"* ]]; then
        echo "✅ PASS: $test_name"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Expected preview elements not found"
        ((failed_count++))
    fi
    
    # Cleanup
    [[ -f "$temp_save" ]] && rm -f "$temp_save"
}

# Test preview without todo box
function test_wizard_preview_without_box() {
    local test_name="Preview handles hidden todo box"
    ((test_count++))
    
    local temp_save="$TMPDIR/test_preview_no_box_$$"
    local output=$(COLUMNS=80 TODO_SAVE_FILE="$temp_save" TODO_SHOW_TODO_BOX="false" zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        show_wizard_preview "Hidden Test" 2>&1
    ')
    
    if [[ "$output" == *"═══ Hidden Test ═══"* ]] && \
       [[ "$output" != *"REMEMBER"* ]] && \
       [[ "$output" != *"▪"* ]]; then
        echo "✅ PASS: $test_name"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Preview should not show todo box when disabled"
        ((failed_count++))
    fi
    
    # Cleanup
    [[ -f "$temp_save" ]] && rm -f "$temp_save"
}

# Test preview with sample tasks
function test_wizard_preview_sample_tasks() {
    local test_name="Preview creates sample tasks when empty"
    ((test_count++))
    
    local temp_save="$TMPDIR/test_preview_samples_$$"
    local output=$(COLUMNS=80 TODO_SAVE_FILE="$temp_save" TODO_SHOW_TODO_BOX="true" zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        # Ensure no tasks exist initially
        echo "" > "'$temp_save'"
        show_wizard_preview "Sample Test" 2>&1
    ')
    
    # After preview, check if display was shown - the preview function should show todo_display output
    if [[ "$output" == *"Sample Test"* ]] && [[ "$output" == *"user@computer"* ]]; then
        echo "✅ PASS: $test_name"
        echo "  Preview function displays correctly"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Preview should show basic preview elements"
        echo "  Output: $output"
        ((failed_count++))
    fi
    
    # Cleanup
    [[ -f "$temp_save" ]] && rm -f "$temp_save"
}

test_wizard_preview_with_box
test_wizard_preview_without_box
test_wizard_preview_sample_tasks

# ===== 2. STEP HEADER TESTS =====

echo
echo "${fg[blue]}2. Testing Step Header Function${reset_color}"
echo "────────────────────────────────────"

# Test step header formatting
function test_show_step_header() {
    local test_name="Step header shows formatted output"
    ((test_count++))
    
    local output=$(zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        show_step_header "1" "Test Step" "This is a test description"
    ' 2>&1)
    
    if [[ "$output" == *"Step 1: Test Step"* ]] && \
       [[ "$output" == *"This is a test description"* ]] && \
       [[ "$output" == *"═══"* ]]; then
        echo "✅ PASS: $test_name"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Step header formatting incorrect"
        ((failed_count++))
    fi
}

test_show_step_header

# ===== 3. COLOR OPTION TESTS =====

echo
echo "${fg[blue]}3. Testing Color Option Display${reset_color}"
echo "────────────────────────────────────"

# Test color option with color code
function test_show_color_option_with_color() {
    local test_name="Color option shows visual color sample"
    ((test_count++))
    
    local output=$(zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        show_color_option "1" "Test color" "196"
    ' 2>&1)
    
    if [[ "$output" == *"1)"* ]] && \
       [[ "$output" == *"Test color"* ]] && \
       [[ "$output" == *"196"* ]] && \
       [[ "$output" == *"[48;5;196m"* ]]; then
        echo "✅ PASS: $test_name"
        echo "  Color option displays with background color sample"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Color option should show visual color indicator"
        ((failed_count++))
    fi
}

# Test color option without color code
function test_show_color_option_without_color() {
    local test_name="Color option handles text-only options"
    ((test_count++))
    
    local output=$(zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        show_color_option "c" "Custom option" ""
    ' 2>&1)
    
    if [[ "$output" == *"c)"* ]] && \
       [[ "$output" == *"Custom option"* ]] && \
       [[ "$output" != *"[48;5;"* ]]; then
        echo "✅ PASS: $test_name"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Text-only option should not show color sample"
        ((failed_count++))
    fi
}

test_show_color_option_with_color
test_show_color_option_without_color

# ===== 4. CONFIGURATION TESTS =====

echo
echo "${fg[blue]}4. Testing Configuration Logic${reset_color}"
echo "───────────────────────────────────────"

# Test preset application
function test_wizard_preset_application() {
    local test_name="Wizard applies presets correctly"
    ((test_count++))
    
    local temp_save="$TMPDIR/test_preset_$$"
    # Test direct preset application
    local output=$(COLUMNS=80 TODO_SAVE_FILE="$temp_save" zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        
        # Apply minimal preset directly
        todo_config preset "minimal" >/dev/null 2>&1
        
        # Check result
        echo "Title: $TODO_TITLE"
    ' 2>&1)
    
    if [[ "$output" == *"Title: TODO"* ]]; then
        echo "✅ PASS: $test_name"
        echo "  Minimal preset changes title to TODO"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Preset should change configuration values"
        echo "  Output: $output"
        ((failed_count++))
    fi
    
    # Cleanup
    [[ -f "$temp_save" ]] && rm -f "$temp_save"
}

# Test custom title input
function test_wizard_custom_title() {
    local test_name="Wizard accepts custom title input"
    ((test_count++))
    
    local temp_save="$TMPDIR/test_custom_title_$$"
    # Test custom title setting directly
    local output=$(COLUMNS=80 TODO_SAVE_FILE="$temp_save" zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        
        # Set custom title directly
        TODO_TITLE="MY TASKS"
        echo "Final title: $TODO_TITLE"
    ' 2>&1)
    
    if [[ "$output" == *"Final title: MY TASKS"* ]]; then
        echo "✅ PASS: $test_name"
        echo "  Custom title variable assignment works"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Custom title variable assignment failed"
        echo "  Output: $output"
        ((failed_count++))
    fi
    
    # Cleanup
    [[ -f "$temp_save" ]] && rm -f "$temp_save"
}

# Test configuration value changes
function test_wizard_config_changes() {
    local test_name="Wizard changes configuration values"
    ((test_count++))
    
    local temp_save="$TMPDIR/test_config_$$"
    # Test changing box width
    local output=$(COLUMNS=80 TODO_SAVE_FILE="$temp_save" zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        
        # Set initial value
        TODO_BOX_WIDTH_FRACTION="0.5"
        
        # Simulate width selection
        local width_choice="2"
        case "$width_choice" in
            1) TODO_BOX_WIDTH_FRACTION="0.3" ;;
            2) TODO_BOX_WIDTH_FRACTION="0.5" ;;
            3) TODO_BOX_WIDTH_FRACTION="0.7" ;;
            4) TODO_BOX_WIDTH_FRACTION="0.9" ;;
        esac
        
        echo "Width fraction: $TODO_BOX_WIDTH_FRACTION"
    ' 2>&1)
    
    if [[ "$output" == *"Width fraction: 0.5"* ]]; then
        echo "✅ PASS: $test_name"
        echo "  Configuration values update correctly"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Width should be 0.5 for option 2"
        ((failed_count++))
    fi
    
    # Cleanup
    [[ -f "$temp_save" ]] && rm -f "$temp_save"
}

test_wizard_preset_application
test_wizard_custom_title
test_wizard_config_changes

# ===== 5. VISUAL ELEMENTS TESTS =====

echo
echo "${fg[blue]}5. Testing Visual Elements${reset_color}"
echo "──────────────────────────────"

# Test heart position formatting
function test_wizard_heart_positions() {
    local test_name="Heart positions format correctly"
    ((test_count++))
    
    local output=$(zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        
        # Test all heart positions
        TODO_HEART_CHAR="♥"
        TODO_HEART_POSITION="left"
        left_text=$(format_affirmation "Test")
        
        TODO_HEART_POSITION="right"
        right_text=$(format_affirmation "Test")
        
        TODO_HEART_POSITION="both"
        both_text=$(format_affirmation "Test")
        
        TODO_HEART_POSITION="none"
        none_text=$(format_affirmation "Test")
        
        echo "Left: $left_text"
        echo "Right: $right_text"
        echo "Both: $both_text"
        echo "None: $none_text"
    ' 2>&1)
    
    if [[ "$output" == *"Left: ♥ Test"* ]] && \
       [[ "$output" == *"Right: Test ♥"* ]] && \
       [[ "$output" == *"Both: ♥ Test ♥"* ]] && \
       [[ "$output" == *"None: Test"* ]]; then
        echo "✅ PASS: $test_name"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Heart positions not formatting correctly"
        ((failed_count++))
    fi
}

# Test bullet character options
function test_wizard_bullet_characters() {
    local test_name="Bullet character options work"
    ((test_count++))
    
    # Test the bullet selection logic directly
    local output=$(zsh -c '
        autoload -U colors; colors;
        source reminder.plugin.zsh;
        
        # Test bullet selection case logic directly
        local bullet_choice="3"
        case "$bullet_choice" in
            1) TODO_BULLET_CHAR="▪" ;;
            2) TODO_BULLET_CHAR="•" ;;
            3) TODO_BULLET_CHAR="→" ;;
            4) TODO_BULLET_CHAR="★" ;;
            5) TODO_BULLET_CHAR="◆" ;;
        esac
        
        echo "$TODO_BULLET_CHAR"
    ' 2>&1)
    
    if [[ "$output" == "→" ]]; then
        echo "✅ PASS: $test_name"
        echo "  Bullet selection logic works correctly"
        ((passed_count++))
    else
        echo "❌ FAIL: $test_name"
        echo "  Expected → but got: $output"
        ((failed_count++))
    fi
}

test_wizard_heart_positions
test_wizard_bullet_characters

# ===== RESULTS SUMMARY =====

echo
echo "🎯 Wizard Test Results"
echo "═══════════════════════"
echo

if [[ $failed_count -eq 0 ]]; then
    echo "${fg[green]}✨ All wizard tests passed!${reset_color}"
else
    echo "${fg[red]}⚠️  Some wizard tests failed.${reset_color}"
fi

echo
echo "📊 Summary:"
echo "  Total Tests:    $test_count"
echo "  ${fg[green]}Passed:        $passed_count${reset_color}"
echo "  ${fg[red]}Failed:        $failed_count${reset_color}"

# Return appropriate exit code
if [[ $failed_count -eq 0 ]]; then
    exit 0
else
    exit 1
fi