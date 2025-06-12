#!/usr/bin/env zsh
# Configuration management module for todo-reminder
# Handles presets, validation, export/import, and user data migration

# Guard against multiple loads
[[ -n "$_TODO_CONFIG_LOADED" ]] && return 0
typeset -gr _TODO_CONFIG_LOADED=1

# Private module variables (use local scope where possible)
typeset -g _TODO_CONFIG_DIR _TODO_USER_PRESETS_DIR _TODO_BUILTIN_PRESETS_DIR _TODO_DEFAULT_SAVE_FILE

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
    
    # Create isolated environment for validation
    (
        # Source the config file in subshell
        source "$file" 2>/dev/null || {
            echo "Syntax error in config file"
            return 1
        }
        
        # Run validation
        __todo_validate_config
    )
    
    return $?
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

# List preset names only (for arrays)
function todo_config_get_preset_names() {
    todo_config_find_presets | cut -d: -f1 | sort -u
}

# Apply a preset by name
function todo_config_apply_preset() {
    local preset_name="$1"
    local preset_file="$(__todo_find_preset_file "$preset_name")"
    
    if [[ ! -f "$preset_file" ]]; then
        echo "Error: Preset '$preset_name' not found" >&2
        echo "Available presets: $(todo_config_get_preset_names | tr '\n' ' ')" >&2
        return 1
    fi
    
    # Validate before applying
    if ! __todo_validate_config_file "$preset_file"; then
        echo "Error: Invalid preset configuration in $preset_file" >&2
        return 1
    fi
    
    # Clear preset description from previous load
    unset TODO_PRESET_DESC
    
    # Source the config file
    source "$preset_file"
    
    # Show what was applied
    echo "Applied preset: $preset_name"
    if [[ -n "$TODO_PRESET_DESC" ]]; then
        echo "  $TODO_PRESET_DESC"
    fi
    
    # Handle tinted-shell integration message
    if [[ "$preset_file" == *"_tinted.conf" ]]; then
        echo "🎨 Using theme-adaptive colors"
    elif command -v tinty >/dev/null 2>&1; then
        echo "💡 Tip: Use 'tinty apply [theme]' for theme integration"
    fi
    
    # Update color arrays
    TODO_COLORS=(${(@s:,:)TODO_TASK_COLORS})
    
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
    
    # Generate export content
    local export_content=""
    for var in "${vars_to_export[@]}"; do
        local value="${(P)var}"
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
    
    # Source the configuration
    source "$config_file"
    echo "Configuration imported from: $config_file"
    
    # Update color arrays
    TODO_COLORS=(${(@s:,:)TODO_TASK_COLORS})
    
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
        local preset_names=($(todo_config_get_preset_names))
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
        source "$preset_file"
        
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

# Auto-initialize when module is loaded
__todo_config_module_init