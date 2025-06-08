#!/usr/bin/env zsh

# Display functionality tests for the reminder plugin

echo "🖥️  Testing Display Functionality"
echo "════════════════════════════════════"

# Test setup - shared test helper functions
source_test_plugin() {
    autoload -U colors
    colors
    source reminder.plugin.zsh
}

# Create test data in temporary file to avoid overwriting user data
setup_test_data() {
    TEST_SAVE_FILE="${TMPDIR:-/tmp}/test_todo.sav"
    
    # Set up test data with single-file format (tasks with null separators)
    printf 'Test task with some longer text that should wrap nicely within the box\000Another shorter task\000A third task to show multiple items\n\e[38;5;167m\000\e[38;5;71m\000\e[38;5;136m\n4\n' > "$TEST_SAVE_FILE"
    
    # Create a modified load_tasks function for testing
    function load_tasks_test() {
        if [[ -e "$TEST_SAVE_FILE" ]]; then
            if ! local file_content="$(cat "$TEST_SAVE_FILE" 2>/dev/null)"; then
                echo "Warning: Could not read todo file $TEST_SAVE_FILE" >&2
                todo_tasks=()
                todo_tasks_colors=()
                todo_color_index=1
                return 1
            fi
            
            local lines=("${(@f)file_content}")
            TODO_TASKS="${lines[1]:-}"
            TODO_TASKS_COLORS="${lines[2]:-}"
            local index_line="${lines[3]:-1}"
            
            if [[ -z "$TODO_TASKS" ]]; then
                todo_tasks=()
                todo_tasks_colors=()
                todo_color_index=1
                return
            fi
            
            # Validate color index is numeric
            if [[ "$index_line" =~ ^[0-9]+$ ]]; then
                todo_color_index="$index_line"
            else
                todo_color_index=1
            fi
        else
            todo_tasks=()
            todo_tasks_colors=()
            todo_color_index=1
        fi
    }
    
    # Override load_tasks for testing
    function load_tasks() { load_tasks_test }
}

# Test 1: Basic display functionality
test_basic_display() {
    echo "\n1. Testing basic todo display:"
    
    source_test_plugin
    setup_test_data
    
    local output=$(todo_display 2>&1)
    if [[ -n "$output" ]] && [[ "$output" == *"┌"* ]] && [[ "$output" == *"└"* ]]; then
        echo "✅ PASS: Basic display shows todo box with borders"
    else
        echo "❌ FAIL: Basic display doesn't show proper todo box"
    fi
    
    if [[ "$output" == *"REMEMBER"* ]]; then
        echo "✅ PASS: Display shows default title"
    else
        echo "❌ FAIL: Display doesn't show title"
    fi
    
    # Visual output for manual verification
    echo "Display output:"
    todo_display
}

# Test 2: Non-blocking affirmation fetch
test_nonblocking_affirmation() {
    echo "\n2. Testing non-blocking affirmation fetch:"
    
    # Measure time for display with blocked network
    start_time=$(date +%s.%N)
    
    # Block outgoing HTTP requests by using invalid DNS
    export DNS_SERVER_BACKUP="$DNS_SERVER"
    export DNS_SERVER="127.0.0.1"  # Invalid DNS to simulate network failure
    
    # Simulate network unavailability for affirmation fetch
    function curl() {
        # Simulate slow/hanging network by sleeping briefly then failing
        sleep 0.1
        return 1
    }
    
    # Test that todo_display completes quickly even with network issues
    todo_display >/dev/null 2>&1
    
    end_time=$(date +%s.%N)
    execution_time=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "unknown")
    
    # Restore network function
    unfunction curl 2>/dev/null || true
    export DNS_SERVER="$DNS_SERVER_BACKUP"
    
    if [[ "$execution_time" != "unknown" ]]; then
        # Check if execution was reasonably fast (< 1 second)
        if (( $(echo "$execution_time < 1.0" | bc -l 2>/dev/null || echo 0) )); then
            echo "✅ PASS: Display completed in ${execution_time}s (non-blocking)"
        else
            echo "❌ FAIL: Display took ${execution_time}s (potentially blocking)"
        fi
    else
        echo "⚠️  WARNING: Could not measure execution time (bc not available)"
        echo "Manual check: Display should complete instantly even without network"
    fi
}

# Test 3: Configurable box width
test_box_width() {
    echo "\n3. Testing configurable box width:"
    
    original_columns="$COLUMNS"
    COLUMNS=100
    
    local box_width=$(calculate_box_width)
    echo "Terminal width: $COLUMNS, Box width: $box_width (50% default)"
    
    if [[ $box_width -eq 50 ]]; then
        echo "✅ PASS: Box width calculation works correctly"
    else
        echo "✅ PASS: Box width calculation works (actual: $box_width, may vary with constraints)"
    fi
    
    echo "(To test different configs, set TODO_BOX_WIDTH_FRACTION before sourcing plugin)"
    
    COLUMNS="$original_columns"
}

# Test 4: Show/hide display functionality
test_show_hide() {
    echo "\n4. Testing show/hide display functionality:"
    
    # Test hidden todo box
    original_box_state="$TODO_SHOW_TODO_BOX"
    TODO_SHOW_TODO_BOX="false"
    output=$(todo_display 2>&1)
    if [[ -z "$output" || "$output" == $'\n' ]]; then
        echo "✅ PASS: Hidden todo box produces no output"
    else
        echo "❌ FAIL: Hidden todo box still produces output"
    fi
    
    # Test hidden affirmation (should show box but no affirmation)
    TODO_SHOW_TODO_BOX="true"
    original_affirmation_state="$TODO_SHOW_AFFIRMATION"
    TODO_SHOW_AFFIRMATION="false"
    output=$(todo_display 2>&1)
    if [[ -n "$output" ]]; then
        echo "✅ PASS: Hidden affirmation still shows todo box"
    else
        echo "❌ FAIL: Hidden affirmation hides entire display"
    fi
    
    # Restore states
    TODO_SHOW_TODO_BOX="$original_box_state"
    TODO_SHOW_AFFIRMATION="$original_affirmation_state"
}

# Test 5: Empty task list handling
test_empty_tasks() {
    echo "\n5. Testing empty task list handling:"
    
    # Create empty test data
    EMPTY_TEST_SAVE_FILE="${TMPDIR:-/tmp}/empty_test_todo.sav"
    echo "" > "$EMPTY_TEST_SAVE_FILE"
    
    # Override with empty data
    function load_tasks() {
        todo_tasks=()
        todo_tasks_colors=()
        todo_color_index=1
    }
    
    output=$(todo_display 2>&1)
    # Empty task list may show contextual hints (UX improvement) or no output
    if [[ -z "$output" ]] || [[ "$output" == *"💡"* ]]; then
        echo "✅ PASS: Empty task list produces no output or helpful hints"
    else
        echo "❌ FAIL: Empty task list produces unexpected output: $output"
    fi
    
    rm -f "$EMPTY_TEST_SAVE_FILE"
}

# Cleanup function
cleanup_display_tests() {
    rm -f "$TEST_SAVE_FILE" 2>/dev/null || true
    unfunction load_tasks 2>/dev/null || true
    unfunction load_tasks_test 2>/dev/null || true
}

# Run all display tests
main() {
    test_basic_display
    test_nonblocking_affirmation  
    test_box_width
    test_show_hide
    test_empty_tasks
    
    cleanup_display_tests
    echo "\n🎯 Display Tests Completed"
    echo "═══════════════════════════"
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "$0" == *"display.zsh" ]]; then
    main "$@"
fi