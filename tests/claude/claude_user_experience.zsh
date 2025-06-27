#!/usr/bin/env zsh
# 🔍 PLUGIN VALIDATION TESTS - Use Claude templates to validate plugin UX
# Category: Plugin Validation (using tools to test the plugin)
# Purpose: Ensure user experience meets design requirements

# Load shared prompt templates and test utilities
script_dir="${0:A:h}"
source "$script_dir/../claude_prompt_templates.zsh"
source "$script_dir/../test_utils.zsh"
source "$script_dir/../claude_timeout_helper.zsh"

echo "🤖 Claude User Experience Tests - Using model: $CLAUDE_MODEL"

test_claude_beginner_workflow_support() {
    echo "Testing beginner workflow support..."
    
    if command -v claude >/dev/null 2>&1; then
        local start_time=$(get_timestamp)
        local result=$(claude_call "Analyze this zsh plugin for beginner-friendly workflow. Check that new users can add tasks, remove tasks, and get help intuitively.

$(grep -A 10 -B 5 'todo help\|todo done\|todo_dispatcher' reminder.plugin.zsh | head -50)

Response format: '✅ PASS: beginner-friendly workflow' or '❌ FAIL: workflow barriers for beginners'")
        local end_time=$(get_timestamp)
        local duration=$(calculate_duration "$start_time" "$end_time")
        
        echo "$result"
        printf "(%.2fs)\n" "$duration"
        
        if [[ "$result" == *"✅ PASS:"* ]]; then
            return 0
        else
            return 1
        fi
    else
        echo "⚠️  Claude unavailable, using heuristic validation"
        if grep -q "todo help" reminder.plugin.zsh && grep -q "todo done" reminder.plugin.zsh; then
            echo "✅ PASS: Found basic beginner commands"
            return 0
        else
            echo "❌ FAIL: Missing beginner workflow commands"
            return 1
        fi
    fi
}

test_claude_power_user_customization() {
    echo "Testing power user customization..."
    
    if command -v claude >/dev/null 2>&1; then
        local start_time=$(get_timestamp)
        local result=$(claude_call "Analyze this zsh plugin for power user customization capabilities. Check for comprehensive config options, presets, and advanced features.

$(grep -E '(TODO_[A-Z_]+|todo config|preset|export|import)' reminder.plugin.zsh | head -30)

Response format: '✅ PASS: comprehensive power user features' or '❌ FAIL: limited customization options'")
        local end_time=$(get_timestamp)
        local duration=$(calculate_duration "$start_time" "$end_time")
        
        echo "$result"
        printf "(%.2fs)\n" "$duration"
        
        if [[ "$result" == *"✅ PASS:"* ]]; then
            return 0
        else
            return 1
        fi
    else
        echo "⚠️  Claude unavailable, using heuristic validation"
        if grep -q "todo config" reminder.plugin.zsh && grep -q "TODO_" reminder.plugin.zsh; then
            echo "✅ PASS: Found power user configuration options"
            return 0
        else
            echo "❌ FAIL: Missing power user customization features"
            return 1
        fi
    fi
}

test_claude_progressive_disclosure() {
    echo "Testing progressive disclosure implementation..."
    
    if command -v claude >/dev/null 2>&1; then
        local start_time=$(get_timestamp)
        local result=$(claude_call "Analyze this zsh plugin for progressive disclosure in help system. Check that basic help is simple while advanced help is comprehensive.

$(grep -A 20 -B 5 'todo help\|help.*full\|help.*more' reminder.plugin.zsh)

Response format: '✅ PASS: good progressive disclosure' or '❌ FAIL: poor information hierarchy'")
        local end_time=$(get_timestamp)
        local duration=$(calculate_duration "$start_time" "$end_time")
        
        echo "$result"
        printf "(%.2fs)\n" "$duration"
        
        if [[ "$result" == *"✅ PASS:"* ]]; then
            return 0
        else
            return 1
        fi
    else
        echo "⚠️  Claude unavailable, using heuristic validation"
        if grep -q "todo help" reminder.plugin.zsh && grep -E '(--full|--more)' reminder.plugin.zsh >/dev/null; then
            echo "✅ PASS: Found layered help system"
            return 0
        else
            echo "❌ FAIL: No progressive disclosure in help system"
            return 1
        fi
    fi
}

# Run all tests with proper exit code tracking
failed_count=0

test_claude_beginner_workflow_support || ((failed_count++))
test_claude_power_user_customization || ((failed_count++))
test_claude_progressive_disclosure || ((failed_count++))

# Exit with failure if any tests failed
if (( failed_count > 0 )); then
    echo "❌ $failed_count tests failed"
    exit 1
else
    echo "✅ All tests passed"
    exit 0
fi