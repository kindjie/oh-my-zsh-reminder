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
    "config_management.zsh"
    "color.zsh"
    "interface.zsh"
    "character.zsh"
)

PERFORMANCE_TEST_FILE="performance.zsh"
UX_TEST_FILE="ux.zsh"
DOCUMENTATION_TEST_FILE="documentation.zsh"

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

# Function to run performance tests
run_performance_tests() {
    local perf_path="$TESTS_DIR/$PERFORMANCE_TEST_FILE"
    
    if [[ ! -f "$perf_path" ]]; then
        echo "${RED}❌ Performance test file not found: $PERFORMANCE_TEST_FILE${RESET}"
        return 1
    fi
    
    echo "${MAGENTA}🚀 Running performance tests...${RESET}"
    echo "This may take 30-60 seconds to complete all 16 performance tests."
    echo
    
    # Run performance tests with timeout
    local output
    local exit_code
    
    if timeout 120 "$perf_path" > /tmp/perf_output 2>&1; then
        output=$(cat /tmp/perf_output)
        exit_code=0
    else
        output=$(cat /tmp/perf_output 2>/dev/null || echo "Performance tests timed out or failed")
        exit_code=1
    fi
    
    # Clean up temp file
    rm -f /tmp/perf_output
    
    # Display relevant output
    echo "$output" | tail -20
    
    # Count performance test results
    local perf_passed=$(echo "$output" | grep -c "✅ PASS")
    local perf_failed=$(echo "$output" | grep -c "❌ FAIL")
    local perf_warnings=$(echo "$output" | grep -c "⚠️")
    
    # Update global counters
    TOTAL_TESTS=$((TOTAL_TESTS + perf_passed + perf_failed))
    PASSED_TESTS=$((PASSED_TESTS + perf_passed))
    FAILED_TESTS=$((FAILED_TESTS + perf_failed))
    WARNING_TESTS=$((WARNING_TESTS + perf_warnings))
    
    # Report performance results
    echo "────────────────────────────────────────────────────"
    if [[ $perf_failed -eq 0 ]]; then
        echo "${GREEN}✅ Performance tests: $perf_passed passed, $perf_warnings warnings${RESET}"
    else
        echo "${RED}❌ Performance tests: $perf_passed passed, $perf_failed failed, $perf_warnings warnings${RESET}"
    fi
    echo
    
    return $exit_code
}

# Function to run UX tests
run_ux_tests() {
    local ux_path="$TESTS_DIR/$UX_TEST_FILE"
    
    if [[ ! -f "$ux_path" ]]; then
        echo "${RED}❌ UX test file not found: $UX_TEST_FILE${RESET}"
        return 1
    fi
    
    echo "${MAGENTA}🎨 Running UX tests...${RESET}"
    echo "This validates user experience, onboarding, and progressive disclosure."
    echo
    
    # Run UX tests with timeout
    local output
    local exit_code
    
    if timeout 60 "$ux_path" > /tmp/ux_output 2>&1; then
        output=$(cat /tmp/ux_output)
        exit_code=0
    else
        output=$(cat /tmp/ux_output 2>/dev/null || echo "UX tests timed out or failed")
        exit_code=1
    fi
    
    # Clean up temp file
    rm -f /tmp/ux_output
    
    # Display relevant output
    echo "$output"
    
    # Count UX test results
    local ux_passed=$(echo "$output" | grep -c "✅ PASS")
    local ux_failed=$(echo "$output" | grep -c "❌ FAIL")
    local ux_warnings=$(echo "$output" | grep -c "⚠️")
    
    # Update global counters
    TOTAL_TESTS=$((TOTAL_TESTS + ux_passed + ux_failed))
    PASSED_TESTS=$((PASSED_TESTS + ux_passed))
    FAILED_TESTS=$((FAILED_TESTS + ux_failed))
    WARNING_TESTS=$((WARNING_TESTS + ux_warnings))
    
    # Report UX results
    echo "────────────────────────────────────────────────────"
    if [[ $ux_failed -eq 0 ]]; then
        echo "${GREEN}✅ UX tests: $ux_passed passed, $ux_warnings warnings${RESET}"
    else
        echo "${RED}❌ UX tests: $ux_passed passed, $ux_failed failed, $ux_warnings warnings${RESET}"
    fi
    echo
    
    return $exit_code
}

# Function to run documentation tests
run_documentation_tests() {
    local doc_path="$TESTS_DIR/$DOCUMENTATION_TEST_FILE"
    
    if [[ ! -f "$doc_path" ]]; then
        echo "${RED}❌ Documentation test file not found: $DOCUMENTATION_TEST_FILE${RESET}"
        return 1
    fi
    
    echo "${MAGENTA}📚 Running documentation tests...${RESET}"
    echo "This validates that documentation accurately represents the implementation."
    echo
    
    # Run documentation tests with timeout
    local output
    local exit_code
    
    if timeout 60 "$doc_path" > /tmp/doc_output 2>&1; then
        output=$(cat /tmp/doc_output)
        exit_code=0
    else
        output=$(cat /tmp/doc_output 2>/dev/null || echo "Documentation tests timed out or failed")
        exit_code=1
    fi
    
    # Clean up temp file
    rm -f /tmp/doc_output
    
    # Display relevant output
    echo "$output"
    
    # Count documentation test results
    local doc_passed=$(echo "$output" | grep -c "✅ PASS")
    local doc_failed=$(echo "$output" | grep -c "❌ FAIL")
    local doc_warnings=$(echo "$output" | grep -c "⚠️")
    
    # Update global counters
    TOTAL_TESTS=$((TOTAL_TESTS + doc_passed + doc_failed))
    PASSED_TESTS=$((PASSED_TESTS + doc_passed))
    FAILED_TESTS=$((FAILED_TESTS + doc_failed))
    WARNING_TESTS=$((WARNING_TESTS + doc_warnings))
    
    # Report documentation results
    echo "────────────────────────────────────────────────────"
    if [[ $doc_failed -eq 0 ]]; then
        echo "${GREEN}✅ Documentation tests: $doc_passed passed, $doc_warnings warnings${RESET}"
    else
        echo "${RED}❌ Documentation tests: $doc_passed passed, $doc_failed failed, $doc_warnings warnings${RESET}"
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
    local script_name="$(basename "${1:-$0}")"
    echo "Usage: $script_name [options] [test_files...]"
    echo
    echo "Options:"
    echo "  -h, --help      Show this help message"
    echo "  -l, --list      List available test files"
    echo "  -v, --verbose   Run with verbose output"
    echo "  -q, --quick     Run quick tests only (skip slow tests)"
    echo "  -p, --perf      Include performance tests (adds ~30-60s)"
    echo "  -u, --ux        Include UX/onboarding tests (adds ~10-20s)"
    echo "  -d, --docs      Include documentation accuracy tests (adds ~5-10s)"
    echo
    echo "Test Files:"
    for test_file in "${TEST_FILES[@]}"; do
        echo "  $test_file"
    done
    echo
    echo "Examples:"
    echo "  $script_name                          # Run all functional tests"
    echo "  $script_name --perf                   # Run functional + performance tests"
    echo "  $script_name --ux                     # Run functional + UX tests"
    echo "  $script_name --docs                   # Run functional + documentation tests"
    echo "  $script_name --perf --ux --docs       # Run all tests (complete suite)"
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
    local script_name="$1"
    shift  # Remove script name from arguments
    
    local run_all=true
    local verbose=false
    local quick=false
    local run_performance=false
    local run_ux=false
    local run_documentation=false
    local specific_tests=()
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help "$script_name"
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
            -p|--perf)
                run_performance=true
                shift
                ;;
            -u|--ux)
                run_ux=true
                shift
                ;;
            -d|--docs)
                run_documentation=true
                shift
                ;;
            -*)
                echo "${RED}❌ Unknown option: $1${RESET}"
                show_help "$script_name"
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
        echo "${CYAN}🚀 Running all functional tests...${RESET}"
        echo
        for test_file in "${TEST_FILES[@]}"; do
            run_test_file "$test_file"
        done
    else
        echo "${CYAN}🚀 Running selected tests...${RESET}"
        echo
        run_specific_tests "${specific_tests[@]}"
    fi
    
    # Run performance tests if requested
    if [[ "$run_performance" == true ]]; then
        echo
        run_performance_tests
    fi
    
    # Run UX tests if requested
    if [[ "$run_ux" == true ]]; then
        echo
        run_ux_tests
    fi
    
    # Run documentation tests if requested
    if [[ "$run_documentation" == true ]]; then
        echo
        run_documentation_tests
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
    # Pass script name as first argument to main
    main "$0" "$@"
fi