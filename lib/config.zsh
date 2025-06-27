#!/usr/bin/env zsh
# Configuration management module for todo-reminder
# Handles presets, validation, export/import, and user data migration

# Guard against multiple loads
[[ -n "$_TODO_CONFIG_LOADED" ]] && return 0
typeset -gr _TODO_CONFIG_LOADED=1

# Private module variables (use local scope where possible)
typeset -g _TODO_CONFIG_DIR _TODO_USER_PRESETS_DIR _TODO_BUILTIN_PRESETS_DIR _TODO_DEFAULT_SAVE_FILE

# ============================================================================
# Secure Configuration File Parsing
# ============================================================================

# Valid configuration keys (allow list)
typeset -g -a _TODO_VALID_CONFIG_KEYS
_TODO_VALID_CONFIG_KEYS=(
    "TODO_PRESET_DESC"
    "TODO_COLOR_MODE"
    "TODO_TITLE"
    "TODO_HEART_CHAR"
    "TODO_HEART_POSITION"
    "TODO_BULLET_CHAR"
    "TODO_BOX_WIDTH_FRACTION"
    "TODO_BOX_MIN_WIDTH"
    "TODO_BOX_MAX_WIDTH"
    "TODO_SHOW_AFFIRMATION"
    "TODO_SHOW_TODO_BOX"
    "TODO_SHOW_HINTS"
    "TODO_PADDING_TOP"
    "TODO_PADDING_RIGHT"
    "TODO_PADDING_BOTTOM"
    "TODO_PADDING_LEFT"
    "TODO_TASK_COLORS"
    "TODO_BORDER_COLOR"
    "TODO_BORDER_BG_COLOR"
    "TODO_CONTENT_BG_COLOR"
    "TODO_TASK_TEXT_COLOR"
    "TODO_TITLE_COLOR"
    "TODO_AFFIRMATION_COLOR"
    "TODO_BULLET_COLOR"
    "TODO_BOX_TOP_LEFT"
    "TODO_BOX_TOP_RIGHT"
    "TODO_BOX_BOTTOM_LEFT"
    "TODO_BOX_BOTTOM_RIGHT"
    "TODO_BOX_HORIZONTAL"
    "TODO_BOX_VERTICAL"
)

# Check if configuration key is valid
function _todo_is_valid_config_key() {
    local key="$1"
    [[ " ${_TODO_VALID_CONFIG_KEYS[*]} " =~ " $key " ]]
}

# Validate configuration value based on key
function _todo_validate_config_value() {
    local key="$1"
    local value="$2"
    
    case "$key" in
        TODO_COLOR_MODE)
            [[ "$value" =~ ^(static|dynamic|auto)$ ]]
            ;;
        TODO_HEART_POSITION)
            [[ "$value" =~ ^(left|right|both|none)$ ]]
            ;;
        TODO_SHOW_AFFIRMATION|TODO_SHOW_TODO_BOX|TODO_SHOW_HINTS)
            [[ "$value" =~ ^(true|false)$ ]]
            ;;
        TODO_PADDING_*|TODO_BOX_MIN_WIDTH|TODO_BOX_MAX_WIDTH)
            [[ "$value" =~ ^[0-9]+$ ]]
            ;;
        TODO_BOX_WIDTH_FRACTION)
            [[ "$value" =~ ^(0?\.[0-9]+|1\.0)$ ]]
            ;;
        TODO_TASK_COLORS)
            [[ "$value" =~ ^[0-9]+(,[0-9]+)*$ ]]
            ;;
        TODO_BORDER_COLOR|TODO_BORDER_BG_COLOR|TODO_CONTENT_BG_COLOR|TODO_TASK_TEXT_COLOR|TODO_TITLE_COLOR|TODO_AFFIRMATION_COLOR|TODO_BULLET_COLOR)
            [[ "$value" =~ ^[0-9]+$ ]] && [[ $value -le 255 ]]
            ;;
        TODO_TITLE|TODO_HEART_CHAR|TODO_BULLET_CHAR|TODO_BOX_*|TODO_PRESET_DESC)
            # String values - check length and reject dangerous patterns
            [[ ${#value} -le 200 ]] && [[ ! "$value" =~ [\$\`\;] ]]
            ;;
        *)
            false
            ;;
    esac
}

# Safely parse configuration file without executing code
function _todo_parse_config_file() {
    local config_file="$1"
    local line_num=0
    local parsed_count=0
    local ignored_count=0
    
    [[ ! -f "$config_file" ]] && return 1
    
    while IFS= read -r line; do
        ((line_num++))
        
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Only allow KEY=VALUE or KEY="VALUE" format
        if [[ "$line" =~ '^([A-Z_][A-Z0-9_]*)=(.*)$' ]]; then
            local key="${match[1]}"
            local value="${match[2]}"
            
            # Remove quotes if present
            value="${value#\"}"
            value="${value%\"}"
            
            # Validate key is in allow list
            if _todo_is_valid_config_key "$key"; then
                # Validate and sanitize value
                if _todo_validate_config_value "$key" "$value"; then
                    typeset -g "$key"="$value"
                    ((parsed_count++))
                else
                    echo "Warning: Invalid value for $key on line $line_num: '$value'" >&2
                    ((ignored_count++))
                fi
            else
                echo "Warning: Unknown configuration key '$key' on line $line_num" >&2
                ((ignored_count++))
            fi
        else
            echo "Warning: Invalid line format on line $line_num: '$line'" >&2
            ((ignored_count++))
        fi
    done < "$config_file"
    
    # Report parsing results
    if [[ $ignored_count -gt 0 ]]; then
        echo "Parsed $parsed_count valid settings, ignored $ignored_count invalid lines" >&2
    fi
    
    return 0
}

# Configuration paths initialization
function __todo_config_init_paths() {
    local config_dir="$HOME/.config/todo-reminder"
    local plugin_dir="${_TODO_INTERNAL_PLUGIN_DIR:-${0:A:h}}"
    
    # Handle case where config.zsh is loaded directly (for tests)
    if [[ "$plugin_dir" == */lib ]]; then
        plugin_dir="${plugin_dir:h}"  # Go up one directory from lib/
    fi
    
    _TODO_CONFIG_DIR="$config_dir"
    _TODO_USER_PRESETS_DIR="$config_dir/presets"
    _TODO_BUILTIN_PRESETS_DIR="$plugin_dir/presets"
    _TODO_DEFAULT_SAVE_FILE="$config_dir/data.save"
    
    # Initialize TODO_SAVE_FILE if not already set
    TODO_SAVE_FILE="${TODO_SAVE_FILE:-$_TODO_DEFAULT_SAVE_FILE}"
}

# Ensure config directories exist
function __todo_ensure_config_dirs() {
    __todo_config_init_paths
    local dirs=("$_TODO_CONFIG_DIR" "$_TODO_USER_PRESETS_DIR")
    for dir in "${dirs[@]}"; do
        [[ ! -d "$dir" ]] && mkdir -p "$dir"
    done
}

# One-time migration from old locations
function __todo_migrate_user_data() {
    __todo_ensure_config_dirs
    
    # Skip migration if disabled (e.g., during tests)
    [[ "$TODO_DISABLE_MIGRATION" == "true" ]] && return 0
    
    # Migrate old save file
    local old_save="$HOME/.todo.save"
    if [[ -f "$old_save" ]] && [[ ! -f "$TODO_SAVE_FILE" ]]; then
        cp "$old_save" "$TODO_SAVE_FILE"
        echo "📦 Migrated todo data to $TODO_SAVE_FILE"
        echo "   (Original file preserved at $old_save)"
    fi
    
    # Migrate old user presets from ~/.config/todo-reminder-*.conf
    local old_files=("$HOME"/.config/todo-reminder-*.conf(N))
    for old_file in "${old_files[@]}"; do
        [[ -f "$old_file" ]] || continue
        local name="${old_file:t}"
        name="${name#todo-reminder-}"  # Remove prefix
        local new_file="$_TODO_USER_PRESETS_DIR/$name"
        if [[ ! -f "$new_file" ]]; then
            cp "$old_file" "$new_file"
            echo "📦 Migrated preset to $new_file"
        fi
    done
}

# Validate configuration variables (private)
function __todo_validate_config() {
    local errors=()
    
    # Validate numeric values
    local numeric_vars=(
        "TODO_PADDING_TOP" "TODO_PADDING_RIGHT" "TODO_PADDING_BOTTOM" "TODO_PADDING_LEFT"
        "TODO_BOX_MIN_WIDTH" "TODO_BOX_MAX_WIDTH" "TODO_BORDER_COLOR" "TODO_TITLE_COLOR"
        "TODO_TASK_TEXT_COLOR" "TODO_AFFIRMATION_COLOR" "TODO_BORDER_BG_COLOR" "TODO_CONTENT_BG_COLOR"
    )
    
    for var in "${numeric_vars[@]}"; do
        local value="${(P)var}"
        if [[ -n "$value" ]] && [[ ! "$value" =~ ^[0-9]+$ ]]; then
            errors+=("$var must be numeric, got: '$value'")
        fi
    done
    
    # Validate boolean values
    local bool_vars=("TODO_SHOW_AFFIRMATION" "TODO_SHOW_TODO_BOX" "TODO_SHOW_HINTS")
    for var in "${bool_vars[@]}"; do
        local value="${(P)var}"
        if [[ -n "$value" ]] && [[ "$value" != "true" && "$value" != "false" ]]; then
            errors+=("$var must be 'true' or 'false', got: '$value'")
        fi
    done
    
    # Validate heart position
    if [[ -n "$TODO_HEART_POSITION" ]]; then
        local valid_positions=("left" "right" "both" "none")
        if [[ ! "${valid_positions[@]}" =~ "$TODO_HEART_POSITION" ]]; then
            errors+=("TODO_HEART_POSITION must be one of: ${valid_positions[*]}")
        fi
    fi
    
    # Validate color lists
    if [[ -n "$TODO_TASK_COLORS" ]]; then
        local IFS=','
        local -a colors=(${=TODO_TASK_COLORS})
        for color in "${colors[@]}"; do
            if [[ ! "$color" =~ ^[0-9]+$ ]] || [[ "$color" -gt 255 ]]; then
                errors+=("Invalid color in TODO_TASK_COLORS: '$color' (must be 0-255)")
                break
            fi
        done
    fi
    
    # Return validation results
    if [[ ${#errors} -gt 0 ]]; then
        printf '%s\n' "${errors[@]}"
        return 1
    fi
    return 0
}

# Validate a config file before loading (private)
function __todo_validate_config_file() {
    local file="$1"
    
    # Validate the config file safely (no code execution)
    # Capture stderr to detect validation warnings
    local validation_output
    validation_output=$(_todo_parse_config_file "$file" 2>&1 >/dev/null)
    
    # If there were validation warnings/errors, fail validation
    if [[ -n "$validation_output" ]]; then
        echo "$validation_output" >&2
        return 1
    fi
    
    return 0
}

# Get preset file path (private)
function __todo_get_preset_path() {
    local preset_name="$1"
    __todo_config_init_paths
    
    # Check user presets first
    local user_file="$_TODO_USER_PRESETS_DIR/${preset_name}.conf"
    if [[ -f "$user_file" ]]; then
        echo "$user_file"
        return 0
    fi
    
    # Check built-in presets
    local builtin_file="$_TODO_BUILTIN_PRESETS_DIR/${preset_name}.conf"
    if [[ -f "$builtin_file" ]]; then
        echo "$builtin_file"
        return 0
    fi
    
    return 1
}

# Find preset with tinted variant support (private)
function __todo_find_preset_file() {
    local preset_name="$1"
    local tinted_variant="${preset_name}_tinted"
    
    # Auto-select tinted variant if available and tinted-shell active
    if [[ "$TINTED_SHELL_ENABLE_BASE16_VARS" == "1" ]]; then
        local tinted_file="$(__todo_get_preset_path "$tinted_variant")"
        if [[ -f "$tinted_file" ]]; then
            echo "$tinted_file"
            return 0
        fi
    fi
    
    # Fall back to regular preset
    __todo_get_preset_path "$preset_name"
}

# PUBLIC API FUNCTIONS

# Find all available presets
function todo_config_find_presets() {
    __todo_config_init_paths
    local -A presets=()  # Associative array: name -> source
    
    # Built-in presets (repo)
    if [[ -d "$_TODO_BUILTIN_PRESETS_DIR" ]]; then
        local builtin_files=("$_TODO_BUILTIN_PRESETS_DIR"/*.conf(N))
        for file in "${builtin_files[@]}"; do
            [[ -f "$file" ]] || continue
            local name="${file:t:r}"  # filename without extension
            presets[$name]="builtin:$file"
        done
    fi
    
    # User presets (override built-ins)
    if [[ -d "$_TODO_USER_PRESETS_DIR" ]]; then
        local user_files=("$_TODO_USER_PRESETS_DIR"/*.conf(N))
        for file in "${user_files[@]}"; do
            [[ -f "$file" ]] || continue
            local name="${file:t:r}"
            presets[$name]="user:$file"
        done
    fi
    
    # Output format: "name:source:filepath"
    for name in "${(@k)presets}"; do
        echo "$name:${presets[$name]}"
    done
}

# Get preset description
function todo_config_get_preset_description() {
    local preset_name="$1"
    local preset_file="$(__todo_find_preset_file "$preset_name")"
    
    [[ -f "$preset_file" ]] || return 1
    
    # Extract TODO_PRESET_DESC from file
    grep '^TODO_PRESET_DESC=' "$preset_file" 2>/dev/null | \
        sed 's/^TODO_PRESET_DESC="//' | sed 's/"$//'
}

# List preset names only (for arrays) - internal use, shows all presets
function _todo_config_get_preset_names() {
    todo_config_find_presets | cut -d: -f1 | sort -u
}

# List user-facing preset names (filtered base presets only)
function _todo_config_get_user_preset_names() {
    # Filter out _tinted variants to show only semantic base presets
    _todo_config_get_preset_names | grep -v '_tinted$' | sort -u
}

# Apply a preset by name
function todo_config_apply_preset() {
    local preset_name="$1"
    local actual_preset_name="$preset_name"
    
    # Smart preset selection based on color mode and tinted detection
    if _should_use_tinted_preset && [[ "$preset_name" != *"_tinted" ]]; then
        # Try to use tinted variant if available
        local tinted_name="${preset_name}_tinted"
        if [[ -f "$(__todo_find_preset_file "$tinted_name")" ]]; then
            actual_preset_name="$tinted_name"
        fi
    elif ! _should_use_tinted_preset && [[ "$preset_name" == *"_tinted" ]]; then
        # Force static: remove _tinted suffix if user explicitly requested tinted preset
        actual_preset_name="${preset_name%_tinted}"
    fi
    
    local preset_file="$(__todo_find_preset_file "$actual_preset_name")"
    
    if [[ ! -f "$preset_file" ]]; then
        echo "Error: Preset '$preset_name' not found" >&2
        echo "Available presets: $(_todo_config_get_user_preset_names | tr '\n' ' ')" >&2
        echo "💡 Theme-adaptive variants are selected automatically based on your TODO_COLOR_MODE setting" >&2
        return 1
    fi
    
    # Validate before applying
    if ! __todo_validate_config_file "$preset_file"; then
        echo "Error: Invalid preset configuration in $preset_file" >&2
        return 1
    fi
    
    # Clear preset description from previous load
    unset TODO_PRESET_DESC
    
    # Parse the config file safely (no code execution)
    _todo_parse_config_file "$preset_file"
    
    # Convert loaded variables to internal format
    _todo_convert_to_internal_vars
    
    # Show what was applied with smart feedback
    if [[ "$actual_preset_name" != "$preset_name" ]]; then
        echo "Applied preset: $preset_name → $actual_preset_name (color-mode: $_TODO_INTERNAL_COLOR_MODE)"
    else
        echo "Applied preset: $preset_name (color-mode: $_TODO_INTERNAL_COLOR_MODE)"
    fi
    if [[ -n "$TODO_PRESET_DESC" ]]; then
        echo "  $TODO_PRESET_DESC"
    fi
    
    # Handle tinted-shell integration message based on actual selection
    if [[ "$actual_preset_name" == *"_tinted" ]]; then
        case "$_TODO_INTERNAL_COLOR_MODE" in
            "dynamic") echo "🎨 Using theme-adaptive colors (forced dynamic mode)" ;;
            "auto") 
                if [[ "$TINTED_SHELL_ENABLE_BASE16_VARS" == "1" ]]; then
                    echo "🎨 Using theme-adaptive colors (tinted-shell detected)"
                elif command -v tinty >/dev/null 2>&1; then
                    echo "🎨 Using theme-adaptive colors (tinty available)"
                else
                    echo "🎨 Using theme-adaptive colors"
                fi
                ;;
        esac
    elif command -v tinty >/dev/null 2>&1 && [[ "$_TODO_INTERNAL_COLOR_MODE" == "auto" ]]; then
        echo "💡 Tip: Use 'tinty apply [theme]' for theme integration"
    fi
    
    # Update color arrays
    _TODO_INTERNAL_COLORS=(${(@s:,:)_TODO_INTERNAL_TASK_COLORS})
    
    return 0
}

# Export current configuration
function todo_config_export_config() {
    local output_file="$1"
    local colors_only="${2:-false}"
    
    # Configuration variables to export
    local config_vars=(
        "TODO_TITLE" "TODO_HEART_CHAR" "TODO_HEART_POSITION" "TODO_BULLET_CHAR"
        "TODO_SHOW_AFFIRMATION" "TODO_SHOW_TODO_BOX" "TODO_SHOW_HINTS"
        "TODO_PADDING_TOP" "TODO_PADDING_RIGHT" "TODO_PADDING_BOTTOM" "TODO_PADDING_LEFT"
        "TODO_BOX_WIDTH_FRACTION" "TODO_BOX_MIN_WIDTH" "TODO_BOX_MAX_WIDTH"
        "TODO_BOX_TOP_LEFT" "TODO_BOX_TOP_RIGHT" "TODO_BOX_BOTTOM_LEFT" 
        "TODO_BOX_BOTTOM_RIGHT" "TODO_BOX_HORIZONTAL" "TODO_BOX_VERTICAL"
    )
    
    local color_vars=(
        "TODO_TASK_COLORS" "TODO_BORDER_COLOR" "TODO_BORDER_BG_COLOR" 
        "TODO_CONTENT_BG_COLOR" "TODO_TASK_TEXT_COLOR" "TODO_TITLE_COLOR"
        "TODO_AFFIRMATION_COLOR" "TODO_BULLET_COLOR"
    )
    
    # Select variables to export
    local -a vars_to_export=()
    if [[ "$colors_only" == "true" ]]; then
        vars_to_export=("${color_vars[@]}")
    else
        vars_to_export=("${config_vars[@]}" "${color_vars[@]}")
    fi
    
    # Generate export content using internal variables but exporting as TODO_* format
    local export_content=""
    for var in "${vars_to_export[@]}"; do
        # Map TODO_* variable names to _TODO_INTERNAL_* variables
        local internal_var=""
        case "$var" in
            "TODO_TITLE") internal_var="_TODO_INTERNAL_TITLE" ;;
            "TODO_HEART_CHAR") internal_var="_TODO_INTERNAL_HEART_CHAR" ;;
            "TODO_HEART_POSITION") internal_var="_TODO_INTERNAL_HEART_POSITION" ;;
            "TODO_BULLET_CHAR") internal_var="_TODO_INTERNAL_BULLET_CHAR" ;;
            "TODO_SHOW_AFFIRMATION") internal_var="_TODO_INTERNAL_SHOW_AFFIRMATION" ;;
            "TODO_SHOW_TODO_BOX") internal_var="_TODO_INTERNAL_SHOW_TODO_BOX" ;;
            "TODO_SHOW_HINTS") internal_var="_TODO_INTERNAL_SHOW_HINTS" ;;
            "TODO_PADDING_TOP") internal_var="_TODO_INTERNAL_PADDING_TOP" ;;
            "TODO_PADDING_RIGHT") internal_var="_TODO_INTERNAL_PADDING_RIGHT" ;;
            "TODO_PADDING_BOTTOM") internal_var="_TODO_INTERNAL_PADDING_BOTTOM" ;;
            "TODO_PADDING_LEFT") internal_var="_TODO_INTERNAL_PADDING_LEFT" ;;
            "TODO_BOX_WIDTH_FRACTION") internal_var="_TODO_INTERNAL_BOX_WIDTH_FRACTION" ;;
            "TODO_BOX_MIN_WIDTH") internal_var="_TODO_INTERNAL_BOX_MIN_WIDTH" ;;
            "TODO_BOX_MAX_WIDTH") internal_var="_TODO_INTERNAL_BOX_MAX_WIDTH" ;;
            "TODO_BOX_TOP_LEFT") internal_var="_TODO_INTERNAL_BOX_TOP_LEFT" ;;
            "TODO_BOX_TOP_RIGHT") internal_var="_TODO_INTERNAL_BOX_TOP_RIGHT" ;;
            "TODO_BOX_BOTTOM_LEFT") internal_var="_TODO_INTERNAL_BOX_BOTTOM_LEFT" ;;
            "TODO_BOX_BOTTOM_RIGHT") internal_var="_TODO_INTERNAL_BOX_BOTTOM_RIGHT" ;;
            "TODO_BOX_HORIZONTAL") internal_var="_TODO_INTERNAL_BOX_HORIZONTAL" ;;
            "TODO_BOX_VERTICAL") internal_var="_TODO_INTERNAL_BOX_VERTICAL" ;;
            "TODO_TASK_COLORS") internal_var="_TODO_INTERNAL_TASK_COLORS" ;;
            "TODO_BORDER_COLOR") internal_var="_TODO_INTERNAL_BORDER_COLOR" ;;
            "TODO_BORDER_BG_COLOR") internal_var="_TODO_INTERNAL_BORDER_BG_COLOR" ;;
            "TODO_CONTENT_BG_COLOR") internal_var="_TODO_INTERNAL_CONTENT_BG_COLOR" ;;
            "TODO_TASK_TEXT_COLOR") internal_var="_TODO_INTERNAL_TASK_TEXT_COLOR" ;;
            "TODO_TITLE_COLOR") internal_var="_TODO_INTERNAL_TITLE_COLOR" ;;
            "TODO_AFFIRMATION_COLOR") internal_var="_TODO_INTERNAL_AFFIRMATION_COLOR" ;;
            "TODO_BULLET_COLOR") internal_var="_TODO_INTERNAL_BULLET_COLOR" ;;
            *) internal_var="$var" ;;  # Fallback for unmapped variables
        esac
        
        local value="${(P)internal_var}"
        if [[ -n "$value" ]]; then
            export_content+="$var=\"$value\"\n"
        fi
    done
    
    # Output to file or stdout
    if [[ -n "$output_file" ]]; then
        echo -e "$export_content" > "$output_file"
        echo "Configuration exported to: $output_file"
    else
        echo -e "$export_content"
    fi
}

# Import configuration from file
function todo_config_import_config() {
    local config_file="$1"
    
    [[ -f "$config_file" ]] || {
        echo "Error: Configuration file not found: $config_file" >&2
        return 1
    }
    
    # Validate before importing
    if ! __todo_validate_config_file "$config_file"; then
        echo "Error: Invalid configuration file: $config_file" >&2
        return 1
    fi
    
    # Parse the configuration safely (no code execution)
    _todo_parse_config_file "$config_file"
    
    # Convert loaded variables to internal format
    _todo_convert_to_internal_vars
    
    echo "Configuration imported from: $config_file"
    
    return 0
}

# Save current config as user preset
function todo_config_save_user_preset() {
    local preset_name="$1"
    local description="$2"
    
    __todo_ensure_config_dirs
    
    # Clean preset name
    preset_name="${preset_name//[^a-zA-Z0-9_-]/}"
    [[ -z "$preset_name" ]] && {
        echo "Error: Invalid preset name" >&2
        return 1
    }
    
    local preset_file="$_TODO_USER_PRESETS_DIR/${preset_name}.conf"
    
    # Add description if provided
    local temp_desc=""
    if [[ -n "$description" ]]; then
        temp_desc="TODO_PRESET_DESC=\"$description\"\n"
    fi
    
    # Export to preset file
    (
        [[ -n "$temp_desc" ]] && echo -e "$temp_desc"
        todo_config_export_config
    ) > "$preset_file"
    
    echo "Saved preset as: $preset_file"
}

# Initialize configuration module
function __todo_config_module_init() {
    __todo_config_init_paths
    __todo_migrate_user_data
    __todo_ensure_config_dirs
}

# Preview color swatches for available presets
function todo_config_preview_presets() {
    local preset="${1:-all}"
    
    echo "🎨 Todo Reminder Preset Preview"
    echo "════════════════════════════════"
    echo
    
    if [[ "$preset" == "all" ]]; then
        local preset_names=($(_todo_config_get_preset_names))
        for p in "${preset_names[@]}"; do
            __todo_show_preset_swatch "$p"
            echo
        done
        
        # Show tinty integration tip
        if command -v tinty >/dev/null 2>&1; then
            echo "💡 Tinty Integration:"
            echo "  ✅ tinty detected - use 'tinty apply [theme]' for 200+ themes"
        else
            echo "💡 Tip: Install tinty + tinted-shell for 200+ additional themes"
        fi
    else
        __todo_show_preset_swatch "$preset"
    fi
}

# Show color swatch for a specific preset (private)
function __todo_show_preset_swatch() {
    local preset="$1"
    
    # Get preset file path
    local preset_file="$(__todo_find_preset_file "$preset")"
    
    if [[ ! -f "$preset_file" ]]; then
        echo "❌ Unknown preset: $preset"
        return 1
    fi
    
    # Load preset in subshell to avoid affecting current config
    (
        _todo_parse_config_file "$preset_file"
        
        echo "📦 ${(C)preset} Theme:"
        echo -n "  Title: \e[38;5;${TODO_TITLE_COLOR}m${TODO_TITLE}\e[0m"
        echo "  Border: \e[38;5;${TODO_BORDER_COLOR}m█\e[0m"
        echo -n "  Colors: "
        
        # Show color swatches
        IFS=',' read -A colors <<< "$TODO_TASK_COLORS"
        for color in "${colors[@]}"; do
            echo -n "\e[38;5;${color}m●\e[0m "
        done
        echo
        echo "  Text: \e[38;5;${TODO_TASK_TEXT_COLOR}m▪ Sample task item\e[0m"
    )
}

# Convert loaded TODO_* variables to internal _TODO_INTERNAL_* variables
function _todo_convert_to_internal_vars() {
    # Configuration variables mapping
    [[ -n "$TODO_SAVE_FILE" ]] && _TODO_INTERNAL_SAVE_FILE="$TODO_SAVE_FILE"
    [[ -n "$TODO_AFFIRMATION_FILE" ]] && _TODO_INTERNAL_AFFIRMATION_FILE="$TODO_AFFIRMATION_FILE"
    [[ -n "$TODO_COLOR_MODE" ]] && _TODO_INTERNAL_COLOR_MODE="$TODO_COLOR_MODE"
    [[ -n "$TODO_BOX_WIDTH_FRACTION" ]] && _TODO_INTERNAL_BOX_WIDTH_FRACTION="$TODO_BOX_WIDTH_FRACTION"
    [[ -n "$TODO_BOX_MIN_WIDTH" ]] && _TODO_INTERNAL_BOX_MIN_WIDTH="$TODO_BOX_MIN_WIDTH"
    [[ -n "$TODO_BOX_MAX_WIDTH" ]] && _TODO_INTERNAL_BOX_MAX_WIDTH="$TODO_BOX_MAX_WIDTH"
    [[ -n "$TODO_TITLE" ]] && _TODO_INTERNAL_TITLE="$TODO_TITLE"
    [[ -n "$TODO_HEART_CHAR" ]] && _TODO_INTERNAL_HEART_CHAR="$TODO_HEART_CHAR"
    [[ -n "$TODO_HEART_POSITION" ]] && _TODO_INTERNAL_HEART_POSITION="$TODO_HEART_POSITION"
    [[ -n "$TODO_BULLET_CHAR" ]] && _TODO_INTERNAL_BULLET_CHAR="$TODO_BULLET_CHAR"
    [[ -n "$TODO_SHOW_AFFIRMATION" ]] && _TODO_INTERNAL_SHOW_AFFIRMATION="$TODO_SHOW_AFFIRMATION"
    [[ -n "$TODO_SHOW_TODO_BOX" ]] && _TODO_INTERNAL_SHOW_TODO_BOX="$TODO_SHOW_TODO_BOX"
    [[ -n "$TODO_SHOW_HINTS" ]] && _TODO_INTERNAL_SHOW_HINTS="$TODO_SHOW_HINTS"
    [[ -n "$TODO_PADDING_TOP" ]] && _TODO_INTERNAL_PADDING_TOP="$TODO_PADDING_TOP"
    [[ -n "$TODO_PADDING_RIGHT" ]] && _TODO_INTERNAL_PADDING_RIGHT="$TODO_PADDING_RIGHT"
    [[ -n "$TODO_PADDING_BOTTOM" ]] && _TODO_INTERNAL_PADDING_BOTTOM="$TODO_PADDING_BOTTOM"
    [[ -n "$TODO_PADDING_LEFT" ]] && _TODO_INTERNAL_PADDING_LEFT="$TODO_PADDING_LEFT"
    [[ -n "$TODO_TASK_COLORS" ]] && _TODO_INTERNAL_TASK_COLORS="$TODO_TASK_COLORS"
    [[ -n "$TODO_BORDER_COLOR" ]] && _TODO_INTERNAL_BORDER_COLOR="$TODO_BORDER_COLOR"
    [[ -n "$TODO_BORDER_BG_COLOR" ]] && _TODO_INTERNAL_BORDER_BG_COLOR="$TODO_BORDER_BG_COLOR"
    [[ -n "$TODO_CONTENT_BG_COLOR" ]] && _TODO_INTERNAL_CONTENT_BG_COLOR="$TODO_CONTENT_BG_COLOR"
    [[ -n "$TODO_TASK_TEXT_COLOR" ]] && _TODO_INTERNAL_TASK_TEXT_COLOR="$TODO_TASK_TEXT_COLOR"
    [[ -n "$TODO_TITLE_COLOR" ]] && _TODO_INTERNAL_TITLE_COLOR="$TODO_TITLE_COLOR"
    [[ -n "$TODO_AFFIRMATION_COLOR" ]] && _TODO_INTERNAL_AFFIRMATION_COLOR="$TODO_AFFIRMATION_COLOR"
    [[ -n "$TODO_BULLET_COLOR" ]] && _TODO_INTERNAL_BULLET_COLOR="$TODO_BULLET_COLOR"
    [[ -n "$TODO_BOX_TOP_LEFT" ]] && _TODO_INTERNAL_BOX_TOP_LEFT="$TODO_BOX_TOP_LEFT"
    [[ -n "$TODO_BOX_TOP_RIGHT" ]] && _TODO_INTERNAL_BOX_TOP_RIGHT="$TODO_BOX_TOP_RIGHT"
    [[ -n "$TODO_BOX_BOTTOM_LEFT" ]] && _TODO_INTERNAL_BOX_BOTTOM_LEFT="$TODO_BOX_BOTTOM_LEFT"
    [[ -n "$TODO_BOX_BOTTOM_RIGHT" ]] && _TODO_INTERNAL_BOX_BOTTOM_RIGHT="$TODO_BOX_BOTTOM_RIGHT"
    [[ -n "$TODO_BOX_HORIZONTAL" ]] && _TODO_INTERNAL_BOX_HORIZONTAL="$TODO_BOX_HORIZONTAL"
    [[ -n "$TODO_BOX_VERTICAL" ]] && _TODO_INTERNAL_BOX_VERTICAL="$TODO_BOX_VERTICAL"
    
    # Update internal color array
    if [[ -n "$_TODO_INTERNAL_TASK_COLORS" ]]; then
        _TODO_INTERNAL_COLORS=(${(@s:,:)_TODO_INTERNAL_TASK_COLORS})
    fi
}

# Auto-initialize when module is loaded
__todo_config_module_init

# Convert any environment variables to internal format on load
_todo_convert_to_internal_vars