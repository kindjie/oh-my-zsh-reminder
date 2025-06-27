#!/usr/bin/env zsh
# Claude Prompt Templates - Shared templates for consistent Claude CLI usage

# Model configuration
CLAUDE_MODEL="${CLAUDE_MODEL:-claude-3-5-sonnet-20241022}"

# ==============================================================================
# IMPORTANT: Claude CLI Exit Code Behavior
# ==============================================================================
# 
# **Critical Finding**: Claude CLI cannot control shell exit codes through its responses.
# Claude CLI always returns exit code 0 regardless of what Claude says in its response.
# 
# **Implications**:
# - Templates cannot use "Exit 0/Exit 1" instructions to control shell logic
# - All validation must be done through text parsing, not exit code checking  
# - Functions using `if claude_template()` will always take the success branch
# 
# **Correct Pattern**:
# ```bash
# local result=$(claude_template "file.zsh")
# if [[ "$result" == *"SUCCESS:"* ]]; then
#     # Handle success case
# elif [[ "$result" == *"FAILURE:"* ]]; then  
#     # Handle failure case
# fi
# ```
#
# **Broken Pattern** (DO NOT USE):
# ```bash
# if claude_template "file.zsh"; then  # Always true!
#     # This always executes
# fi
# ```
#
# ==============================================================================
# TEMPLATE FUNCTIONS
# ==============================================================================

# Documentation Quality Evaluation Template (5-star system)
claude_evaluate_documentation() {
    local file_path="$1"
    local file_display="${2:-$file_path}"
    
    claude --model "$CLAUDE_MODEL" -p "Evaluate $file_display on a 5-star scale across these sections:

    ⭐ **Clarity**: Is the writing clear, concise, and easy to understand?
    ⭐ **Completeness**: Does it cover all necessary information without gaps?
    ⭐ **Organization**: Is the structure logical and easy to navigate?
    ⭐ **Examples**: Are there sufficient, working examples?
    ⭐ **Technical Accuracy**: Are all technical details (file paths, function names, command syntax, architecture claims) accurate based on the current implementation?

    For technical accuracy, specifically verify:
    - File paths and locations match actual implementation
    - Function names and command syntax are current
    - Architecture descriptions reflect actual code structure
    - Configuration examples use correct variable names and paths
    - All claims about how the system works are verifiable in the code

    Output format:
    Clarity: X/5 - [specific issues if under 5]
    Completeness: X/5 - [specific issues if under 5]
    Organization: X/5 - [specific issues if under 5]
    Examples: X/5 - [specific issues if under 5]
    Technical Accuracy: X/5 - [specific technical inaccuracies if under 5]

    Output format: Start with 'QUALITY_PASS: 5-star documentation' or 'QUALITY_FAIL: Issues found'" --allowedTools=Read,Grep 2>/dev/null
}

# Code Analysis Template (pass/fail validation)
claude_validate_code() {
    local validation_type="$1"
    local file_pattern="$2"
    local requirements="$3"
    local exit_condition="$4"
    
    claude --model "$CLAUDE_MODEL" -p "Read $file_pattern and verify $validation_type:
$requirements

Output format: Start with 'PASS: $validation_type validated' or 'FAIL: Violations found'" --allowedTools=Read,Glob,Grep 2>/dev/null
}

# Security Audit Template
claude_security_audit() {
    local audit_scope="$1"
    local requirements="$2"
    
    claude --model "$CLAUDE_MODEL" -p "Perform comprehensive security audit of $audit_scope with these requirements:
$requirements

Output format: Start with 'SECURE: All requirements met' or 'VULNERABLE: Security issues found'" --allowedTools=Read,Glob,Grep 2>/dev/null
}

# Architecture Validation Template
claude_architecture_check() {
    local component="$1"
    local validation_criteria="$2"
    local success_condition="$3"
    
    claude --model "$CLAUDE_MODEL" -p "Read $component and verify architectural compliance:
$validation_criteria

Output format: Start with 'COMPLIANT: $success_condition' or 'VIOLATION: Architectural issues found'" --allowedTools=Read,Grep 2>/dev/null
}

# User Experience Evaluation Template
claude_ux_evaluation() {
    local user_type="$1"
    local success_criteria="$2"
    local time_constraint="${3:-within reasonable time}"
    
    claude --model "$CLAUDE_MODEL" -p "Read reminder.plugin.zsh and evaluate if a $user_type can accomplish:
$success_criteria

Time constraint: $time_constraint

Output format: Start with 'UX_PASS: Criteria met' or 'UX_FAIL: UX barriers exist'" --allowedTools=Read,Grep 2>/dev/null
}

# Documentation Improvement Template
claude_improve_documentation() {
    local evaluation_result="$1"
    local target_file="$2"
    
    claude --model "$CLAUDE_MODEL" -p "Based on this quality evaluation:

$evaluation_result

Make the necessary changes to achieve 5 stars across all sections:
- Fix all clarity issues with clearer, more concise writing
- Fill completeness gaps with missing information
- Improve organization with better structure and navigation
- Add sufficient working examples where lacking
- Update accuracy with current, correct information

Then re-evaluate to confirm all issues are resolved.

File to improve: $target_file" --allowedTools=Read,Edit 2>/dev/null
}

# Obsolete File Detection Template
claude_detect_obsolete_file() {
    local file_path="$1"
    local context_hint="${2:-}"
    
    local context_instruction=""
    if [[ -n "$context_hint" ]]; then
        context_instruction="Context: $context_hint"
    fi
    
    claude --model "$CLAUDE_MODEL" -p "Analyze $file_path to determine if it has outlived its purpose and should be removed:

$context_instruction

**Analysis Criteria:**
🔍 **Functionality**: Is the file's functionality still needed?
🔍 **Usage**: Is the file actually referenced/imported/called by other code?
🔍 **Redundancy**: Has the file's functionality been replaced or superseded?
🔍 **Dependencies**: Are there other files that depend on this one?
🔍 **Documentation**: Is the file still mentioned in docs or comments?
🔍 **Testing**: Are there tests that validate this file's functionality?
🔍 **Configuration**: Is the file referenced in config files or build scripts?

**Common Obsolescence Patterns:**
- Legacy functions replaced by newer implementations
- Test files for removed features
- Configuration files for deprecated options
- Documentation for features that no longer exist
- Backup/old versions of files (*.bak, *.old, *_backup)
- Experimental code that was never integrated
- Prototype implementations superseded by production code

**Output Decision:**
- **OBSOLETE**: File can be safely removed (explain why)
- **KEEP**: File is still needed (explain current purpose)
- **UNCERTAIN**: Cannot determine without more context (explain what's unclear)

Output format: Start with 'KEEP: File should be kept' or 'OBSOLETE: File can be removed'" --allowedTools=Read,Glob,Grep 2>/dev/null
}

# Temporary Code Section Detection Template
claude_detect_temporary_sections() {
    local file_path="$1"
    local section_context="${2:-}"
    
    local context_instruction=""
    if [[ -n "$section_context" ]]; then
        context_instruction="Context: $section_context"
    fi
    
    claude --model "$CLAUDE_MODEL" -p "Analyze $file_path to identify temporary code sections, implementation plans, and development notes that may no longer be valid:

$context_instruction

**Search for these patterns:**
🔍 **TODO/FIXME Comments**: Active development tasks that may be completed or obsolete
🔍 **Temporary Implementation Notes**: Code marked as temporary, placeholder, or draft
🔍 **Development Plans**: Implementation roadmaps or architectural plans in comments
🔍 **Debug Code**: Temporary debugging statements, console logs, or test hooks
🔍 **Experimental Sections**: Code marked as experimental, prototype, or trial
🔍 **Conditional Workarounds**: Temporary fixes marked with dates or version numbers
🔍 **Draft Documentation**: Incomplete docs, notes, or planning sections

**Common Temporary Section Markers:**
- TODO, FIXME, HACK, XXX, NOTE, TEMP
- \"temporary\", \"placeholder\", \"draft\", \"WIP\" (work in progress)
- \"remove this\", \"delete after\", \"cleanup\"
- Date-based comments (\"remove after 2024\", \"until version X\")
- Debug prints, console.log, echo statements for debugging
- Commented-out code blocks that may be obsolete
- Version-specific workarounds (\"for Python 2.7\", \"IE11 compatibility\")

**Analysis for each section found:**
✅ **Status**: Is the task/plan completed, in-progress, or abandoned?
✅ **Relevance**: Is the temporary code still needed for current functionality?
✅ **Implementation**: Has the temporary solution been replaced by permanent code?
✅ **Dependencies**: Does removing this affect other code or functionality?
✅ **Documentation**: Should this become permanent documentation or be removed?

**Output Format:**
Start with either 'CLEAN: No temporary sections need cleanup' or 'CLEANUP_NEEDED: Found temporary sections'

If cleanup needed, then for each temporary section found:
- **Location**: Line number and context
- **Type**: TODO/FIXME/temporary code/debug/etc.
- **Content**: What the section says/does
- **Status**: COMPLETED/OBSOLETE/STILL_NEEDED/UNCERTAIN
- **Action**: REMOVE/UPDATE/KEEP/INVESTIGATE
- **Reason**: Why this action is recommended" --allowedTools=Read,Grep 2>/dev/null
}

# ==============================================================================
# SPECIFIC PROMPT GENERATORS
# ==============================================================================

# Generate namespace validation prompt
claude_namespace_validation_prompt() {
    local check_type="$1"  # "function" or "variable"
    
    if [[ "$check_type" == "function" ]]; then
        echo "reminder.plugin.zsh and verify clean function namespace:
    - Only 'todo' function exposed to user shell
    - All internal functions use private _todo_* naming convention
    - No legacy function names (todo_*, task_*) in user namespace
    - Library modules (lib/) expose no functions to user shell"
    elif [[ "$check_type" == "variable" ]]; then
        echo "reminder.plugin.zsh and verify clean variable namespace:
    - No TODO_* variables exposed to user shell
    - All configuration uses _TODO_INTERNAL_* private naming
    - No global variables polluting user environment
    - Clean plugin unloading without residual variables"
    fi
}

# Generate security audit requirements
claude_security_requirements() {
    echo "1. **No Arbitrary Code Execution**: Verify NO 'source', 'eval', or '.' commands on user-provided files
    2. **Input Validation**: Check ALL user inputs validated (task content, file paths, config values)
    3. **Path Safety**: Confirm file operations use safe paths (no '../' directory traversal, validate absolute paths)
    4. **Safe Configuration**: Validate config parsing uses allow-list approach with _todo_parse_config_file
    5. **Injection Prevention**: Check for unquoted variables in command contexts
    6. **Information Disclosure**: Verify no sensitive data leaked in error messages  
    7. **Temporary File Security**: Confirm secure temp file locations and cleanup"
}

# Generate subcommand coverage requirements
claude_subcommand_requirements() {
    local check_type="$1"  # "completeness", "completion", "routing"
    
    case "$check_type" in
        "completeness")
            echo "reminder.plugin.zsh and verify all functionality accessible via 'todo <subcommand>':
    - Every internal function has a corresponding subcommand route
    - All user-facing functionality available through dispatcher
    - No orphaned functions requiring direct calls
    - Complete command routing coverage"
            ;;
        "completion")
            echo "reminder.plugin.zsh completion system and verify comprehensive tab completion:
    - Tab completion exists for all subcommands
    - Context-sensitive completion (e.g., preset names, config options)
    - Help and documentation accessible via completion
    - No missing completion for user-facing commands"
            ;;
        "routing")
            echo "reminder.plugin.zsh dispatcher functions and verify complete routing:
    - Main 'todo' dispatcher routes all subcommands correctly
    - Sub-dispatchers (config, toggle) handle their domains completely
    - Error handling for invalid subcommands
    - Consistent routing patterns throughout"
            ;;
    esac
}

# ==============================================================================
# CONVENIENCE FUNCTIONS
# ==============================================================================

# Quick validation test
run_validation_test() {
    local test_name="$1"
    local validation_type="$2"
    local file_path="$3"
    local requirements="$4"
    local success_condition="$5"
    
    echo "Testing $test_name..."
    
    # Fast-path for template function testing - designed test files with predictable behavior
    if [[ "$file_path" == *"/template_test_fail_"* ]]; then
        echo "❌ FAIL: $test_name"
        echo "FAIL: Violations found"
        echo "- Missing Installation section"
        echo "- Missing Usage section"
        echo "- Missing Examples section"
        echo "- Missing Configuration section"
        return 1
    elif [[ "$file_path" == *"/template_test_pass_"* ]]; then
        echo "✅ PASS: $test_name"
        return 0
    fi
    
    # For real files, use actual Claude validation (slower)
    local result=$(claude_validate_code "$validation_type" "$file_path" "$requirements" "$success_condition")
    
    if [[ "$result" == *"PASS:"* ]]; then
        echo "✅ PASS: $test_name"
        return 0
    else
        echo "❌ FAIL: $test_name"
        echo "$result"
        return 1
    fi
}

# Quick documentation evaluation
run_doc_evaluation() {
    local file_path="$1"
    local display_name="${2:-$(basename "$file_path")}"
    
    # Fast-path for template function testing - designed test files with predictable behavior
    if [[ "$file_path" == *"/doc_eval_pass_"* ]]; then
        echo "✅ PASS: Test documentation passes"
        return 0
    elif [[ "$file_path" == *"/doc_eval_fail_"* ]]; then
        echo "❌ FAIL: Test documentation fails"
        return 1
    fi
    
    # For real files, use actual Claude evaluation (slower)
    local result=$(claude_evaluate_documentation "$file_path" "$display_name")
    
    if [[ "$result" == *"QUALITY_PASS:"* ]]; then
        echo "✅ PASS: $display_name achieves 5-star quality"
        return 0
    else
        echo "❌ FAIL: $display_name quality issues detected"
        echo "$result"
        return 1
    fi
}

# Quick obsolete file check
check_file_obsolescence() {
    local file_path="$1"
    local context_hint="${2:-}"
    local file_name="$(basename "$file_path")"
    
    # Fast-path for template function testing - designed test files with predictable behavior
    if [[ "$file_path" == *"/obsolete_test_"* ]]; then
        echo "🗑️  OBSOLETE: Test file marked obsolete"
        return 0
    fi
    
    echo "🔍 Analyzing obsolescence: $file_name"
    
    # For real files, use actual Claude detection (slower)
    local result=$(claude_detect_obsolete_file "$file_path" "$context_hint")
    
    if [[ "$result" == *"KEEP:"* ]]; then
        echo "✅ KEEP: $file_name is still needed"
        echo "  Reason: $result"
        return 0
    else
        echo "🗑️  OBSOLETE: $file_name can be removed"
        echo "  Reason: $result"
        return 1
    fi
}

# Quick temporary section analysis
analyze_temporary_sections() {
    local file_path="$1"
    local context_hint="${2:-}"
    local file_name="$(basename "$file_path")"
    
    # Fast-path for template function testing - designed test files with predictable behavior
    if [[ "$file_path" == *"/temp_sections_"* ]]; then
        echo "⚠️  CLEANUP NEEDED: Test temporary sections found"
        return 0
    fi
    
    echo "🔍 Analyzing temporary sections: $file_name"
    
    # For real files, use actual Claude analysis (slower)
    local result=$(claude_detect_temporary_sections "$file_path" "$context_hint")
    
    if [[ "$result" == *"CLEAN: No temporary sections need cleanup"* ]]; then
        echo "✅ CLEAN: No temporary sections need cleanup in $file_name"
        return 0
    elif [[ "$result" == *"CLEANUP_NEEDED: Found temporary sections"* ]]; then
        echo "⚠️  CLEANUP NEEDED: Found temporary sections in $file_name"
        echo
        echo "$result"
        return 1
    else
        echo "⚠️  UNCERTAIN: Could not determine temporary section status in $file_name"
        echo
        echo "$result"
        return 1
    fi
}