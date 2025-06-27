#!/usr/bin/env zsh
# 🔍 PLUGIN VALIDATION TESTS - Use Claude templates to validate project hygiene
# Category: Plugin Validation (using tools to test the plugin)
# Purpose: Detect obsolete files and maintain clean project structure

# Load shared prompt templates and test utilities
script_dir="${0:A:h}"
source "$script_dir/../claude_prompt_templates.zsh"
source "$script_dir/../test_utils.zsh"
source "$script_dir/../claude_timeout_helper.zsh"

echo "🤖 Claude Obsolete File Detection Tests - Using model: $CLAUDE_MODEL"

test_claude_no_backup_files() {
    echo "Testing for obsolete backup files..."
    
    local backup_files=($(find . -name "*.bak" -o -name "*.old" -o -name "*_backup*" -o -name "*.orig" -o -name "*~" 2>/dev/null || true))
    local obsolete_found=false
    
    for backup_file in "${backup_files[@]}"; do
        if [[ -f "$backup_file" ]]; then
            echo "  🔍 Checking: $backup_file"
            local start_time=$(get_timestamp)
            local result=$(timeout 8 claude --model "$CLAUDE_MODEL" -p "Analyze this backup file to determine if it's obsolete. File: $backup_file

$(ls -la "$backup_file" 2>/dev/null || echo 'File not accessible')

Response format: '✅ KEEP: still needed because...' or '❌ OBSOLETE: can be removed because...'" --allowedTools= 2>/dev/null || echo "❌ OBSOLETE: Claude timeout, assume obsolete")
            local end_time=$(get_timestamp)
            local duration=$(calculate_duration "$start_time" "$end_time")
            printf "(%.2fs) " "$duration"
            if [[ "$result" == *"OBSOLETE:"* ]]; then
                echo "    🗑️  OBSOLETE: $backup_file should be removed"
                obsolete_found=true
            else
                echo "    ✅ KEEP: $backup_file is still needed"
            fi
        fi
    done
    
    if [[ "$obsolete_found" == "true" ]]; then
        echo "❌ FAIL: Found obsolete backup files that should be removed"
        return 1
    else
        echo "✅ PASS: No obsolete backup files found"
        return 0
    fi
}

test_claude_no_temporary_files() {
    echo "Testing for obsolete temporary files..."
    
    local temp_files=($(find . -name "*.tmp" -o -name "*.temp" -o -name "debug_*" -o -name "scratch_*" -o -name "test_local_*" 2>/dev/null || true))
    local obsolete_found=false
    
    for temp_file in "${temp_files[@]}"; do
        if [[ -f "$temp_file" ]]; then
            echo "  🔍 Checking: $temp_file"
            local start_time=$(get_timestamp)
            local result=$(timeout 8 claude --model "$CLAUDE_MODEL" -p "Analyze this temporary file to determine if it's obsolete. File: $temp_file

$(ls -la "$temp_file" 2>/dev/null || echo 'File not accessible')

Response format: '✅ KEEP: still needed because...' or '❌ OBSOLETE: can be removed because...'" --allowedTools= 2>/dev/null || echo "❌ OBSOLETE: Claude timeout, assume obsolete")
            local end_time=$(get_timestamp)
            local duration=$(calculate_duration "$start_time" "$end_time")
            printf "(%.2fs) " "$duration"
            if [[ "$result" == *"OBSOLETE:"* ]]; then
                echo "    🗑️  OBSOLETE: $temp_file should be removed"
                obsolete_found=true
            else
                echo "    ✅ KEEP: $temp_file is still needed"
            fi
        fi
    done
    
    if [[ "$obsolete_found" == "true" ]]; then
        echo "❌ FAIL: Found obsolete temporary files that should be removed"
        return 1
    else
        echo "✅ PASS: No obsolete temporary files found"
        return 0
    fi
}

test_claude_no_deprecated_files() {
    echo "Testing for obsolete deprecated/legacy files..."
    
    local deprecated_files=($(find . -name "*_deprecated*" -o -name "*_legacy*" -o -name "old_*" -o -name "*_old" 2>/dev/null || true))
    local obsolete_found=false
    
    for deprecated_file in "${deprecated_files[@]}"; do
        if [[ -f "$deprecated_file" ]]; then
            echo "  🔍 Checking: $deprecated_file"
            local start_time=$(get_timestamp)
            local result=$(timeout 8 claude --model "$CLAUDE_MODEL" -p "Analyze this deprecated/legacy file to determine if it's obsolete. File: $deprecated_file

$(ls -la "$deprecated_file" 2>/dev/null || echo 'File not accessible')

Response format: '✅ KEEP: still needed because...' or '❌ OBSOLETE: can be removed because...'" --allowedTools= 2>/dev/null || echo "❌ OBSOLETE: Claude timeout, assume obsolete")
            local end_time=$(get_timestamp)
            local duration=$(calculate_duration "$start_time" "$end_time")
            printf "(%.2fs) " "$duration"
            if [[ "$result" == *"OBSOLETE:"* ]]; then
                echo "    🗑️  OBSOLETE: $deprecated_file should be removed"
                obsolete_found=true
            else
                echo "    ✅ KEEP: $deprecated_file is still needed"
            fi
        fi
    done
    
    if [[ "$obsolete_found" == "true" ]]; then
        echo "❌ FAIL: Found obsolete deprecated files that should be removed"
        return 1
    else
        echo "✅ PASS: No obsolete deprecated files found"
        return 0
    fi
}

test_claude_no_redundant_test_files() {
    echo "Testing for obsolete test files..."
    
    # Look for potentially redundant test files
    local test_files=($(find tests/ -name "*_refactored.zsh" -o -name "*_backup.zsh" -o -name "*_test_old.zsh" 2>/dev/null || true))
    local obsolete_found=false
    
    for test_file in "${test_files[@]}"; do
        if [[ -f "$test_file" ]]; then
            echo "  🔍 Checking: $test_file"
            local start_time=$(get_timestamp)
            local result=$(timeout 8 claude --model "$CLAUDE_MODEL" -p "Analyze this test file to determine if it's obsolete after refactoring. File: $test_file

$(head -20 "$test_file" 2>/dev/null || echo 'File not accessible')

Response format: '✅ KEEP: still needed because...' or '❌ OBSOLETE: can be removed because...'" --allowedTools= 2>/dev/null || echo "❌ OBSOLETE: Claude timeout, assume obsolete")
            local end_time=$(get_timestamp)
            local duration=$(calculate_duration "$start_time" "$end_time")
            printf "(%.2fs) " "$duration"
            if [[ "$result" == *"OBSOLETE:"* ]]; then
                echo "    🗑️  OBSOLETE: $test_file should be removed"
                obsolete_found=true
            else
                echo "    ✅ KEEP: $test_file is still needed"
            fi
        fi
    done
    
    if [[ "$obsolete_found" == "true" ]]; then
        echo "❌ FAIL: Found obsolete test files that should be removed"
        return 1
    else
        echo "✅ PASS: No obsolete test files found"
        return 0
    fi
}

test_claude_no_unused_development_files() {
    echo "Testing for obsolete development artifacts..."
    
    # Look for development artifacts that might be obsolete
    local dev_files=($(find . -maxdepth 2 -name "*.draft" -o -name "*.wip" -o -name "experiment_*" -o -name "prototype_*" 2>/dev/null || true))
    local obsolete_found=false
    
    for dev_file in "${dev_files[@]}"; do
        if [[ -f "$dev_file" ]]; then
            echo "  🔍 Checking: $dev_file"
            local start_time=$(get_timestamp)
            local result=$(timeout 8 claude --model "$CLAUDE_MODEL" -p "Analyze this development artifact to determine if it's obsolete. File: $dev_file

$(ls -la "$dev_file" 2>/dev/null || echo 'File not accessible')

Response format: '✅ KEEP: still needed because...' or '❌ OBSOLETE: can be removed because...'" --allowedTools= 2>/dev/null || echo "❌ OBSOLETE: Claude timeout, assume obsolete")
            local end_time=$(get_timestamp)
            local duration=$(calculate_duration "$start_time" "$end_time")
            printf "(%.2fs) " "$duration"
            if [[ "$result" == *"OBSOLETE:"* ]]; then
                echo "    🗑️  OBSOLETE: $dev_file should be removed"
                obsolete_found=true
            else
                echo "    ✅ KEEP: $dev_file is still needed"
            fi
        fi
    done
    
    if [[ "$obsolete_found" == "true" ]]; then
        echo "❌ FAIL: Found obsolete development files that should be removed"
        return 1
    else
        echo "✅ PASS: No obsolete development files found"
        return 0
    fi
}

# Run all tests with proper exit code tracking
failed_count=0

test_claude_no_backup_files || ((failed_count++))
test_claude_no_temporary_files || ((failed_count++))
test_claude_no_deprecated_files || ((failed_count++))
test_claude_no_redundant_test_files || ((failed_count++))
test_claude_no_unused_development_files || ((failed_count++))

# Exit with failure if any tests failed
if (( failed_count > 0 )); then
    echo "❌ $failed_count tests failed"
    exit 1
else
    echo "✅ All tests passed"
    exit 0
fi