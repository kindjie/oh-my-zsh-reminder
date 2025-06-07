#!/usr/bin/env zsh

# Master test runner for the reminder plugin test suite

echo "🧪 Zsh Todo Reminder Plugin - Complete Test Suite"
echo "═══════════════════════════════════════════════════"
echo "Running comprehensive tests for all plugin functionality"
echo

# Color definitions for output
if autoload -U colors 2>/dev/null && colors 2>/dev/null; then
    RED=$'\e[31m'
    GREEN=$'\e[32m'
    YELLOW=$'\e[33m'
    BLUE=$'\e[34m'
    MAGENTA=$'\e[35m'
    CYAN=$'\e[36m'
    RESET=$'\e[0m'
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    MAGENTA=""
    CYAN=""
    RESET=""
fi

# Test file configuration
TESTS_DIR="$(dirname "$0")"
TEST_FILES=(
    "display.zsh"
    "configuration.zsh"
    "color.zsh"
    "interface.zsh"
    "character.zsh"
)

# Global test tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNING_TESTS=0

# Function to run a single test file
run_test_file() {
    local test_file="$1"
    local test_path="$TESTS_DIR/$test_file"
    
    echo "${BLUE}▶ Running $test_file...${RESET}"
    echo "────────────────────────────────────────────────────"
    
    if [[ ! -f "$test_path" ]]; then
        echo "${RED}❌ Test file not found: $test_path${RESET}"
        return 1
    fi
    
    if [[ ! -x "$test_path" ]]; then
        echo "${RED}❌ Test file not executable: $test_path${RESET}"
        return 1
    fi
    
    # Capture output and parse results
    local output
    local exit_code
    
    # Change to plugin directory to ensure relative paths work
    local original_pwd="$PWD"
    cd "$TESTS_DIR/.."
    
    output=$("$test_path" 2>&1)
    exit_code=$?
    
    cd "$original_pwd"
    
    # Display the output
    echo "$output"
    
    # Parse test results from output
    local file_passed=$(echo "$output" | grep -c "✅ PASS:")
    local file_failed=$(echo "$output" | grep -c "❌ FAIL:")
    local file_warnings=$(echo "$output" | grep -c "⚠️  WARNING:")
    
    # Update global counters
    TOTAL_TESTS=$((TOTAL_TESTS + file_passed + file_failed))
    PASSED_TESTS=$((PASSED_TESTS + file_passed))
    FAILED_TESTS=$((FAILED_TESTS + file_failed))
    WARNING_TESTS=$((WARNING_TESTS + file_warnings))
    
    # Report file results
    echo "────────────────────────────────────────────────────"
    if [[ $file_failed -eq 0 ]]; then
        echo "${GREEN}✅ $test_file: $file_passed passed, $file_warnings warnings${RESET}"
    else
        echo "${RED}❌ $test_file: $file_passed passed, $file_failed failed, $file_warnings warnings${RESET}"
    fi
    echo
    
    return $exit_code
}

# Function to display summary
display_summary() {
    echo "🎯 Test Suite Summary"
    echo "═════════════════════"
    echo "Total Tests:    $TOTAL_TESTS"
    echo "${GREEN}Passed:         $PASSED_TESTS${RESET}"
    if [[ $FAILED_TESTS -gt 0 ]]; then
        echo "${RED}Failed:         $FAILED_TESTS${RESET}"
    else
        echo "Failed:         $FAILED_TESTS"
    fi
    if [[ $WARNING_TESTS -gt 0 ]]; then
        echo "${YELLOW}Warnings:       $WARNING_TESTS${RESET}"
    else
        echo "Warnings:       $WARNING_TESTS"
    fi
    echo
    
    # Calculate success rate
    if [[ $TOTAL_TESTS -gt 0 ]]; then
        local success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
        echo "Success Rate:   ${success_rate}%"
    fi
    
    # Overall result
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo "${GREEN}🎉 All tests passed!${RESET}"
        if [[ $WARNING_TESTS -gt 0 ]]; then
            echo "${YELLOW}⚠️  There were $WARNING_TESTS warnings to review.${RESET}"
        fi
        return 0
    else
        echo "${RED}💥 $FAILED_TESTS test(s) failed.${RESET}"
        return 1
    fi
}

# Function to check prerequisites
check_prerequisites() {
    echo "${CYAN}🔍 Checking prerequisites...${RESET}"
    
    # Check if plugin file exists
    if [[ ! -f "$TESTS_DIR/../reminder.plugin.zsh" ]]; then
        echo "${RED}❌ Plugin file not found: reminder.plugin.zsh${RESET}"
        echo "Make sure you're running tests from the correct directory."
        return 1
    fi
    
    # Check zsh version
    if [[ -n "$ZSH_VERSION" ]]; then
        echo "✅ Zsh version: $ZSH_VERSION"
    else
        echo "${YELLOW}⚠️  Not running in zsh. Some tests may not work correctly.${RESET}"
    fi
    
    # Check if colors are available
    if command -v colors >/dev/null 2>&1; then
        echo "✅ Color support available"
    else
        echo "${YELLOW}⚠️  Color support not available${RESET}"
    fi
    
    # Check for optional dependencies
    local deps_available=true
    for dep in bc curl jq; do
        if command -v "$dep" >/dev/null 2>&1; then
            echo "✅ $dep available"
        else
            echo "${YELLOW}⚠️  $dep not available (some tests may be limited)${RESET}"
            deps_available=false
        fi
    done
    
    echo
    return 0
}

# Function to run specific test files
run_specific_tests() {
    local selected_tests=("$@")
    
    if [[ ${#selected_tests[@]} -eq 0 ]]; then
        echo "${RED}❌ No test files specified${RESET}"
        return 1
    fi
    
    for test_file in "${selected_tests[@]}"; do
        if [[ ! " ${TEST_FILES[@]} " =~ " $test_file " ]]; then
            echo "${RED}❌ Unknown test file: $test_file${RESET}"
            echo "Available tests: ${TEST_FILES[*]}"
            return 1
        fi
        run_test_file "$test_file"
    done
}

# Function to display help
show_help() {
    local script_name="$(basename "$0")"
    echo "Usage: $script_name [options] [test_files...]"
    echo
    echo "Options:"
    echo "  -h, --help      Show this help message"
    echo "  -l, --list      List available test files"
    echo "  -v, --verbose   Run with verbose output"
    echo "  -q, --quick     Run quick tests only (skip slow tests)"
    echo
    echo "Test Files:"
    for test_file in "${TEST_FILES[@]}"; do
        echo "  $test_file"
    done
    echo
    echo "Examples:"
    echo "  $script_name                          # Run all tests"
    echo "  $script_name display.zsh color.zsh    # Run specific tests"
    echo "  $script_name --list                   # List available tests"
}

# Function to list available tests
list_tests() {
    echo "Available test files:"
    for test_file in "${TEST_FILES[@]}"; do
        local test_path="$TESTS_DIR/$test_file"
        if [[ -f "$test_path" ]]; then
            echo "  ✅ $test_file"
        else
            echo "  ❌ $test_file (missing)"
        fi
    done
}

# Main execution
main() {
    local run_all=true
    local verbose=false
    local quick=false
    local specific_tests=()
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                return 0
                ;;
            -l|--list)
                list_tests
                return 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -q|--quick)
                quick=true
                shift
                ;;
            -*)
                echo "${RED}❌ Unknown option: $1${RESET}"
                show_help
                return 1
                ;;
            *)
                specific_tests+=("$1")
                run_all=false
                shift
                ;;
        esac
    done
    
    # Set verbose mode
    if [[ "$verbose" == true ]]; then
        set -x
    fi
    
    # Check prerequisites
    if ! check_prerequisites; then
        return 1
    fi
    
    local start_time=$(date +%s 2>/dev/null || date +%s)
    
    # Run tests
    if [[ "$run_all" == true ]]; then
        echo "${CYAN}🚀 Running all tests...${RESET}"
        echo
        for test_file in "${TEST_FILES[@]}"; do
            run_test_file "$test_file"
        done
    else
        echo "${CYAN}🚀 Running selected tests...${RESET}"
        echo
        run_specific_tests "${specific_tests[@]}"
    fi
    
    local end_time=$(date +%s 2>/dev/null || date +%s)
    local duration=$((end_time - start_time))
    
    echo
    echo "📊 Execution time: ${duration}s"
    echo
    
    # Display final summary
    display_summary
}

# Execute main function if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "$0" == *"run_all.zsh" ]]; then
    main "$@"
fi