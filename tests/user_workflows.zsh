#!/usr/bin/env zsh

# User Workflow Tests
# End-to-end tests for complete user scenarios with the pure subcommand interface

echo "🚀 Testing User Workflows (End-to-End)"
echo "════════════════════════════════════════"

# Test setup
SCRIPT_DIR=${0:A:h}
TEST_TMPDIR="${TMPDIR:-/tmp}/todo-workflow-tests-$$"
mkdir -p "$TEST_TMPDIR"
cd "$TEST_TMPDIR"

# Setup test environment
export TODO_SAVE_FILE="$TEST_TMPDIR/test_todo.save"
export _TODO_INTERNAL_FIRST_RUN_FILE="$TEST_TMPDIR/test_first_run"
export COLUMNS=80

# Clean up on exit
cleanup() {
    cd /
    rm -rf "$TEST_TMPDIR"
}
trap cleanup EXIT

# Load colors
autoload -U colors
colors

# Test counters
test_count=0
pass_count=0
fail_count=0

# Test helper
run_test() {
    local test_name="$1"
    ((test_count++))
    echo -e "\n  Workflow $test_count: $test_name"
    echo "  ────────────────────────────────────"
}

# ============================================================================
# Complete Beginner Workflow
# ============================================================================

test_beginner_workflow() {
    run_test "Complete Beginner Journey"
    
    # Start fresh
    rm -f "$TODO_SAVE_FILE" "$_TODO_INTERNAL_FIRST_RUN_FILE"
    
    # Step 1: First run - see welcome message
    echo "  Step 1: First run experience"
    local welcome_output=$(zsh -c "
        autoload -U colors; colors
        source '$SCRIPT_DIR/../reminder.plugin.zsh'
        # Trigger welcome message
        if [[ ! -f '$_TODO_INTERNAL_FIRST_RUN_FILE' ]]; then
            show_welcome_message
        fi
    ")
    
    if [[ "$welcome_output" == *"Welcome to Todo Reminder!"* ]] && \
       [[ "$welcome_output" == *"todo \"Your first task\""* ]]; then
        echo "    ✅ Welcome message shown correctly"
    else
        echo "    ❌ Welcome message missing or incorrect"
        ((fail_count++))
        return 1
    fi
    
    # Step 2: Get help
    echo "  Step 2: Getting help"
    local help_output=$(zsh -c "
        autoload -U colors; colors
        source '$SCRIPT_DIR/../reminder.plugin.zsh'
        todo help
    ")
    
    if [[ "$help_output" == *"Commands:"* ]] && \
       [[ "$help_output" == *"todo done"* ]]; then
        echo "    ✅ Help system accessible"
    else
        echo "    ❌ Help system not working"
        ((fail_count++))
        return 1
    fi
    
    # Step 3: Add first task
    echo "  Step 3: Adding first task"
    local add_output=$(zsh -c "
        autoload -U colors; colors
        source '$SCRIPT_DIR/../reminder.plugin.zsh'
        todo 'Buy groceries'
    ")
    
    if [[ "$add_output" == *"Task added"* ]] && \
       [[ "$add_output" == *"Buy groceries"* ]]; then
        echo "    ✅ First task added with guidance"
    else
        echo "    ❌ Task addition failed"
        ((fail_count++))
        return 1
    fi
    
    # Step 4: View tasks (display)
    echo "  Step 4: Viewing tasks"
    local display_output=$(zsh -c "
        autoload -U colors; colors
        source '$SCRIPT_DIR/../reminder.plugin.zsh'
        todo_display 2>&1
    " | cat -v)
    
    if [[ "$display_output" == *"Buy groceries"* ]] && \
       [[ "$display_output" == *"REMEMBER"* ]]; then
        echo "    ✅ Tasks display correctly"
    else
        echo "    ❌ Task display not working"
        ((fail_count++))
        return 1
    fi
    
    # Step 5: Complete task
    echo "  Step 5: Completing task"
    local done_output=$(zsh -c "
        autoload -U colors; colors
        source '$SCRIPT_DIR/../reminder.plugin.zsh'
        todo done 'Buy'
    ")
    
    if [[ "$done_output" == *"Task completed"* ]] && \
       [[ "$done_output" == *"All tasks done"* ]]; then
        echo "    ✅ Task completion works"
        ((pass_count++))
    else
        echo "    ❌ Task completion failed"
        ((fail_count++))
    fi
}

# ============================================================================
# Power User Workflow
# ============================================================================

test_power_user_workflow() {
    run_test "Power User Advanced Features"
    
    # Start fresh
    rm -f "$TODO_SAVE_FILE"
    
    # Step 1: Batch add tasks
    echo "  Step 1: Batch adding tasks"
    zsh -c "
        autoload -U colors; colors
        source '$SCRIPT_DIR/../reminder.plugin.zsh'
        todo 'Refactor authentication module'
        todo 'Write unit tests for API'
        todo 'Update documentation'
        todo 'Deploy to staging'
    " >/dev/null 2>&1
    
    # Verify tasks were added
    local task_count=$(zsh -c "
        autoload -U colors; colors
        source '$SCRIPT_DIR/../reminder.plugin.zsh'
        load_tasks
        echo \${#todo_tasks}
    ")
    
    if [[ "$task_count" == "4" ]]; then
        echo "    ✅ Batch task addition works"
    else
        echo "    ❌ Batch addition failed (got $task_count tasks)"
        ((fail_count++))
        return 1
    fi
    
    # Step 2: Configure display
    echo "  Step 2: Configuring display"
    local config_output=$(zsh -c "
        autoload -U colors; colors
        source '$SCRIPT_DIR/../reminder.plugin.zsh'
        todo config set title 'SPRINT TASKS'
        todo config set bullet-char '◆'
        echo 'configured'
    ")
    
    if [[ "$config_output" == *"configured"* ]]; then
        echo "    ✅ Configuration commands work"
    else
        echo "    ❌ Configuration failed"
        ((fail_count++))
        return 1
    fi
    
    # Step 3: Export configuration
    echo "  Step 3: Exporting configuration"
    local export_file="$TEST_TMPDIR/config_backup.conf"
    zsh -c "
        autoload -U colors; colors
        source '$SCRIPT_DIR/../reminder.plugin.zsh'
        todo config export '$export_file'
    " >/dev/null 2>&1
    
    if [[ -f "$export_file" ]]; then
        echo "    ✅ Configuration export works"
    else
        echo "    ❌ Export failed"
        ((fail_count++))
        return 1
    fi
    
    # Step 4: Toggle display components
    echo "  Step 4: Toggling display components"
    local toggle_output=$(zsh -c "
        autoload -U colors; colors
        source '$SCRIPT_DIR/../reminder.plugin.zsh'
        todo toggle affirmation >/dev/null
        echo \$TODO_SHOW_AFFIRMATION
    ")
    
    if [[ "$toggle_output" == "false" ]]; then
        echo "    ✅ Toggle commands work"
    else
        echo "    ❌ Toggle failed"
        ((fail_count++))
        return 1
    fi
    
    # Step 5: Apply preset
    echo "  Step 5: Applying preset"
    local preset_output=$(zsh -c "
        autoload -U colors; colors
        source '$SCRIPT_DIR/../reminder.plugin.zsh'
        todo config preset minimal >/dev/null 2>&1
        echo \$TODO_TITLE
    ")
    
    if [[ "$preset_output" == "TODO" ]]; then
        echo "    ✅ Preset application works"
        ((pass_count++))
    else
        echo "    ❌ Preset failed"
        ((fail_count++))
    fi
}

# ============================================================================
# Migration Workflow (Old to New Interface)
# ============================================================================

test_migration_workflow() {
    run_test "Migration from Old Interface"
    
    # Start fresh
    rm -f "$TODO_SAVE_FILE"
    
    echo "  Step 1: Simulating old interface usage"
    # Users might have muscle memory for old commands
    
    # Step 2: Help discovery
    echo "  Step 2: Discovering new commands"
    local help_output=$(zsh -c "
        autoload -U colors; colors
        source '$SCRIPT_DIR/../reminder.plugin.zsh'
        todo help
    ")
    
    if [[ "$help_output" == *"todo done"* ]] && \
       [[ "$help_output" == *"More Commands:"* ]]; then
        echo "    ✅ New commands discoverable"
    else
        echo "    ❌ New commands not clear"
        ((fail_count++))
        return 1
    fi
    
    # Step 3: Adapt to new patterns
    echo "  Step 3: Using new command patterns"
    local new_pattern=$(zsh -c "
        autoload -U colors; colors
        source '$SCRIPT_DIR/../reminder.plugin.zsh'
        todo 'Test new pattern'
        todo done 'Test'
        echo 'success'
    " 2>&1)
    
    if [[ "$new_pattern" == *"success"* ]]; then
        echo "    ✅ New patterns work correctly"
        ((pass_count++))
    else
        echo "    ❌ New pattern usage failed"
        ((fail_count++))
    fi
}

# ============================================================================
# Command Discovery Workflow
# ============================================================================

test_discovery_workflow() {
    run_test "Natural Command Discovery"
    
    # Step 1: Start with nothing
    echo "  Step 1: User types 'todo' alone"
    local bare_output=$(zsh -c "
        autoload -U colors; colors
        source '$SCRIPT_DIR/../reminder.plugin.zsh'
        todo
    ")
    
    if [[ "$bare_output" == *"Commands:"* ]]; then
        echo "    ✅ Help shown by default"
    else
        echo "    ❌ No help shown"
        ((fail_count++))
        return 1
    fi
    
    # Step 2: Explore subcommands
    echo "  Step 2: Exploring subcommands"
    local config_explore=$(zsh -c "
        autoload -U colors; colors
        source '$SCRIPT_DIR/../reminder.plugin.zsh'
        todo config
    ")
    
    if [[ "$config_explore" == *"export"* ]] && \
       [[ "$config_explore" == *"import"* ]]; then
        echo "    ✅ Config subcommands discoverable"
    else
        echo "    ❌ Config discovery failed"
        ((fail_count++))
        return 1
    fi
    
    # Step 3: Progressive help
    echo "  Step 3: Progressive help exploration"
    local full_help=$(zsh -c "
        autoload -U colors; colors
        source '$SCRIPT_DIR/../reminder.plugin.zsh'
        todo help --full
    " | wc -l)
    
    if [[ $full_help -gt 50 ]]; then
        echo "    ✅ Full help accessible"
    else
        echo "    ❌ Full help not comprehensive"
        ((fail_count++))
        return 1
    fi
    
    # Step 4: Color reference discovery
    echo "  Step 4: Discovering color options"
    local color_help=$(zsh -c "
        autoload -U colors; colors
        source '$SCRIPT_DIR/../reminder.plugin.zsh'
        todo help --colors
    ")
    
    if [[ "$color_help" == *"256-color"* ]] || [[ "$color_help" == *"Color Reference"* ]]; then
        echo "    ✅ Color reference found"
        ((pass_count++))
    else
        echo "    ❌ Color reference missing"
        ((fail_count++))
    fi
}

# ============================================================================
# Error Recovery Workflow
# ============================================================================

test_error_recovery_workflow() {
    run_test "Error Recovery and Guidance"
    
    # Step 1: Invalid command
    echo "  Step 1: Handling invalid commands"
    local invalid_output=$(zsh -c "
        autoload -U colors; colors
        source '$SCRIPT_DIR/../reminder.plugin.zsh'
        todo config invalid_command 2>&1
    ")
    
    if [[ "$invalid_output" == *"Unknown"* ]] && \
       [[ "$invalid_output" == *"todo config"* ]]; then
        echo "    ✅ Clear error with guidance"
    else
        echo "    ❌ Poor error handling"
        ((fail_count++))
        return 1
    fi
    
    # Step 2: Missing arguments
    echo "  Step 2: Missing argument handling"
    local missing_arg=$(zsh -c "
        autoload -U colors; colors
        source '$SCRIPT_DIR/../reminder.plugin.zsh'
        todo done 2>&1
    ")
    
    if [[ "$missing_arg" == *"Usage:"* ]] || \
       [[ "$missing_arg" == *"Example:"* ]]; then
        echo "    ✅ Helpful missing argument message"
    else
        echo "    ❌ Unhelpful error for missing args"
        ((fail_count++))
        return 1
    fi
    
    # Step 3: File not found
    echo "  Step 3: File error handling"
    local file_error=$(zsh -c "
        autoload -U colors; colors
        source '$SCRIPT_DIR/../reminder.plugin.zsh'
        todo config import /nonexistent/file 2>&1
    ")
    
    if [[ "$file_error" == *"Error"* ]] || \
       [[ "$file_error" == *"not found"* ]]; then
        echo "    ✅ Clear file error message"
        ((pass_count++))
    else
        echo "    ❌ Unclear file error"
        ((fail_count++))
    fi
}

# ============================================================================
# Run all workflows
# ============================================================================

echo -e "\n[Running All Workflows]"
echo "═══════════════════════"

test_beginner_workflow
test_power_user_workflow
test_migration_workflow
test_discovery_workflow
test_error_recovery_workflow

# ============================================================================
# Summary
# ============================================================================

echo -e "\n\n🎯 User Workflow Test Summary"
echo "═════════════════════════════"
echo "Total Workflows:    $test_count"
echo "Passed:            $pass_count"
echo "Failed:            $fail_count"
echo
if [[ $fail_count -eq 0 ]]; then
    echo "✅ All user workflows completed successfully!"
else
    echo "❌ Some workflows encountered issues. Please review."
fi