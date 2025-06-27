#!/usr/bin/env zsh
# 🔍 PLUGIN VALIDATION TESTS - Use Claude templates to validate plugin architecture
# Category: Plugin Validation (using tools to test the plugin)
# Purpose: Detect namespace pollution and ensure clean plugin design

# Load shared prompt templates and test utilities
script_dir="${0:A:h}"
source "$script_dir/../claude_prompt_templates.zsh"
source "$script_dir/../test_utils.zsh"

echo "🤖 Claude Namespace Validation Tests - Using model: $CLAUDE_MODEL"

test_claude_no_function_pollution() {
    echo "Testing function namespace pollution..."
    
    # AI assessment with timeout fallback
    local requirements="- Only 'todo' function exposed to user shell
    - All internal functions use private _todo_* naming convention  
    - No legacy function names (todo_*, task_*) in user namespace
    - Library modules (lib/) expose no functions to user shell"
    
    if command -v claude >/dev/null 2>&1; then
        local start_time=$(get_timestamp)
        # Use background process with timeout instead of timeout command
        local claude_cmd="/Users/owx/.config/npm-global/bin/claude"
        local temp_result=$(mktemp)
        
        # Start Claude in background and kill after 15 seconds
        (
            echo "Analyze this zsh plugin for function namespace pollution. Check: $requirements

$(head -100 reminder.plugin.zsh)

Respond with exactly '✅ PASS:' or '❌ FAIL:' followed by brief explanation." | \
            "$claude_cmd" --model "$CLAUDE_MODEL" --allowedTools= 2>/dev/null > "$temp_result"
        ) &
        local claude_pid=$!
        
        # Wait up to 15 seconds for completion
        local waited=0
        while [[ $waited -lt 15 ]] && kill -0 $claude_pid 2>/dev/null; do
            sleep 1
            ((waited++))
        done
        
        # Kill if still running and read result
        if kill -0 $claude_pid 2>/dev/null; then
            kill $claude_pid 2>/dev/null
            local result="❌ FAIL: Claude timeout after 15 seconds"
        else
            local result=$(cat "$temp_result" 2>/dev/null || echo "❌ FAIL: Claude error")
        fi
        rm -f "$temp_result"
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
        # Fallback validation
        echo "⚠️  Claude unavailable, using heuristic validation"
        if grep -q "^todo_[a-zA-Z]" reminder.plugin.zsh || grep -q "^task_[a-zA-Z]" reminder.plugin.zsh; then
            echo "❌ FAIL: Found legacy function names in global scope"
            return 1
        else
            echo "✅ PASS: No obvious function namespace pollution detected"
            return 0
        fi
    fi
}

test_claude_no_variable_pollution() {
    echo "Testing variable namespace pollution..."
    
    # AI assessment with timeout fallback
    local requirements="- No TODO_* variables exposed to user shell
    - All configuration uses _TODO_INTERNAL_* private naming
    - No global variables polluting user environment
    - Clean plugin unloading without residual variables"
    
    if command -v claude >/dev/null 2>&1; then
        local start_time=$(get_timestamp)
        # Use background process with timeout
        local claude_cmd="/Users/owx/.config/npm-global/bin/claude"
        local temp_result=$(mktemp)
        
        (
            echo "Analyze this zsh plugin for variable namespace pollution. Check: $requirements

$(head -100 reminder.plugin.zsh)

Respond with exactly '✅ PASS:' or '❌ FAIL:' followed by brief explanation." | \
            "$claude_cmd" --model "$CLAUDE_MODEL" --allowedTools= 2>/dev/null > "$temp_result"
        ) &
        local claude_pid=$!
        
        local waited=0
        while [[ $waited -lt 15 ]] && kill -0 $claude_pid 2>/dev/null; do
            sleep 1
            ((waited++))
        done
        
        if kill -0 $claude_pid 2>/dev/null; then
            kill $claude_pid 2>/dev/null
            local result="❌ FAIL: Claude timeout after 15 seconds"
        else
            local result=$(cat "$temp_result" 2>/dev/null || echo "❌ FAIL: Claude error")
        fi
        rm -f "$temp_result"
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
        # Fallback validation
        echo "⚠️  Claude unavailable, using heuristic validation"
        if grep -q "^export TODO_" reminder.plugin.zsh; then
            echo "❌ FAIL: Found TODO_ variable exports"
            return 1
        else
            echo "✅ PASS: No obvious variable namespace pollution detected"
            return 0
        fi
    fi
}

test_claude_pure_subcommand_interface() {
    echo "Testing pure subcommand interface..."
    
    # AI assessment with timeout fallback
    local requirements="- ALL functionality accessible through 'todo <subcommand>' pattern
    - No direct function calls required by users
    - Consistent command routing through dispatcher
    - Complete tab completion for all subcommands"
    
    if command -v claude >/dev/null 2>&1; then
        local start_time=$(get_timestamp)
        # Use background process with timeout
        local claude_cmd="/Users/owx/.config/npm-global/bin/claude"
        local temp_result=$(mktemp)
        
        (
            echo "Analyze this zsh plugin for pure subcommand interface. Check: $requirements

$(head -100 reminder.plugin.zsh)

Respond with exactly '✅ PASS:' or '❌ FAIL:' followed by brief explanation." | \
            "$claude_cmd" --model "$CLAUDE_MODEL" --allowedTools= 2>/dev/null > "$temp_result"
        ) &
        local claude_pid=$!
        
        local waited=0
        while [[ $waited -lt 15 ]] && kill -0 $claude_pid 2>/dev/null; do
            sleep 1
            ((waited++))
        done
        
        if kill -0 $claude_pid 2>/dev/null; then
            kill $claude_pid 2>/dev/null
            local result="❌ FAIL: Claude timeout after 15 seconds"
        else
            local result=$(cat "$temp_result" 2>/dev/null || echo "❌ FAIL: Claude error")
        fi
        rm -f "$temp_result"
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
        # Fallback validation
        echo "⚠️  Claude unavailable, using heuristic validation"
        if grep -q "todo_dispatcher" reminder.plugin.zsh && grep -q "case.*\$1" reminder.plugin.zsh; then
            echo "✅ PASS: Found dispatcher pattern for subcommands"
            return 0
        else
            echo "❌ FAIL: No clear subcommand dispatcher found"
            return 1
        fi
    fi
}

# Run all tests with proper exit code tracking
failed_count=0

test_claude_no_function_pollution || ((failed_count++))
test_claude_no_variable_pollution || ((failed_count++))
test_claude_pure_subcommand_interface || ((failed_count++))

# Exit with failure if any tests failed
if (( failed_count > 0 )); then
    echo "❌ $failed_count tests failed"
    exit 1
else
    echo "✅ All tests passed"
    exit 0
fi