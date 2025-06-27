#!/usr/bin/env zsh
# 🔍 PLUGIN VALIDATION TESTS - Use Claude templates to validate plugin architecture
# Category: Plugin Validation (using tools to test the plugin)
# Purpose: Ensure architectural purity and clean design patterns

# Load shared prompt templates and test utilities
script_dir="${0:A:h}"
source "$script_dir/../claude_prompt_templates.zsh"
source "$script_dir/../test_utils.zsh"
source "$script_dir/../claude_timeout_helper.zsh"

echo "🤖 Claude Architecture Purity Tests - Using model: $CLAUDE_MODEL"

test_claude_no_legacy_function_exposure() {
    echo "Testing legacy function exposure..."
    
    if command -v claude >/dev/null 2>&1; then
        local start_time=$(get_timestamp)
        local result=$(claude_call "Analyze this zsh plugin for legacy function exposure. Check that no old todo_* or task_* functions are accessible to users.

$(head -200 reminder.plugin.zsh | grep -E '(function|^[a-zA-Z_][a-zA-Z0-9_]*\(\))')

Response format: '✅ PASS: no legacy functions exposed' or '❌ FAIL: found exposed legacy functions'")
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
        if ! grep -E '^(task_|todo_[^_])' reminder.plugin.zsh >/dev/null; then
            echo "✅ PASS: No obvious legacy function exposure"
            return 0
        else
            echo "❌ FAIL: Found potential legacy function exposure"
            return 1
        fi
    fi
}

test_claude_internal_function_privacy() {
    echo "Testing internal function privacy..."
    
    if command -v claude >/dev/null 2>&1; then
        local start_time=$(get_timestamp)
        local result=$(claude_call "Analyze this zsh plugin for internal function privacy. Check that all internal functions use _todo_* naming convention and are properly encapsulated.

$(find . -name '*.zsh' -exec grep -H -E '^[a-zA-Z_][a-zA-Z0-9_]*\(\)' {} \; | head -50)

Response format: '✅ PASS: proper internal function privacy' or '❌ FAIL: found privacy violations'")
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
        if grep -q "_todo_" *.zsh lib/*.zsh 2>/dev/null; then
            echo "✅ PASS: Found internal function naming convention"
            return 0
        else
            echo "❌ FAIL: No internal function naming convention found"
            return 1
        fi
    fi
}

test_claude_clean_plugin_lifecycle() {
    echo "Testing clean plugin lifecycle..."
    
    if command -v claude >/dev/null 2>&1; then
        local start_time=$(get_timestamp)
        local result=$(claude_call "Analyze this zsh plugin for clean lifecycle management. Check that it loads without namespace pollution and can be unloaded cleanly.

$(grep -E '(precmd|preexec|^function|^[a-zA-Z_][a-zA-Z0-9_]*\(\))' reminder.plugin.zsh | head -30)

Response format: '✅ PASS: clean plugin lifecycle' or '❌ FAIL: found lifecycle issues'")
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
        if grep -q "precmd" reminder.plugin.zsh && ! grep -q "global" reminder.plugin.zsh; then
            echo "✅ PASS: Plugin uses hooks without obvious global pollution"
            return 0
        else
            echo "❌ FAIL: Plugin lifecycle concerns detected"
            return 1
        fi
    fi
}

# Run all tests with proper exit code tracking
failed_count=0

test_claude_no_legacy_function_exposure || ((failed_count++))
test_claude_internal_function_privacy || ((failed_count++))
test_claude_clean_plugin_lifecycle || ((failed_count++))

# Exit with failure if any tests failed
if (( failed_count > 0 )); then
    echo "❌ $failed_count tests failed"
    exit 1
else
    echo "✅ All tests passed"
    exit 0
fi