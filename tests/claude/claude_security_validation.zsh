#!/usr/bin/env zsh
# 🔍 PLUGIN VALIDATION TESTS - Use Claude templates to validate plugin security
# Category: Plugin Validation (using tools to test the plugin)
# Purpose: Detect security vulnerabilities and ensure safe practices

# Load shared prompt templates and test utilities
script_dir="${0:A:h}"
source "$script_dir/../claude_prompt_templates.zsh"
source "$script_dir/../test_utils.zsh"
source "$script_dir/../claude_timeout_helper.zsh"

echo "🤖 Claude Security Validation Tests - Using model: $CLAUDE_MODEL"

test_claude_comprehensive_security_audit() {
    echo "Running comprehensive security audit..."
    
    if command -v claude >/dev/null 2>&1; then
        local start_time=$(get_timestamp)
        local result=$(claude_call "Security check for zsh plugin:

Does this code use eval or unsafe source commands?
Pattern count: $(grep -c 'eval\|source.*\$' reminder.plugin.zsh lib/config.zsh 2>/dev/null || echo "0")

Response: '✅ PASS: no eval/unsafe source' or '❌ FAIL: found security issues'")
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
        if ! grep -E '(eval.*\$|source.*\$|\$\(.*\$)' *.zsh lib/*.zsh 2>/dev/null; then
            echo "✅ PASS: No obvious security vulnerabilities"
            return 0
        else
            echo "❌ FAIL: Found potential security issues"
            return 1
        fi
    fi
}

test_claude_input_sanitization() {
    echo "Testing input sanitization implementation..."
    
    if command -v claude >/dev/null 2>&1; then
        local start_time=$(get_timestamp)
        local result=$(claude_call "Input validation check:

User input methods: $(grep -c '\$1\|\$@\|read' reminder.plugin.zsh 2>/dev/null || echo "0") found
Uses printf %s: $(grep -c 'printf.*%s' reminder.plugin.zsh lib/*.zsh 2>/dev/null || echo "0") found

Question: Are user inputs handled safely?
Response: '✅ PASS: safe input handling' or '❌ FAIL: unsafe input handling'")
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
        if grep -q 'printf.*%s' *.zsh lib/*.zsh 2>/dev/null; then
            echo "✅ PASS: Found safe string formatting"
            return 0
        else
            echo "❌ FAIL: No obvious input sanitization found"
            return 1
        fi
    fi
}

test_claude_safe_configuration_parsing() {
    echo "Testing secure configuration file parsing..."
    
    if command -v claude >/dev/null 2>&1; then
        local start_time=$(get_timestamp)
        local result=$(claude_call "Analyze this config parsing code for security. Check that it uses manual parsing instead of dangerous 'source' commands.

$(grep -A 20 -B 5 '_todo_parse_config_file\|config.*parse' lib/config.zsh)

Response format: '✅ PASS: secure config parsing' or '❌ FAIL: unsafe config parsing'")
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
        if ! grep 'source.*config' lib/config.zsh >/dev/null 2>&1; then
            echo "✅ PASS: No dangerous config sourcing found"
            return 0
        else
            echo "❌ FAIL: Found potentially unsafe config parsing"
            return 1
        fi
    fi
}

# Run all tests with proper exit code tracking
failed_count=0

test_claude_comprehensive_security_audit || ((failed_count++))
test_claude_input_sanitization || ((failed_count++))
test_claude_safe_configuration_parsing || ((failed_count++))

# Exit with failure if any tests failed
if (( failed_count > 0 )); then
    echo "❌ $failed_count tests failed"
    exit 1
else
    echo "✅ All tests passed"
    exit 0
fi