#!/usr/bin/env zsh

# Test script for color validation in the reminder plugin
autoload -U colors
colors

echo "🎨 Testing Color Validation"
echo "════════════════════════════"

# Test 1: Valid color configuration
echo "\n1. Testing valid color configuration:"
COLUMNS=80 TODO_TASK_COLORS="196,46,33" TODO_BORDER_COLOR=244 TODO_AFFIRMATION_COLOR=109 zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh; echo "✅ PASS: Valid colors accepted"' 2>/dev/null
if [[ $? -eq 0 ]]; then
    echo "✅ PASS: Valid color configuration loads successfully"
else
    echo "❌ FAIL: Valid color configuration rejected"
fi

# Test 2: Invalid border color (too high)
echo "\n2. Testing invalid border color (256):"
error_output=$(COLUMNS=80 TODO_BORDER_COLOR=256 zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh' 2>&1)
if [[ $? -ne 0 ]] && [[ "$error_output" == *"TODO_BORDER_COLOR must be a number between 0-255"* ]]; then
    echo "✅ PASS: Invalid border color (256) properly rejected"
else
    echo "❌ FAIL: Invalid border color not properly rejected"
fi

# Test 3: Invalid task colors (non-numeric)
echo "\n3. Testing invalid task colors (non-numeric):"
error_output=$(COLUMNS=80 TODO_TASK_COLORS="red,green,blue" zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh' 2>&1)
if [[ $? -ne 0 ]] && [[ "$error_output" == *"TODO_TASK_COLORS must be comma-separated numbers"* ]]; then
    echo "✅ PASS: Non-numeric task colors properly rejected"
else
    echo "❌ FAIL: Non-numeric task colors not properly rejected"
fi

# Test 4: Invalid task colors (value too high)
echo "\n4. Testing invalid task colors (value too high):"
error_output=$(COLUMNS=80 TODO_TASK_COLORS="200,300,150" zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh' 2>&1)
if [[ "$error_output" == *"Task color values must be 0-255"* ]]; then
    echo "✅ PASS: High task color values properly rejected"
else
    echo "❌ FAIL: High task color values not properly rejected (output: '$error_output')"
fi

# Test 5: Invalid affirmation color (negative)
echo "\n5. Testing invalid affirmation color (negative):"
error_output=$(COLUMNS=80 TODO_AFFIRMATION_COLOR=-1 zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh' 2>&1)
if [[ $? -ne 0 ]] && [[ "$error_output" == *"TODO_AFFIRMATION_COLOR must be a number between 0-255"* ]]; then
    echo "✅ PASS: Negative affirmation color properly rejected"
else
    echo "❌ FAIL: Negative affirmation color not properly rejected"
fi

# Test 6: Mixed valid/invalid task colors
echo "\n6. Testing mixed valid/invalid task colors:"
error_output=$(COLUMNS=80 TODO_TASK_COLORS="100,256,50" zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh' 2>&1)
if [[ "$error_output" == *"Task color values must be 0-255"* ]]; then
    echo "✅ PASS: Mixed task colors properly validated"
else
    echo "❌ FAIL: Mixed task colors validation failed (output: '$error_output')"
fi

# Test 7: Empty task colors (should use default)
echo "\n7. Testing empty task colors (should use default):"
error_output=$(COLUMNS=80 TODO_TASK_COLORS="" zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh; echo "Final value: $TODO_TASK_COLORS"' 2>&1)
if [[ "$error_output" == *"Final value: 167,71,136,110,139,73"* ]]; then
    echo "✅ PASS: Empty task colors use default values"
else
    echo "❌ FAIL: Empty task colors don't use default (output: '$error_output')"
fi

# Test 8: Task colors with spaces
echo "\n8. Testing task colors with invalid format (spaces):"
error_output=$(COLUMNS=80 TODO_TASK_COLORS="100, 200, 150" zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh' 2>&1)
if [[ $? -ne 0 ]] && [[ "$error_output" == *"TODO_TASK_COLORS must be comma-separated numbers"* ]]; then
    echo "✅ PASS: Task colors with spaces properly rejected"
else
    echo "❌ FAIL: Task colors with spaces not properly rejected"
fi

# Test 9: Single task color (valid)
echo "\n9. Testing single task color:"
COLUMNS=80 TODO_TASK_COLORS="196" zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh; echo "Single color loaded"' 2>/dev/null
if [[ $? -eq 0 ]]; then
    echo "✅ PASS: Single task color accepted"
else
    echo "❌ FAIL: Single task color rejected"
fi

# Test 10: Boundary values (0 and 255)
echo "\n10. Testing boundary values (0 and 255):"
COLUMNS=80 TODO_TASK_COLORS="0,255" TODO_BORDER_COLOR=0 TODO_AFFIRMATION_COLOR=255 zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh; echo "Boundary values loaded"' 2>/dev/null
if [[ $? -eq 0 ]]; then
    echo "✅ PASS: Boundary values (0,255) accepted"
else
    echo "❌ FAIL: Boundary values (0,255) rejected"
fi

echo "\n🎯 Color Validation Tests Completed"
echo "══════════════════════════════════════"