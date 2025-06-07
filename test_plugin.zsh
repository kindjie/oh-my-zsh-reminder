#!/usr/bin/env zsh

# Test script for the modified reminder plugin
autoload -U colors
colors

# Source the plugin
source reminder.plugin.zsh

# Save current state and restore after test
backup_tasks=""
backup_colors=""
backup_color_index=""

if [[ -f "$TODO_SAVE_TASKS_FILE" ]]; then
    backup_tasks="$(cat "$TODO_SAVE_TASKS_FILE")"
fi
if [[ -f "$TODO_SAVE_COLOR_FILE" ]]; then
    backup_colors="$(cat "$TODO_SAVE_COLOR_FILE")"
fi

# Set up test data  
echo "REMEMBER:Test task with some longer text that should wrap nicely within the box:Another shorter task:A third task to show multiple items" > "$TODO_SAVE_TASKS_FILE"
echo "${fg[red]}:${fg[green]}:${fg[yellow]}:${fg[blue]}" > "$TODO_SAVE_COLOR_FILE"
echo "1" >> "$TODO_SAVE_COLOR_FILE"

# Display the todos
echo "Testing the modified todo display:"
todo_display

# Restore original state
if [[ -n "$backup_tasks" ]]; then
    echo "$backup_tasks" > "$TODO_SAVE_TASKS_FILE"
else
    rm -f "$TODO_SAVE_TASKS_FILE"
fi

if [[ -n "$backup_colors" ]]; then
    echo "$backup_colors" > "$TODO_SAVE_COLOR_FILE"
else
    rm -f "$TODO_SAVE_COLOR_FILE"
fi

echo "Test completed - original todo state restored"