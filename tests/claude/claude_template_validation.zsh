#!/usr/bin/env zsh
# 🧪 TEMPLATE FUNCTION TESTS - Test that Claude template functions work correctly
# Category: Template Function Validation (testing the tools themselves)
# Purpose: Verify template convenience functions use text parsing correctly

# Load shared prompt templates and test utilities
script_dir="${0:A:h}"
source "$script_dir/../claude_prompt_templates.zsh"
source "$script_dir/../test_utils.zsh"

# Use default model but with timeout for template validation tests
CLAUDE_MODEL="${CLAUDE_MODEL:-claude-3-5-sonnet-20241022}"

# Check if running from test runner (quieter output) or standalone (verbose output)
if [[ "$0" == *"claude_runner"* ]] || [[ -n "$CLAUDE_RUNNER_MODE" ]]; then
    QUIET_MODE=true
else
    QUIET_MODE=false
fi

if [[ "$QUIET_MODE" != "true" ]]; then
    echo "🧪 Claude Template Validation Tests - Using model: $CLAUDE_MODEL"
    echo "Testing all template convenience functions with designed pass/fail cases"
    echo
fi

# Fast-path mode for template validation
if [[ -n "$CLAUDE_FAST_MODE" ]] || [[ -n "$CI" ]]; then
    if [[ "$QUIET_MODE" != "true" ]]; then
        echo "✅ Template validation: Fast mode (skipping Claude CLI checks)"
        echo
    fi
else
    # Check Claude availability first
    if ! command -v claude >/dev/null 2>&1; then
        echo "❌ Claude Code CLI not available - skipping template validation"
        if [[ "$QUIET_MODE" != "true" ]]; then
            echo "Install Claude Code CLI to run these tests"
        fi
        exit 1
    fi

    # Test basic Claude functionality with shorter timeout
    if ! timeout 5 claude --model "$CLAUDE_MODEL" -p "Say: OK" --allowedTools= >/dev/null 2>&1; then
        echo "❌ Claude Code CLI not responding correctly - skipping template validation"
        exit 1
    fi

    if [[ "$QUIET_MODE" != "true" ]]; then
        echo "✅ Claude Code CLI available and functional"
        echo
    fi
fi

# Global test tracking
failed_count=0
temp_files=()

# Cleanup function
cleanup_temp_files() {
    for temp_file in "${temp_files[@]}"; do
        if [[ -f "$temp_file" ]]; then
            rm -f "$temp_file"
        fi
    done
    temp_files=()
}

# Trap to ensure cleanup on exit
trap cleanup_temp_files EXIT

# Test 1: run_validation_test function
test_run_validation_test() {
    local test_start_time=$(get_timestamp)
    if [[ "$QUIET_MODE" != "true" ]]; then
        echo "Testing run_validation_test convenience function..."
    fi
    
    # Create temp files
    local temp_fail="$TMPDIR/template_test_fail_$$"
    local temp_pass="$TMPDIR/template_test_pass_$$"
    temp_files+=("$temp_fail" "$temp_pass")
    
    # File designed to fail validation
    cat > "$temp_fail" << 'EOF'
# Broken File
This file has no proper structure.
Missing required sections.
No examples or documentation.
Should definitely fail validation.
EOF
    
    # File designed to pass validation  
    cat > "$temp_pass" << 'EOF'
# Well-Structured Documentation

## Overview
Clear and complete documentation with proper structure.

## Installation
```bash
# Install command here
npm install example
```

## Usage
```bash
# Usage examples
example --help
```

## Configuration
- Setting 1: Description
- Setting 2: Description

## Examples
Working examples with expected outputs.

This file should pass validation tests.
EOF
    
    if [[ "$QUIET_MODE" != "true" ]]; then
        echo "  🔍 Testing with file designed to fail..."
    fi
    local fail_test_start=$(get_timestamp)
    if [[ "$QUIET_MODE" == "true" ]]; then
        run_validation_test "intentional failure test" "complete documentation" "$temp_fail" "Must have installation, usage, examples, and configuration sections" "complete documentation with examples" >/dev/null 2>&1
        local validation_result=$?
    else
        run_validation_test "intentional failure test" "complete documentation" "$temp_fail" "Must have installation, usage, examples, and configuration sections" "complete documentation with examples"
        local validation_result=$?
    fi
    local fail_test_end=$(get_timestamp)
    local fail_test_duration=$(calculate_duration "$fail_test_start" "$fail_test_end")
    if [[ $validation_result -eq 0 ]]; then
        if [[ "$QUIET_MODE" != "true" ]]; then
            printf "  ❌ FAIL: run_validation_test should have failed but passed (%.2fs)\n" $fail_test_duration
        fi
        ((failed_count++))
    else
        if [[ "$QUIET_MODE" != "true" ]]; then
            printf "  ✅ PASS: run_validation_test correctly failed as expected (%.2fs)\n" $fail_test_duration
        fi
    fi
    
    if [[ "$QUIET_MODE" != "true" ]]; then
        echo "  🔍 Testing with file designed to pass..."
    fi
    local pass_test_start=$(get_timestamp)
    if [[ "$QUIET_MODE" == "true" ]]; then
        run_validation_test "intentional success test" "complete documentation" "$temp_pass" "Should have basic documentation structure" "acceptable documentation" >/dev/null 2>&1
        local validation_result=$?
    else
        run_validation_test "intentional success test" "complete documentation" "$temp_pass" "Should have basic documentation structure" "acceptable documentation"
        local validation_result=$?
    fi
    local pass_test_end=$(get_timestamp)
    local pass_test_duration=$(calculate_duration "$pass_test_start" "$pass_test_end")
    if [[ $validation_result -eq 0 ]]; then
        if [[ "$QUIET_MODE" != "true" ]]; then
            printf "  ✅ PASS: run_validation_test correctly passed as expected (%.2fs)\n" $pass_test_duration
        fi
    else
        if [[ "$QUIET_MODE" != "true" ]]; then
            printf "  ❌ FAIL: run_validation_test should have passed but failed (%.2fs)\n" $pass_test_duration
        fi
        ((failed_count++))
    fi
    
    local test_end_time=$(get_timestamp)
    local total_duration=$(calculate_duration "$test_start_time" "$test_end_time")
    if [[ "$QUIET_MODE" != "true" ]]; then
        printf "📊 test_run_validation_test completed in %.2fs\n" $total_duration
        echo
    fi
}

# Test 2: run_doc_evaluation function
test_run_doc_evaluation() {
    local test_start_time=$(get_timestamp)
    if [[ "$QUIET_MODE" != "true" ]]; then
        echo "Testing run_doc_evaluation convenience function..."
    fi
    
    # Create temp files
    local temp_fail="$TMPDIR/doc_eval_fail_$$"
    local temp_pass="$TMPDIR/doc_eval_pass_$$"
    temp_files+=("$temp_fail" "$temp_pass")
    
    # Simple file designed to fail quality (minimal content)
    cat > "$temp_fail" << 'EOF'
# bad
no content
EOF
    
    # File designed to pass quality (comprehensive structure)
    cat > "$temp_pass" << 'EOF'
# Template Function Test Documentation

## Overview
Comprehensive documentation with clear structure and complete information.

## Installation
```bash
npm install template-test
```

## Usage
```bash
template-test --validate
```

## Examples
Working examples with expected outputs.

## Configuration
- setting1: Description
- setting2: Description

## Technical Details
Complete and accurate technical information.
EOF
    
    if [[ "$QUIET_MODE" != "true" ]]; then
        echo "  🔍 Testing with real Claude template call..."
    fi
    
    # Test real template function with well-structured document (with timeout)
    local claude_call_start=$(get_timestamp)
    local result=$(run_doc_evaluation "$temp_pass" "test documentation")
    local claude_call_end=$(get_timestamp)
    local claude_call_duration=$(calculate_duration "$claude_call_start" "$claude_call_end")
    
    # Check that function produces valid output format (PASS or FAIL)
    if [[ "$result" == *"✅ PASS:"* ]] || [[ "$result" == *"❌ FAIL:"* ]]; then
        if [[ "$QUIET_MODE" != "true" ]]; then
            printf "  ✅ PASS: run_doc_evaluation produces valid output format (%.2fs)\n" $claude_call_duration
        fi
    else
        if [[ "$QUIET_MODE" != "true" ]]; then
            printf "  ❌ FAIL: run_doc_evaluation not producing expected format (%.2fs)\n" $claude_call_duration
            echo "  Result: $result"
        fi
        ((failed_count++))
    fi
    
    local test_end_time=$(get_timestamp)
    local total_duration=$(calculate_duration "$test_start_time" "$test_end_time")
    if [[ "$QUIET_MODE" != "true" ]]; then
        printf "📊 test_run_doc_evaluation completed in %.2fs\n" $total_duration
        echo
    fi
}

# Test 3: check_file_obsolescence function  
test_check_file_obsolescence() {
    local test_start_time=$(get_timestamp)
    if [[ "$QUIET_MODE" != "true" ]]; then
        echo "Testing check_file_obsolescence convenience function..."
    fi
    
    # Create temp files
    local temp_obsolete="$TMPDIR/obsolete_test_$$"
    temp_files+=("$temp_obsolete")
    
    # Simple file that should be clearly obsolete
    cat > "$temp_obsolete" << 'EOF'
# BACKUP FILE - DELETE AFTER TESTING
# This is a backup from 2020
# TODO: Remove this file - task completed in 2023
function old_function() {
    echo "deprecated - do not use"
}
EOF
    
    if [[ "$QUIET_MODE" != "true" ]]; then
        echo "  🔍 Testing with real Claude template call..."
    fi
    
    # Test real template function with clearly obsolete file (with timeout)
    local claude_call_start=$(get_timestamp)
    local result=$(check_file_obsolescence "$temp_obsolete" "backup file")
    local claude_call_end=$(get_timestamp)
    local claude_call_duration=$(calculate_duration "$claude_call_start" "$claude_call_end")
    
    # Check that function produces valid output format (OBSOLETE or CURRENT)
    if [[ "$result" == *"🗑️  OBSOLETE:"* ]] || [[ "$result" == *"📁 CURRENT:"* ]]; then
        if [[ "$QUIET_MODE" != "true" ]]; then
            printf "  ✅ PASS: check_file_obsolescence produces valid output format (%.2fs)\n" $claude_call_duration
        fi
    else
        if [[ "$QUIET_MODE" != "true" ]]; then
            printf "  ❌ FAIL: check_file_obsolescence not producing expected format (%.2fs)\n" $claude_call_duration
            echo "  Result: $result"
        fi
        ((failed_count++))
    fi
    
    local test_end_time=$(get_timestamp)
    local total_duration=$(calculate_duration "$test_start_time" "$test_end_time")
    if [[ "$QUIET_MODE" != "true" ]]; then
        printf "📊 test_check_file_obsolescence completed in %.2fs\n" $total_duration
        echo
    fi
}

# Test 4: analyze_temporary_sections function
test_analyze_temporary_sections() {
    local test_start_time=$(get_timestamp)
    if [[ "$QUIET_MODE" != "true" ]]; then
        echo "Testing analyze_temporary_sections convenience function..."
    fi
    
    # Create temp file
    local temp_sections="$TMPDIR/temp_sections_$$"
    temp_files+=("$temp_sections")
    
    # File with obvious temporary sections
    cat > "$temp_sections" << 'EOF'
#!/usr/bin/env zsh
function main() {
    # TODO: Fix this performance issue
    # FIXME: Memory leak here
    echo "processing"
    
    # HACK: Temporary workaround
    # DEBUG: Remove before production
    echo "debug info" >&2
}
EOF
    
    if [[ "$QUIET_MODE" != "true" ]]; then
        echo "  🔍 Testing with real Claude template call..."
    fi
    
    # Test real template function with file containing temporary sections (with timeout)
    local claude_call_start=$(get_timestamp)
    local result=$(analyze_temporary_sections "$temp_sections" "test file")
    local claude_call_end=$(get_timestamp)
    local claude_call_duration=$(calculate_duration "$claude_call_start" "$claude_call_end")
    
    # Check that function produces valid output format (CLEANUP_NEEDED or CLEAN)
    if [[ "$result" == *"⚠️  CLEANUP NEEDED:"* ]] || [[ "$result" == *"✨ CLEAN:"* ]]; then
        if [[ "$QUIET_MODE" != "true" ]]; then
            printf "  ✅ PASS: analyze_temporary_sections produces valid output format (%.2fs)\n" $claude_call_duration
        fi
    else
        if [[ "$QUIET_MODE" != "true" ]]; then
            printf "  ❌ FAIL: analyze_temporary_sections not producing expected format (%.2fs)\n" $claude_call_duration
            echo "  Result: $result"
        fi
        ((failed_count++))
    fi
    
    local test_end_time=$(get_timestamp)
    local total_duration=$(calculate_duration "$test_start_time" "$test_end_time")
    if [[ "$QUIET_MODE" != "true" ]]; then
        printf "📊 test_analyze_temporary_sections completed in %.2fs\n" $total_duration
        echo
    fi
}

# Run all template validation tests
if [[ "$QUIET_MODE" != "true" ]]; then
    echo "🚀 Starting template convenience function validation..."
    echo
fi

# Track overall script timing
script_start_time=$(get_timestamp)

test_run_validation_test
test_run_doc_evaluation  
test_check_file_obsolescence
test_analyze_temporary_sections

# Calculate total execution time
script_end_time=$(get_timestamp)
total_script_duration=$(calculate_duration "$script_start_time" "$script_end_time")

# Cleanup happens automatically via trap

# Final results
if [[ "$QUIET_MODE" == "true" ]]; then
    # Compact output for test runner
    if (( failed_count == 0 )); then
        echo "✅ 4 template function tests PASSED"
    else
        echo "❌ $failed_count/$((4)) template function tests FAILED"
    fi
else
    # Verbose output for standalone run
    echo "🎯 Template Function Test Results:"
    echo "=================================="
    
    if (( failed_count == 0 )); then
        echo "✅ All template convenience functions working correctly"
        echo "📊 Template functions tested: 4/4"
        echo "📝 Real Claude template integration: CONFIRMED"
        echo "⚡ Claude CLI integration: FUNCTIONAL"
        printf "⏱️  Total execution time: %.2fs\n" $total_script_duration
        echo "🧪 Category: Template Function Validation PASSED"
    else
        echo "❌ $failed_count template function issues found"
        echo "📊 Some template functions may have integration problems"
        printf "⏱️  Total execution time: %.2fs\n" $total_script_duration
        echo "🧪 Category: Template Function Validation FAILED"
    fi
fi

# Exit with appropriate code
if (( failed_count == 0 )); then
    exit 0
else
    exit 1
fi