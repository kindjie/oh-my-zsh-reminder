#!/usr/bin/env zsh

# Shared test utilities for the reminder plugin test suite

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