#!/usr/bin/env zsh

# Meta-test: Pass test results to Claude CLI for pass/fail decision

# Check if Claude CLI is available
if ! command -v claude >/dev/null 2>&1; then
    echo "❌ ERROR: Claude CLI not found"
    exit 1
fi

# Run tests based on type
test_type="${1:-complete}"
case "$test_type" in
    functional) test_output=$(./tests/test.zsh --only-functional 2>&1) ;;
    ux) test_output=$(./tests/test.zsh --only-functional --skip-functional 2>&1 && ./tests/ux.zsh 2>&1) ;;
    documentation) test_output=$(./tests/test.zsh --only-functional --skip-functional 2>&1 && ./tests/documentation.zsh 2>&1) ;;
    performance) test_output=$(./tests/test.zsh --only-functional --skip-functional 2>&1 && ./tests/performance.zsh 2>&1) ;;
    complete) test_output=$(./tests/test.zsh 2>&1) ;;
    *) echo "Invalid test type: $test_type"; exit 1 ;;
esac

test_exit_code=$?

# Send to Claude with simple prompt
prompt="Analyze these test results. Respond with exactly 'PASS' or 'FAIL' based on overall quality.

Test results:
$test_output

Exit code: $test_exit_code"

claude_response=$(echo "$prompt" | timeout 30 claude 2>/dev/null)

# Check Claude response
if [[ "$claude_response" == *"PASS"* ]]; then
    echo "✅ PASS (Claude analysis)"
    exit 0
elif [[ "$claude_response" == *"FAIL"* ]]; then
    echo "❌ FAIL (Claude analysis)"
    exit 1
else
    echo "⚠️  UNKNOWN (Claude analysis unclear)"
    exit $test_exit_code  # Fall back to original exit code
fi