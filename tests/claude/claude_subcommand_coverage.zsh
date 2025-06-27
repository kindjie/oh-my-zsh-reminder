#!/usr/bin/env zsh
# 🔍 PLUGIN VALIDATION TESTS - Use Claude templates to validate plugin completeness
# Category: Plugin Validation (using tools to test the plugin)
# Purpose: Ensure subcommand interface covers all functionality

# Load shared prompt templates and test utilities
script_dir="${0:A:h}"
source "$script_dir/../claude_prompt_templates.zsh"
source "$script_dir/../test_utils.zsh"
source "$script_dir/../claude_timeout_helper.zsh"

echo "🤖 Claude Subcommand Coverage Tests - Using model: $CLAUDE_MODEL"

test_claude_subcommand_completeness() {
    echo "Testing subcommand interface completeness..."
    
    if command -v claude >/dev/null 2>&1; then
        local start_time=$(get_timestamp)
        local result=$(claude_call "Analyze this zsh plugin for complete subcommand coverage. Check that ALL functionality is accessible via 'todo <subcommand>' pattern.

$(head -100 reminder.plugin.zsh)

Respond with exactly '✅ PASS:' or '❌ FAIL:' followed by brief explanation.")
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
        if grep -q "todo_dispatcher" reminder.plugin.zsh; then
            echo "✅ PASS: Found subcommand dispatcher"
            return 0
        else
            echo "❌ FAIL: No subcommand dispatcher found"
            return 1
        fi
    fi
}

test_claude_tab_completion_coverage() {
    echo "Testing tab completion coverage..."
    
    if command -v claude >/dev/null 2>&1; then
        local start_time=$(get_timestamp)
        local result=$(claude_call "Analyze this zsh plugin for comprehensive tab completion coverage. Check that ALL subcommands have proper tab completion.

$(grep -A 20 -B 5 '_todo_completion' reminder.plugin.zsh)

Response format: '✅ PASS: complete tab completion' or '❌ FAIL: missing completions for X'")
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
        if grep -q "_todo_completion" reminder.plugin.zsh && grep -q "compdef" reminder.plugin.zsh; then
            echo "✅ PASS: Found completion system"
            return 0
        else
            echo "❌ FAIL: No completion system found"
            return 1
        fi
    fi
}

test_claude_dispatcher_routing() {
    echo "Testing dispatcher routing completeness..."
    
    if command -v claude >/dev/null 2>&1; then
        local start_time=$(get_timestamp)
        local result=$(claude_call "Analyze this zsh plugin for complete dispatcher routing. Check that all subcommands are properly routed through dispatcher functions.

$(grep -A 30 'todo_dispatcher' reminder.plugin.zsh)

Response format: '✅ PASS: complete routing coverage' or '❌ FAIL: missing routes for X'")
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
        if grep -q "todo_dispatcher" reminder.plugin.zsh && grep -q "todo_config_dispatcher" reminder.plugin.zsh; then
            echo "✅ PASS: Found dispatcher functions"
            return 0
        else
            echo "❌ FAIL: No dispatcher functions found"
            return 1
        fi
    fi
}

# Run all tests with proper exit code tracking
failed_count=0

test_claude_subcommand_completeness || ((failed_count++))
test_claude_tab_completion_coverage || ((failed_count++))
test_claude_dispatcher_routing || ((failed_count++))

# Exit with failure if any tests failed
if (( failed_count > 0 )); then
    echo "❌ $failed_count tests failed"
    exit 1
else
    echo "✅ All tests passed"
    exit 0
fi