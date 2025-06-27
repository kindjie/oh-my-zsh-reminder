#!/usr/bin/env zsh
# Claude test runner - executes all Claude validation tests

set -e

# Load test utilities for portable timing
script_dir="$(dirname "$0")"
source "$script_dir/test_utils.zsh"

# Model configuration - explicitly specify model for transparency
CLAUDE_MODEL="claude-3-5-sonnet-20241022"
export CLAUDE_MODEL

# Set runner mode for cleaner output from individual tests
CLAUDE_RUNNER_MODE=true
export CLAUDE_RUNNER_MODE

echo "🤖 Claude Code Validation Test Suite"
echo "======================================"
echo "🤖 Using model: $CLAUDE_MODEL"

# Check Claude availability first
check_claude_availability() {
    if ! command -v claude >/dev/null 2>&1; then
        echo "❌ Claude Code CLI not available"
        echo "Please install Claude Code CLI to run validation tests"
        echo "See: https://docs.anthropic.com/en/docs/claude-code"
        return 1
    fi
    
    # Test basic Claude functionality with minimal prompt
    if ! claude --model "$CLAUDE_MODEL" -p "Exit 0 to confirm Claude CLI is working" --allowedTools= >/dev/null 2>&1; then
        echo "❌ Claude Code CLI not responding correctly"
        echo "Please check Claude Code CLI installation and configuration"
        return 1
    fi
    
    echo "✅ Claude Code CLI available and functional"
    return 0
}

# Check prerequisites
if ! check_claude_availability; then
    exit 1
fi

# Global test tracking
local total_tests=0
local passed_tests=0
local failed_tests=0

# Test categories - template validation runs first to verify Claude CLI integration
local test_files=(
    "claude_template_validation.zsh"
    "claude_namespace_validation.zsh"
    "claude_subcommand_coverage.zsh"
    "claude_architecture_purity.zsh"
    "claude_user_experience.zsh"
    "claude_security_validation.zsh"
    "claude_documentation_quality.zsh"
    "claude_obsolete_file_detection.zsh"
)

local tests_dir="$(dirname "$0")"

echo

# Concurrent test execution for faster results
echo "🚀 Starting concurrent Claude test execution..."
echo

# Arrays to track concurrent tests
local test_pids=()
local test_names=()
local test_start_times=()
local temp_files=()

# Start all tests concurrently
for test_file in $test_files; do
    local test_path="$tests_dir/claude/$test_file"
    
    if [[ -f "$test_path" ]]; then
        # Extract test type for cleaner display
        local test_type=$(echo "$test_file" | sed 's/claude_//' | sed 's/_validation//' | sed 's/_/ /g' | sed 's/.zsh//')
        
        echo "🔄 Starting $test_type..."
        
        # Create temporary file for this test's output
        local temp_output="/tmp/claude_test_$$_${#test_pids[@]}"
        temp_files+=("$temp_output")
        
        # Change to plugin directory for relative paths and run test in background
        (
            cd "$tests_dir/.."
            timeout 60 "$test_path" > "$temp_output" 2>&1
            echo $? > "${temp_output}.exit"
        ) &
        
        # Track this background job
        test_pids+=($!)
        test_names+=("$test_type")
        test_start_times+=($(get_timestamp))
        ((total_tests++))
    else
        echo "⚠️  Test file not found: $(basename "$test_file" .zsh)"
    fi
done

echo
echo "⏳ Waiting for ${#test_pids[@]} concurrent tests to complete..."

# Wait for tests to complete and collect results
for i in "${!test_pids[@]}"; do
    local pid="${test_pids[$i]}"
    local test_name="${test_names[$i]}"
    local start_time="${test_start_times[$i]}"
    local temp_output="${temp_files[$i]}"
    
    # Wait for this specific test to complete
    wait "$pid"
    
    local end_time=$(get_timestamp)
    local duration=$(calculate_duration "$start_time" "$end_time")
    
    # Read the exit code
    local exit_code
    if [[ -f "${temp_output}.exit" ]]; then
        exit_code=$(cat "${temp_output}.exit")
    else
        exit_code=1
    fi
    
    # Read the output
    local output
    if [[ -f "$temp_output" ]]; then
        output=$(cat "$temp_output")
    else
        output="No output captured"
    fi
    
    # Process results
    echo -n "🔍 $test_name: "
    
    if [[ $exit_code -eq 0 ]]; then
        # Extract test count from output if available
        local test_count=$(echo "$output" | grep -E "tests passed|PASSED" | head -1 | grep -o '[0-9]\+' | head -1)
        if [[ -n "$test_count" ]]; then
            printf "✅ %s tests (%.2fs)\n" "$test_count" "$duration"
        else
            printf "✅ PASSED (%.2fs)\n" "$duration"
        fi
        ((passed_tests++))
    else
        # Check for specific error types
        if echo "$output" | grep -q "Claude Code CLI not"; then
            echo "⚠️  SKIPPED (Claude CLI unavailable)"
        elif echo "$output" | grep -q "timed out\|timeout"; then
            echo "❌ TIMEOUT (>60s)"
        else
            printf "❌ FAILED (%.2fs)\n" "$duration"
            # Show first line of error for context
            local first_error=$(echo "$output" | grep -E "❌|FAIL|ERROR" | head -1 | cut -c1-60)
            if [[ -n "$first_error" ]]; then
                echo "   $first_error..."
            fi
        fi
        ((failed_tests++))
    fi
    
    # Clean up temp files
    rm -f "$temp_output" "${temp_output}.exit"
done

echo "======================================"
echo "Claude Validation Results:"
echo "✅ Passed: $passed_tests"
echo "❌ Failed: $failed_tests"
echo "📊 Total:  $total_tests"

if [[ $failed_tests -eq 0 && $total_tests -gt 0 ]]; then
    echo
    echo "🎉 All Claude validation tests passed!"
    exit 0
elif [[ $total_tests -eq 0 ]]; then
    echo
    echo "⚠️  No Claude validation tests found"
    exit 1
else
    echo
    echo "⚠️  Some Claude validation tests failed"
    exit 1
fi