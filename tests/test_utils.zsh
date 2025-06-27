#!/usr/bin/env zsh

# Shared test utilities for the reminder plugin test suite

# Portable timing functions that work regardless of EPOCHREALTIME availability
get_timestamp() {
    # Use EPOCHREALTIME if available, otherwise fall back to date
    if [[ -n "$EPOCHREALTIME" ]]; then
        echo "$EPOCHREALTIME"
    else
        date +%s.%N 2>/dev/null || date +%s
    fi
}

calculate_duration() {
    local start_time="$1"
    local end_time="$2"
    
    # Use bc if available for high precision, otherwise use shell arithmetic
    if command -v bc >/dev/null 2>&1; then
        echo "$end_time - $start_time" | bc
    else
        # Shell arithmetic - works for integer seconds
        local duration=$((${end_time%.*} - ${start_time%.*}))
        echo "$duration"
    fi
}

# Timing and test tracking utilities
init_test_timing() {
    script_start_time=$(get_timestamp)
    total_tests=0
    passed_tests=0
}

# Function to wrap a test with timing
timed_test() {
    local test_name="$1"
    local test_function="$2"
    
    local test_start_time=$(get_timestamp)
    echo "\n${test_name}:"
    
    # Call the test function
    $test_function
    
    local test_end_time=$(get_timestamp)
    local test_duration=$(calculate_duration "$test_start_time" "$test_end_time")
    printf "📊 %s completed in %.3fs\n" "${test_function}" $test_duration
}

# Function to increment test counters (call after each assertion)
count_test() {
    local result="$1"  # "pass" or "fail"
    ((total_tests++))
    if [[ "$result" == "pass" ]]; then
        ((passed_tests++))
    fi
}

# Function to show final test summary with timing
finalize_test_timing() {
    local script_end_time=$(get_timestamp)
    local total_duration=$(calculate_duration "$script_start_time" "$script_end_time")
    
    printf "\n📊 Results: %d/%d tests passed\n" $passed_tests $total_tests
    printf "⏱️  Total execution time: %.3fs\n" $total_duration
    
    # Return appropriate exit code
    if (( passed_tests == total_tests )); then
        return 0
    else
        return 1
    fi
}

# Test setup - shared test helper functions
source_test_plugin() {
    autoload -U colors
    colors
    source reminder.plugin.zsh
}

# Setup test data for tests that need it
setup_test_data() {
    # Save original state
    original_save_file="$TODO_SAVE_FILE"
    original_affirmation_file="$TODO_AFFIRMATION_FILE"
    
    # Use temp files for testing
    TODO_SAVE_FILE="${TMPDIR:-/tmp}/test_todo_save.$$"
    TODO_AFFIRMATION_FILE="${TMPDIR:-/tmp}/test_affirmation.$$"
    
    # Clear any existing tasks
    todo_tasks=()
    todo_tasks_colors=()
    todo_color_index=1
    
    # Export for subprocesses
    export TODO_SAVE_FILE
    export TODO_AFFIRMATION_FILE
}

# Cleanup test data
cleanup_test_data() {
    # Clean up temp files
    [[ -f "$TODO_SAVE_FILE" ]] && rm -f "$TODO_SAVE_FILE"
    [[ -f "$TODO_AFFIRMATION_FILE" ]] && rm -f "$TODO_AFFIRMATION_FILE"
    
    # Restore original state if saved
    if [[ -n "$original_save_file" ]]; then
        TODO_SAVE_FILE="$original_save_file"
        TODO_AFFIRMATION_FILE="$original_affirmation_file"
        export TODO_SAVE_FILE
        export TODO_AFFIRMATION_FILE
    fi
}

# Common test data
get_test_tasks() {
    echo "Buy groceries
Walk the dog
Finish project
Read book"
}

# Helper to count lines in output
count_lines() {
    echo "$1" | wc -l | tr -d ' '
}

# Helper to strip ANSI color codes
strip_ansi() {
    echo "$1" | sed 's/\x1b\[[0-9;]*m//g'
}

# Helper to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Test if terminal supports colors
supports_colors() {
    [[ -t 1 ]] && [[ "${TERM}" != "dumb" ]]
}

# Helper for testing in specific terminal width
with_columns() {
    local cols="$1"
    shift
    COLUMNS="$cols" "$@"
}