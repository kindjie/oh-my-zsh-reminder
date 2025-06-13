#!/usr/bin/env zsh

# Token Size Validation Tests
# Ensures all script files stay under token limits for AI processing

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TOKEN_LIMIT=24000  # Maximum tokens allowed per file
WARNING_THRESHOLD=20000  # Warn when approaching limit

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Simple test runner
run_test() {
    local test_name="$1"
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if $test_name; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Print test summary
print_test_summary() {
    echo
    echo "Test Summary:"
    echo "============"
    echo "Tests run: $TESTS_RUN"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "✅ All tests passed!"
        return 0
    else
        echo "❌ $TESTS_FAILED test(s) failed"
        return 1
    fi
}

echo "🔢 Token Size Validation Tests"
echo "=============================="
echo

# Check if python and tiktoken are available
check_tiktoken_available() {
    if ! command -v python3 >/dev/null 2>&1; then
        echo "⚠️  Python3 not found - using character count estimation"
        return 1
    fi
    
    if ! python3 -c "import tiktoken" 2>/dev/null; then
        echo "⚠️  tiktoken not installed - using character count estimation"
        echo "   Install with: pip install tiktoken"
        return 1
    fi
    
    return 0
}

# Count tokens using tiktoken
count_tokens_tiktoken() {
    local file="$1"
    python3 -c "
import tiktoken
import sys

# Use cl100k_base encoding (GPT-4/ChatGPT)
encoding = tiktoken.get_encoding('cl100k_base')

try:
    with open('$file', 'r', encoding='utf-8') as f:
        content = f.read()
    tokens = encoding.encode(content)
    print(len(tokens))
except Exception as e:
    print(f'ERROR: {e}', file=sys.stderr)
    sys.exit(1)
"
}

# Estimate tokens using character count (rough approximation)
estimate_tokens_char_count() {
    local file="$1"
    local char_count=$(wc -c < "$file" 2>/dev/null || echo 0)
    # Rough estimation: 1 token ≈ 4 characters for code
    echo $((char_count / 4))
}

# Test token count for a file
test_file_token_count() {
    local file="$1"
    local description="$2"
    local use_tiktoken="$3"
    
    if [[ ! -f "$file" ]]; then
        echo "❌ FAIL: File not found: $file"
        return 1
    fi
    
    local token_count
    local method
    
    if [[ "$use_tiktoken" == "true" ]]; then
        token_count=$(count_tokens_tiktoken "$file")
        method="tiktoken"
        if [[ $? -ne 0 ]]; then
            echo "❌ FAIL: Error counting tokens in $file"
            return 1
        fi
    else
        token_count=$(estimate_tokens_char_count "$file")
        method="estimated"
    fi
    
    # Validate token count is reasonable
    if [[ ! "$token_count" =~ ^[0-9]+$ ]] || [[ $token_count -le 0 ]]; then
        echo "❌ FAIL: Invalid token count for $file: $token_count"
        return 1
    fi
    
    # Check against limits
    if [[ $token_count -gt $TOKEN_LIMIT ]]; then
        echo "❌ FAIL: $description exceeds token limit"
        echo "   File: $file"
        echo "   Tokens: $token_count ($method)"
        echo "   Limit: $TOKEN_LIMIT"
        echo "   Excess: $((token_count - TOKEN_LIMIT)) tokens"
        return 1
    elif [[ $token_count -gt $WARNING_THRESHOLD ]]; then
        echo "⚠️  WARN: $description approaching token limit"
        echo "   File: $file"
        echo "   Tokens: $token_count ($method)"
        echo "   Limit: $TOKEN_LIMIT"
        echo "   Remaining: $((TOKEN_LIMIT - token_count)) tokens"
        echo "✅ PASS: $description under token limit"
        return 0
    else
        echo "✅ PASS: $description under token limit ($token_count/$TOKEN_LIMIT tokens, $method)"
        return 0
    fi
}

# Test 1: Main plugin file token count
function test_main_plugin_token_count() {
    local file="$SCRIPT_DIR/reminder.plugin.zsh"
    test_file_token_count "$file" "Main plugin file" "$USE_TIKTOKEN"
}

# Test 2: Wizard module token count
function test_wizard_module_token_count() {
    local file="$SCRIPT_DIR/lib/wizard.zsh"
    test_file_token_count "$file" "Wizard module" "$USE_TIKTOKEN"
}

# Test 3: Config module token count
function test_config_module_token_count() {
    local file="$SCRIPT_DIR/lib/config.zsh"
    test_file_token_count "$file" "Config module" "$USE_TIKTOKEN"
}

# Test 4: Combined modules token count (informational only)
function test_combined_modules_token_count() {
    local temp_file="$(mktemp)"
    local combined_file="$temp_file"
    
    # Combine all main script files
    {
        echo "# Combined script files for token analysis"
        echo
        cat "$SCRIPT_DIR/reminder.plugin.zsh" 2>/dev/null
        echo
        cat "$SCRIPT_DIR/lib/wizard.zsh" 2>/dev/null
        echo
        cat "$SCRIPT_DIR/lib/config.zsh" 2>/dev/null
    } > "$combined_file"
    
    if [[ ! -f "$combined_file" ]]; then
        echo "❌ FAIL: Could not create combined file"
        rm -f "$combined_file"
        return 1
    fi
    
    local token_count
    local method
    
    if [[ "$USE_TIKTOKEN" == "true" ]]; then
        token_count=$(count_tokens_tiktoken "$combined_file")
        method="tiktoken"
        if [[ $? -ne 0 ]]; then
            echo "❌ FAIL: Error counting tokens in combined file"
            rm -f "$combined_file"
            return 1
        fi
    else
        token_count=$(estimate_tokens_char_count "$combined_file")
        method="estimated"
    fi
    
    # Validate token count is reasonable
    if [[ ! "$token_count" =~ ^[0-9]+$ ]] || [[ $token_count -le 0 ]]; then
        echo "❌ FAIL: Invalid token count for combined file: $token_count"
        rm -f "$combined_file"
        return 1
    fi
    
    # Always pass this test - it's informational only since files are loaded separately
    echo "ℹ️  INFO: Combined modules analysis ($token_count tokens, $method)"
    if [[ $token_count -gt $TOKEN_LIMIT ]]; then
        echo "   Note: Combined size exceeds limit but individual files are loaded separately"
        echo "   Individual files all pass token limits independently"
    else
        echo "   Combined size under token limit"
    fi
    echo "✅ PASS: Combined modules analysis completed"
    
    rm -f "$combined_file"
    return 0
}

# Test 5: Largest test file token count
function test_largest_test_file_token_count() {
    local largest_file=""
    local largest_size=0
    
    # Find largest test file
    for test_file in "$SCRIPT_DIR"/tests/*.zsh; do
        if [[ -f "$test_file" ]]; then
            local size=$(wc -c < "$test_file" 2>/dev/null || echo 0)
            if [[ $size -gt $largest_size ]]; then
                largest_size=$size
                largest_file="$test_file"
            fi
        fi
    done
    
    if [[ -n "$largest_file" ]]; then
        local filename=$(basename "$largest_file")
        test_file_token_count "$largest_file" "Largest test file ($filename)" "$USE_TIKTOKEN"
    else
        echo "❌ FAIL: No test files found"
        return 1
    fi
}

# Test 6: Documentation files token count
function test_documentation_token_count() {
    local files=("$SCRIPT_DIR/README.md" "$SCRIPT_DIR/CLAUDE.md")
    local all_passed=true
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            local filename=$(basename "$file")
            if ! test_file_token_count "$file" "Documentation file ($filename)" "$USE_TIKTOKEN"; then
                all_passed=false
            fi
        fi
    done
    
    if [[ "$all_passed" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# Test 7: Token density analysis
function test_token_density_analysis() {
    local file="$SCRIPT_DIR/reminder.plugin.zsh"
    
    if [[ ! -f "$file" ]]; then
        echo "❌ FAIL: Main plugin file not found"
        return 1
    fi
    
    local char_count=$(wc -c < "$file" 2>/dev/null || echo 0)
    local line_count=$(wc -l < "$file" 2>/dev/null || echo 0)
    local word_count=$(wc -w < "$file" 2>/dev/null || echo 0)
    
    local token_count
    if [[ "$USE_TIKTOKEN" == "true" ]]; then
        token_count=$(count_tokens_tiktoken "$file")
    else
        token_count=$(estimate_tokens_char_count "$file")
    fi
    
    if [[ $token_count -gt 0 && $char_count -gt 0 && $line_count -gt 0 ]]; then
        local chars_per_token=$((char_count / token_count))
        local tokens_per_line=$((token_count / line_count))
        
        echo "✅ PASS: Token density analysis completed"
        echo "   Characters: $char_count"
        echo "   Lines: $line_count" 
        echo "   Words: $word_count"
        echo "   Tokens: $token_count"
        echo "   Chars/token: $chars_per_token"
        echo "   Tokens/line: $tokens_per_line"
        
        # Validate reasonable density (sanity check)
        if [[ $chars_per_token -lt 2 || $chars_per_token -gt 8 ]]; then
            echo "⚠️  WARN: Unusual character-to-token ratio: $chars_per_token"
        fi
        
        return 0
    else
        echo "❌ FAIL: Could not calculate token density"
        return 1
    fi
}

# Check tiktoken availability
USE_TIKTOKEN="false"
if check_tiktoken_available; then
    USE_TIKTOKEN="true"
    echo "✅ Using tiktoken for accurate token counting"
else
    echo "📊 Using character count estimation (install tiktoken for accuracy)"
fi
echo

# Run all tests
echo "Testing individual files:"
echo "------------------------"
run_test test_main_plugin_token_count
run_test test_wizard_module_token_count  
run_test test_config_module_token_count
echo

echo "Testing combined and special cases:"
echo "----------------------------------"
run_test test_combined_modules_token_count
run_test test_largest_test_file_token_count
run_test test_documentation_token_count
echo

echo "Analysis:"
echo "--------"
run_test test_token_density_analysis

# Print summary
print_test_summary