#!/usr/bin/env zsh

# Test script for the modified reminder plugin
autoload -U colors
colors

# Source the plugin
source reminder.plugin.zsh

# Save current state and restore after test
backup_tasks=""
backup_colors=""

if [[ -f "$TODO_SAVE_TASKS_FILE" ]]; then
    backup_tasks="$(cat "$TODO_SAVE_TASKS_FILE")"
fi
if [[ -f "$TODO_SAVE_COLOR_FILE" ]]; then
    backup_colors="$(cat "$TODO_SAVE_COLOR_FILE")"
fi

# Create test data in temporary files to avoid overwriting user data
TEST_TASKS_FILE="${TMPDIR:-/tmp}/test_todo.sav"
TEST_COLORS_FILE="${TMPDIR:-/tmp}/test_todo_color.sav"

# Set up test data with new color system
echo "REMEMBER:Test task with some longer text that should wrap nicely within the box:Another shorter task:A third task to show multiple items" > "$TEST_TASKS_FILE"
echo $'\e[38;5;167m:\e[38;5;71m:\e[38;5;136m:\e[38;5;110m' > "$TEST_COLORS_FILE"
echo "5" >> "$TEST_COLORS_FILE"

# Temporarily override the save file paths for testing
original_tasks_file="$TODO_SAVE_TASKS_FILE"
original_colors_file="$TODO_SAVE_COLOR_FILE"
TODO_SAVE_TASKS_FILE="$TEST_TASKS_FILE"
TODO_SAVE_COLOR_FILE="$TEST_COLORS_FILE"

# Display the todos
echo "Testing the modified todo display:"
todo_display

# Restore original file paths
TODO_SAVE_TASKS_FILE="$original_tasks_file"
TODO_SAVE_COLOR_FILE="$original_colors_file"

# Clean up temporary test files
rm -f "$TEST_TASKS_FILE" "$TEST_COLORS_FILE"

# Original state is preserved (never modified)
echo "Test completed - original todo state preserved"