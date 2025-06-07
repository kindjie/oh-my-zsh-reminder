#!/usr/bin/env zsh

# Demo script to showcase padding configurations for both affirmation and todo box
autoload -U colors
colors

# Source the plugin
source reminder.plugin.zsh

# Function to create full-width borders
function print_start_border() {
    local text="┌─ START OF DISPLAY OUTPUT "
    local text_length=${#text}
    local remaining=$((COLUMNS - text_length - 1))
    printf "%s" "$text"
    
    # Generate dashes to fill remaining width
    local i=0
    while [[ $i -lt $remaining ]]; do
        printf "─"
        ((i++))
    done
    echo "┐"
}

function print_end_border() {
    local text="└─ END OF DISPLAY OUTPUT "
    local text_length=${#text}
    local remaining=$((COLUMNS - text_length - 1))
    printf "%s" "$text"
    
    # Generate dashes to fill remaining width
    local i=0
    while [[ $i -lt $remaining ]]; do
        printf "─"
        ((i++))
    done
    echo "┘"
}

echo "🎛️  Padding Configuration Demo"
echo "==============================="
echo "This demo shows how padding affects BOTH the affirmation and todo box positioning."
echo

# Add demo tasks for visualization
todo_add_task "Demo task for padding visualization"
todo_add_task "Another task to show wrapping"
todo_add_task "Short task"

# Load the tasks to ensure they're available
load_tasks

echo "1️⃣  Default padding (0,4,0,0) - Baseline"
echo "   📍 Shows default right padding of 4 characters"
print_start_border
# Use default padding values - no need to set them
todo_display
print_end_border

echo "\n2️⃣  Zero padding (0,0,0,0) - Edge alignment"
echo "   📍 Box reaches exactly to terminal edge"
print_start_border
TODO_PADDING_TOP=0
TODO_PADDING_RIGHT=0
TODO_PADDING_BOTTOM=0
TODO_PADDING_LEFT=0
todo_display
print_end_border

echo "\n3️⃣  Top padding (2 lines)"
echo "   📍 Both affirmation and box move down by 2 blank lines"
print_start_border
TODO_PADDING_TOP=2
TODO_PADDING_RIGHT=0
TODO_PADDING_BOTTOM=0
TODO_PADDING_LEFT=0
todo_display
print_end_border

echo "\n4️⃣  Left padding (6 spaces) - Notice the shift!"
echo "   📍 BOTH affirmation and box shift right by 6 spaces"
echo "   📍 Affirmation gets less space and may truncate"
print_start_border
TODO_PADDING_TOP=0
TODO_PADDING_RIGHT=0
TODO_PADDING_BOTTOM=0
TODO_PADDING_LEFT=6
todo_display
print_end_border

echo "\n5️⃣  Right padding (5 spaces)"
echo "   📍 Box has less space, affirmation space reduced accordingly" 
print_start_border
TODO_PADDING_TOP=0
TODO_PADDING_RIGHT=5
TODO_PADDING_BOTTOM=0
TODO_PADDING_LEFT=0
todo_display
print_end_border

echo "\n6️⃣  Bottom padding (3 lines)"
echo "   📍 Extra blank lines appear after the entire display"
print_start_border
TODO_PADDING_TOP=0
TODO_PADDING_RIGHT=0
TODO_PADDING_BOTTOM=3
TODO_PADDING_LEFT=0
todo_display
print_end_border

echo "\n7️⃣  Combined padding (2,3,2,8) - Maximum effect!"
echo "   📍 Top: 2 blank lines above"
echo "   📍 Left: Both affirmation and box shift right by 8 spaces"
echo "   📍 Right: Reduced width for both components"
echo "   📍 Bottom: 2 blank lines below"
print_start_border
TODO_PADDING_TOP=2
TODO_PADDING_RIGHT=3
TODO_PADDING_BOTTOM=2
TODO_PADDING_LEFT=8
todo_display
print_end_border

echo "\n8️⃣  Extreme left padding (15 spaces) - Watch the truncation!"
echo "   📍 Affirmation severely truncated due to space constraints"
echo "   📍 Both components squeezed into remaining space"
print_start_border
TODO_PADDING_TOP=0
TODO_PADDING_RIGHT=0
TODO_PADDING_BOTTOM=0
TODO_PADDING_LEFT=15
todo_display
print_end_border

echo "✨ Demo complete!"
echo
echo "💡 Key observations:"
echo "   • Left/right padding affects BOTH affirmation and todo box positioning"
echo "   • Affirmation space is calculated after padding, so it may truncate"
echo "   • Top/bottom padding adds blank lines around the entire display"
echo "   • All padding works together to create the final layout"

# Clean up demo tasks (remove the 3 tasks we added)
if command -v task_done >/dev/null 2>&1; then
    task_done "Demo task" 2>/dev/null || true
    task_done "Another task" 2>/dev/null || true  
    task_done "Short task" 2>/dev/null || true
fi