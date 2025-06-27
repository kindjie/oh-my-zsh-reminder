#!/usr/bin/env zsh
# 🔧 Claude Timeout Helper - Reliable Claude CLI calls with timeout
# This helper solves the issue where `timeout` command doesn't work with Claude CLI path

# Function to call Claude with reliable timeout
# Usage: claude_with_timeout <timeout_seconds> <prompt>
claude_with_timeout() {
    local timeout_seconds="$1"
    local prompt="$2"
    local claude_cmd="/Users/owx/.config/npm-global/bin/claude"
    local temp_result=$(mktemp)
    
    # Start Claude in background
    (
        echo "$prompt" | "$claude_cmd" --model "$CLAUDE_MODEL" --allowedTools= 2>/dev/null > "$temp_result"
    ) &
    local claude_pid=$!
    
    # Wait up to timeout_seconds for completion
    local waited=0
    while [[ $waited -lt $timeout_seconds ]] && kill -0 $claude_pid 2>/dev/null; do
        sleep 1
        ((waited++))
    done
    
    # Kill if still running and read result
    local result
    if kill -0 $claude_pid 2>/dev/null; then
        kill $claude_pid 2>/dev/null
        result="❌ FAIL: Claude timeout after ${timeout_seconds} seconds"
    else
        result=$(cat "$temp_result" 2>/dev/null || echo "❌ FAIL: Claude error")
    fi
    
    # Cleanup and return result
    rm -f "$temp_result"
    echo "$result"
}

# Function to call Claude with standard 15-second timeout
# Usage: claude_call <prompt>
claude_call() {
    claude_with_timeout 15 "$1"
}

# Function to call Claude with extended 30-second timeout for complex analysis
# Usage: claude_call_extended <prompt>
claude_call_extended() {
    claude_with_timeout 30 "$1"
}