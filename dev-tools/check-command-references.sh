#!/bin/bash

# Comprehensive Search Tool for Command Reference Validation
# Part of the pragmatic development workflow for preventing documentation drift
#
# Usage: ./dev-tools/check-command-references.sh [old_command_name]
#        ./dev-tools/check-command-references.sh --help

set -e

# Colors for output
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
RESET='\033[0m'

function show_help() {
    cat << EOF
📋 Command Reference Checker

USAGE:
    $0 [old_command_name]     # Check for specific command references
    $0 --help                 # Show this help

EXAMPLES:
    $0 todo_remove           # Check for todo_remove references
    $0 task_done             # Check for task_done references  
    $0                       # Run comprehensive check for common issues

PURPOSE:
    Before completing any command interface changes, run this script to ensure
    all documentation, help text, and examples are updated consistently.
    
    This prevents documentation drift and maintains interface consistency.

OUTPUT:
    • Lists all files containing old command references
    • Shows line numbers and context for each match
    • Suggests next steps for fixing inconsistencies

WORKFLOW:
    1. Make command interface changes
    2. Run this script to find all references to old commands
    3. Update all found references to new interface
    4. Run ./tests/help_examples.zsh to validate help examples work
    5. Run full test suite to ensure no regressions

EOF
}

function check_command() {
    local cmd="$1"
    local found_files=()
    
    echo -e "${BLUE}🔍 Searching for references to: ${YELLOW}$cmd${RESET}"
    echo
    
    # Search in all relevant files
    local files=$(find . -name "*.zsh" -o -name "*.md" | grep -v ".git" | sort)
    
    for file in $files; do
        if grep -n "$cmd" "$file" >/dev/null 2>&1; then
            found_files+=("$file")
            echo -e "${RED}📄 $file:${RESET}"
            # Show matches with context
            grep -n --color=always "$cmd" "$file" | head -5
            echo
        fi
    done
    
    if [[ ${#found_files[@]} -eq 0 ]]; then
        echo -e "${GREEN}✅ No references to '$cmd' found${RESET}"
    else
        echo -e "${YELLOW}⚠️  Found $cmd in ${#found_files[@]} files${RESET}"
        echo -e "${YELLOW}📝 Next steps:${RESET}"
        echo "   1. Update references in the files above"
        echo "   2. Run: ./tests/help_examples.zsh"
        echo "   3. Run: ./tests/test.zsh --only-functional"
    fi
    echo
}

function comprehensive_check() {
    echo -e "${BLUE}📋 Running Comprehensive Command Reference Check${RESET}"
    echo "═══════════════════════════════════════════════"
    echo
    
    # Common old command patterns to check
    local old_commands=(
        "task_done"
        "todo_add_task"
        "todo_remove"
        "todo_affirm"
        "todo_hide"
        "todo_show"
        "todo_setup"
        "todo_colors"
        "todo_help_full"
        "todo_toggle_"
    )
    
    local issues_found=0
    
    for cmd in "${old_commands[@]}"; do
        local matches=$(find . -name "*.zsh" -o -name "*.md" | grep -v ".git" | xargs grep -l "$cmd" 2>/dev/null | wc -l)
        if [[ $matches -gt 0 ]]; then
            ((issues_found++))
            echo -e "${RED}⚠️  Found $matches files with '$cmd'${RESET}"
        fi
    done
    
    if [[ $issues_found -eq 0 ]]; then
        echo -e "${GREEN}✅ No common command reference issues found${RESET}"
        echo -e "${GREEN}📝 Recommendations:${RESET}"
        echo "   • Run ./tests/help_examples.zsh to validate help examples"
        echo "   • Run ./tests/test.zsh to ensure all functionality works"
    else
        echo
        echo -e "${YELLOW}📝 Run with specific command names for details:${RESET}"
        for cmd in "${old_commands[@]}"; do
            local matches=$(find . -name "*.zsh" -o -name "*.md" | grep -v ".git" | xargs grep -l "$cmd" 2>/dev/null | wc -l)
            if [[ $matches -gt 0 ]]; then
                echo "   $0 $cmd"
            fi
        done
    fi
    echo
}

# Main logic
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
elif [[ -n "$1" ]]; then
    check_command "$1"
else
    comprehensive_check
fi

echo -e "${BLUE}💡 TIP: Add this script to your development workflow${RESET}"
echo "   Run before completing any command interface changes"