# Load configuration module
_TODO_INTERNAL_PLUGIN_DIR="${0:A:h}"
source "${0:A:h}/lib/config.zsh"

# Internal configuration variables - private to plugin, not user-configurable via environment
_TODO_INTERNAL_SAVE_FILE="${_TODO_INTERNAL_SAVE_FILE:-$HOME/.todo.save}"
_TODO_INTERNAL_AFFIRMATION_FILE="${_TODO_INTERNAL_AFFIRMATION_FILE:-${TMPDIR:-/tmp}/todo_affirmation}"

# Color mode configuration
_TODO_INTERNAL_COLOR_MODE="${_TODO_INTERNAL_COLOR_MODE:-auto}"                   # Color selection mode: "static", "dynamic", "auto"

# Available configuration presets (dynamically discovered)
_TODO_INTERNAL_AVAILABLE_PRESETS=($(_todo_config_get_preset_names))              # Internal use - all presets
_TODO_INTERNAL_USER_PRESETS=($(_todo_config_get_user_preset_names))               # User display - filtered base presets
_TODO_INTERNAL_PRESET_LIST="${(j:, :)_TODO_INTERNAL_USER_PRESETS}"                       # Used in help text

# Box width configuration (fraction of terminal width, with min/max limits)
_TODO_INTERNAL_BOX_WIDTH_FRACTION="${_TODO_INTERNAL_BOX_WIDTH_FRACTION:-0.5}"  # 50% by default
_TODO_INTERNAL_BOX_MIN_WIDTH="${_TODO_INTERNAL_BOX_MIN_WIDTH:-30}"            # Minimum 30 chars
_TODO_INTERNAL_BOX_MAX_WIDTH="${_TODO_INTERNAL_BOX_MAX_WIDTH:-80}"            # Maximum 80 chars

# Display configuration
_TODO_INTERNAL_TITLE="${_TODO_INTERNAL_TITLE:-REMEMBER}"                      # Box title
_TODO_INTERNAL_HEART_CHAR="${_TODO_INTERNAL_HEART_CHAR:-♥}"                   # Affirmation heart character
_TODO_INTERNAL_HEART_POSITION="${_TODO_INTERNAL_HEART_POSITION:-left}"        # Heart position: "left", "right", "both", "none"
_TODO_INTERNAL_BULLET_CHAR="${_TODO_INTERNAL_BULLET_CHAR:-▪}"                 # Task bullet character

# Show/hide state configuration
_TODO_INTERNAL_SHOW_AFFIRMATION="${_TODO_INTERNAL_SHOW_AFFIRMATION:-true}"    # Show affirmations: "true", "false"
_TODO_INTERNAL_SHOW_TODO_BOX="${_TODO_INTERNAL_SHOW_TODO_BOX:-true}"          # Show todo box: "true", "false"
_TODO_INTERNAL_SHOW_HINTS="${_TODO_INTERNAL_SHOW_HINTS:-true}"                # Show contextual hints: "true", "false"

# Padding/margin configuration (in characters)
_TODO_INTERNAL_PADDING_TOP="${_TODO_INTERNAL_PADDING_TOP:-0}"                 # Top padding/margin
_TODO_INTERNAL_PADDING_RIGHT="${_TODO_INTERNAL_PADDING_RIGHT:-4}"             # Right padding/margin
_TODO_INTERNAL_PADDING_BOTTOM="${_TODO_INTERNAL_PADDING_BOTTOM:-0}"           # Bottom padding/margin
_TODO_INTERNAL_PADDING_LEFT="${_TODO_INTERNAL_PADDING_LEFT:-0}"               # Left padding/margin

# Color configuration (256-color terminal codes)
_TODO_INTERNAL_TASK_COLORS="${_TODO_INTERNAL_TASK_COLORS:-167,71,136,110,139,73}"    # Task bullet colors (comma-separated)
_TODO_INTERNAL_BORDER_COLOR="${_TODO_INTERNAL_BORDER_COLOR:-240}"                     # Box border foreground color

_TODO_INTERNAL_BORDER_BG_COLOR="${_TODO_INTERNAL_BORDER_BG_COLOR:-235}"               # Box border background color
_TODO_INTERNAL_CONTENT_BG_COLOR="${_TODO_INTERNAL_CONTENT_BG_COLOR:-235}"             # Box content background color

_TODO_INTERNAL_TASK_TEXT_COLOR="${_TODO_INTERNAL_TASK_TEXT_COLOR:-240}"               # Task text color
_TODO_INTERNAL_TITLE_COLOR="${_TODO_INTERNAL_TITLE_COLOR:-250}"                       # Box title color
_TODO_INTERNAL_AFFIRMATION_COLOR="${_TODO_INTERNAL_AFFIRMATION_COLOR:-109}"           # Affirmation text color
_TODO_INTERNAL_BULLET_COLOR="${_TODO_INTERNAL_BULLET_COLOR:-39}"                      # Bullet color

# Box drawing characters configuration
_TODO_INTERNAL_BOX_TOP_LEFT="${_TODO_INTERNAL_BOX_TOP_LEFT:-┌}"                       # Top left corner
_TODO_INTERNAL_BOX_TOP_RIGHT="${_TODO_INTERNAL_BOX_TOP_RIGHT:-┐}"                     # Top right corner
_TODO_INTERNAL_BOX_BOTTOM_LEFT="${_TODO_INTERNAL_BOX_BOTTOM_LEFT:-└}"                 # Bottom left corner
_TODO_INTERNAL_BOX_BOTTOM_RIGHT="${_TODO_INTERNAL_BOX_BOTTOM_RIGHT:-┘}"               # Bottom right corner
_TODO_INTERNAL_BOX_HORIZONTAL="${_TODO_INTERNAL_BOX_HORIZONTAL:-─}"                   # Horizontal line
_TODO_INTERNAL_BOX_VERTICAL="${_TODO_INTERNAL_BOX_VERTICAL:-│}"                       # Vertical line

# Validate heart character display width (allows Unicode characters including emojis)
if [[ -z "$_TODO_INTERNAL_HEART_CHAR" ]] || [[ ${#_TODO_INTERNAL_HEART_CHAR} -gt 4 ]]; then
    echo "Error: _TODO_INTERNAL_HEART_CHAR must be a single character or emoji, got: '$_TODO_INTERNAL_HEART_CHAR'" >&2
    return 1
fi

# Validate heart position
if [[ "$_TODO_INTERNAL_HEART_POSITION" != "left" && "$_TODO_INTERNAL_HEART_POSITION" != "right" && "$_TODO_INTERNAL_HEART_POSITION" != "both" && "$_TODO_INTERNAL_HEART_POSITION" != "none" ]]; then
    echo "Error: _TODO_INTERNAL_HEART_POSITION must be 'left', 'right', 'both', or 'none', got: '$_TODO_INTERNAL_HEART_POSITION'" >&2
    return 1
fi

# Validate bullet character display width (allows Unicode characters including emojis)
if [[ -z "$_TODO_INTERNAL_BULLET_CHAR" ]] || [[ ${#_TODO_INTERNAL_BULLET_CHAR} -gt 4 ]]; then
    echo "Error: _TODO_INTERNAL_BULLET_CHAR must be a single character or emoji, got: '$_TODO_INTERNAL_BULLET_CHAR'" >&2
    return 1
fi

# Validate show/hide configurations
if [[ "$_TODO_INTERNAL_SHOW_AFFIRMATION" != "true" && "$_TODO_INTERNAL_SHOW_AFFIRMATION" != "false" ]]; then
    echo "Error: _TODO_INTERNAL_SHOW_AFFIRMATION must be 'true' or 'false', got: '$_TODO_INTERNAL_SHOW_AFFIRMATION'" >&2
    return 1
fi

if [[ "$_TODO_INTERNAL_SHOW_TODO_BOX" != "true" && "$_TODO_INTERNAL_SHOW_TODO_BOX" != "false" ]]; then
    echo "Error: _TODO_INTERNAL_SHOW_TODO_BOX must be 'true' or 'false', got: '$_TODO_INTERNAL_SHOW_TODO_BOX'" >&2
    return 1
fi

if [[ "$_TODO_INTERNAL_SHOW_HINTS" != "true" && "$_TODO_INTERNAL_SHOW_HINTS" != "false" ]]; then
    echo "Error: _TODO_INTERNAL_SHOW_HINTS must be 'true' or 'false', got: '$_TODO_INTERNAL_SHOW_HINTS'" >&2
    return 1
fi

# Validate color mode configuration
if [[ "$_TODO_INTERNAL_COLOR_MODE" != "static" && "$_TODO_INTERNAL_COLOR_MODE" != "dynamic" && "$_TODO_INTERNAL_COLOR_MODE" != "auto" ]]; then
    echo "Error: _TODO_INTERNAL_COLOR_MODE must be 'static', 'dynamic', or 'auto', got: '$_TODO_INTERNAL_COLOR_MODE'" >&2
    return 1
fi

# Validate padding configurations are numeric
for padding_var in _TODO_INTERNAL_PADDING_TOP _TODO_INTERNAL_PADDING_RIGHT _TODO_INTERNAL_PADDING_BOTTOM _TODO_INTERNAL_PADDING_LEFT; do
    local padding_value="${(P)padding_var}"
    if [[ ! "$padding_value" =~ ^[0-9]+$ ]]; then
        echo "Error: $padding_var must be a non-negative integer, got: '$padding_value'" >&2
        return 1
    fi
done

# Validate color configurations are numeric
for color_var in _TODO_INTERNAL_BORDER_COLOR _TODO_INTERNAL_BORDER_BG_COLOR _TODO_INTERNAL_CONTENT_BG_COLOR _TODO_INTERNAL_TASK_TEXT_COLOR _TODO_INTERNAL_TITLE_COLOR _TODO_INTERNAL_AFFIRMATION_COLOR _TODO_INTERNAL_BULLET_COLOR; do
    local color_value="${(P)color_var}"
    if [[ ! "$color_value" =~ ^[0-9]+$ ]] || [[ $color_value -gt 255 ]]; then
        echo "Error: $color_var must be a number between 0-255, got: '$color_value'" >&2
        return 1
    fi
done


# Validate and parse task colors
if [[ -z "$_TODO_INTERNAL_TASK_COLORS" ]] || [[ ! "$_TODO_INTERNAL_TASK_COLORS" =~ ^[0-9]+(,[0-9]+)*$ ]]; then
    echo "Error: _TODO_INTERNAL_TASK_COLORS must be comma-separated numbers (0-255), got: '$_TODO_INTERNAL_TASK_COLORS'" >&2
    return 1
fi

# Convert comma-separated string to array and validate range
IFS=',' read -A task_color_array <<< "$_TODO_INTERNAL_TASK_COLORS"
for color in "${task_color_array[@]}"; do
    if [[ $color -gt 255 ]]; then
        echo "Error: Task color values must be 0-255, got: '$color'" >&2
        return 1
    fi
done

# Validate box drawing characters (must be single characters)
for box_var in _TODO_INTERNAL_BOX_TOP_LEFT _TODO_INTERNAL_BOX_TOP_RIGHT _TODO_INTERNAL_BOX_BOTTOM_LEFT _TODO_INTERNAL_BOX_BOTTOM_RIGHT _TODO_INTERNAL_BOX_HORIZONTAL _TODO_INTERNAL_BOX_VERTICAL; do
    local box_char="${(P)box_var}"
    if [[ -z "$box_char" ]] || [[ ${#box_char} -gt 4 ]]; then
        echo "Error: $box_var must be a single character, got: '$box_char'" >&2
        return 1
    fi
done


# Initialize color palette from configuration
typeset -a _TODO_INTERNAL_COLORS
_TODO_INTERNAL_COLORS=(${(@s:,:)_TODO_INTERNAL_TASK_COLORS})


# Check for first run and show welcome message
typeset -g _TODO_INTERNAL_FIRST_RUN_FILE="${_TODO_INTERNAL_FIRST_RUN_FILE:-$HOME/.todo_first_run}"
if [[ ! -f "$_TODO_INTERNAL_FIRST_RUN_FILE" ]]; then
    # Show welcome message on first run
    function show_welcome_message() {
        local bold=$'\e[1m'
        local reset=$'\e[0m'
        local blue=$'\e[38;5;39m'
        local green=$'\e[38;5;46m'
        local cyan=$'\e[38;5;51m'
        local gray=$'\e[38;5;244m'
        
        echo
        echo "${bold}${blue}┌─ Welcome to Todo Reminder! ─────────────────────────┐${reset}"
        echo "${bold}${blue}│${reset} ${green}✨ Get started:${reset} ${cyan}todo \"Your first task\"${reset}              ${bold}${blue}│${reset}"
        echo "${bold}${blue}│${reset} ${green}📚 Quick help:${reset} ${cyan}todo help${reset}                           ${bold}${blue}│${reset}"
        echo "${bold}${blue}│${reset} ${green}⚙️  Customize:${reset} ${cyan}todo setup${reset}                          ${bold}${blue}│${reset}"
        echo "${bold}${blue}└─────────────────────────────────────────────────────┘${reset}"
        echo "${gray}💡 Your tasks will appear above the prompt automatically${reset}"
        echo
        
        # Mark first run as complete and remove this hook
        touch "$_TODO_INTERNAL_FIRST_RUN_FILE"
        add-zsh-hook -d precmd show_welcome_message
        unfunction show_welcome_message
    }
    
    # Schedule welcome message to show after current command completes
    if ! (( ${+functions[add-zsh-hook]} )); then
        autoload -U add-zsh-hook
    fi
    add-zsh-hook precmd show_welcome_message
fi


# Allow to use colors (ensure autoload first for deferred loading)
autoload -U colors
colors
# Use a more unique separator to avoid conflicts with task content
typeset -T -x -g TODO_TASKS todo_tasks $'\x00'  # Use null byte separator
typeset -T -x -g TODO_TASKS_COLORS todo_tasks_colors $'\x00'
typeset -i -x -g todo_color_index

# File change detection and caching for performance and multi-terminal coordination
# Use underscore prefix to indicate internal variables
typeset -g _TODO_INTERNAL_FILE_MTIME=0
typeset -g _TODO_INTERNAL_CACHED_TASKS=""
typeset -g _TODO_INTERNAL_CACHED_COLORS=""
typeset -i -g _TODO_INTERNAL_CACHED_COLOR_INDEX=1

# Load tasks and colors from single save file with caching for performance
# File format: tasks on line 1, colors on line 2, color_index on line 3
function load_tasks() {
    local current_mtime=0
    
    # Get file modification time (cross-platform)
    if [[ -f "$_TODO_INTERNAL_SAVE_FILE" ]]; then
        # Try different stat formats for cross-platform compatibility
        if stat -f %m "$_TODO_INTERNAL_SAVE_FILE" >/dev/null 2>&1; then
            # macOS/BSD stat
            current_mtime=$(stat -f %m "$_TODO_INTERNAL_SAVE_FILE" 2>/dev/null)
        elif stat -c %Y "$_TODO_INTERNAL_SAVE_FILE" >/dev/null 2>&1; then
            # GNU stat
            current_mtime=$(stat -c %Y "$_TODO_INTERNAL_SAVE_FILE" 2>/dev/null)
        else
            # Fallback: use file size + random as a poor approximation
            current_mtime=$(wc -c < "$_TODO_INTERNAL_SAVE_FILE" 2>/dev/null || echo 0)
        fi
        # Ensure we have a numeric value
        current_mtime="${current_mtime:-0}"
        # Clean any non-numeric characters
        current_mtime="${current_mtime//[^0-9]/}"
        current_mtime="${current_mtime:-0}"
    fi
    
    # Only reload if file changed or we have no cached data (ensure numeric comparison)
    if [[ "${current_mtime:-0}" -ne "${_TODO_INTERNAL_FILE_MTIME:-0}" ]] || [[ -z "$_TODO_INTERNAL_CACHED_TASKS" && -z "$_TODO_INTERNAL_CACHED_COLORS" ]]; then
        _TODO_INTERNAL_FILE_MTIME=$current_mtime
        
        if [[ -e "$_TODO_INTERNAL_SAVE_FILE" ]]; then
            if ! local file_content="$(cat "$_TODO_INTERNAL_SAVE_FILE" 2>/dev/null)"; then
                echo "Warning: Could not read todo file $_TODO_INTERNAL_SAVE_FILE" >&2
                todo_tasks=()
                todo_tasks_colors=()
                todo_color_index=1
                # Clear cache on error
                _TODO_INTERNAL_CACHED_TASKS=""
                _TODO_INTERNAL_CACHED_COLORS=""
                _TODO_INTERNAL_CACHED_COLOR_INDEX=1
                return 1
            fi

            # Validate file format (should have 3 lines for old format or 4 lines for new format with config)
            local line_count=$(echo "$file_content" | wc -l)
            if [[ $line_count -ne 3 && $line_count -ne 4 ]]; then
                echo "Warning: Invalid todo file format (expected 3 or 4 lines, got $line_count), creating backup and resetting" >&2
                if cp "$_TODO_INTERNAL_SAVE_FILE" "$_TODO_INTERNAL_SAVE_FILE.backup.$(date +%s)" 2>/dev/null; then
                    echo "Backup created: $_TODO_INTERNAL_SAVE_FILE.backup.$(date +%s)" >&2
                fi
                # Reset to empty state
                todo_tasks=()
                todo_tasks_colors=()
                todo_color_index=1
                _TODO_INTERNAL_CACHED_TASKS=""
                _TODO_INTERNAL_CACHED_COLORS=""
                _TODO_INTERNAL_CACHED_COLOR_INDEX=1
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
                _TODO_INTERNAL_CACHED_TASKS=""
                _TODO_INTERNAL_CACHED_COLORS=""
                _TODO_INTERNAL_CACHED_COLOR_INDEX=1
                return
            fi

            # Validate color index is numeric
            if [[ "$index_line" =~ ^[0-9]+$ ]]; then
                todo_color_index="$index_line"
            else
                todo_color_index=1
            fi

            # Count tasks and colors to ensure consistency
            local task_count=$(echo "$TODO_TASKS" | tr '\000' '\n' | wc -l)
            local color_count=0
            if [[ -n "$TODO_TASKS_COLORS" ]]; then
                color_count=$(echo "$TODO_TASKS_COLORS" | tr '\000' '\n' | grep -c .)
            fi

            # If color count doesn't match task count, regenerate colors
            if [[ $color_count -ne $task_count ]] || [[ -z "$TODO_TASKS_COLORS" ]]; then
                regenerate_colors_for_existing_tasks
            fi
            
            # Load configuration if present (4-line format)
            if [[ $line_count -eq 4 ]]; then
                local config_line="${lines[4]:-}"
                _todo_load_config_from_line "$config_line"
            fi
            
            # Update cache
            _TODO_INTERNAL_CACHED_TASKS="$TODO_TASKS"
            _TODO_INTERNAL_CACHED_COLORS="$TODO_TASKS_COLORS"
            _TODO_INTERNAL_CACHED_COLOR_INDEX="$todo_color_index"
        else
            # No file exists
            todo_tasks=()
            todo_tasks_colors=()
            todo_color_index=1
            _TODO_INTERNAL_CACHED_TASKS=""
            _TODO_INTERNAL_CACHED_COLORS=""
            _TODO_INTERNAL_CACHED_COLOR_INDEX=1
        fi
    else
        # Use cached data - no file I/O needed!
        TODO_TASKS="$_TODO_INTERNAL_CACHED_TASKS"
        TODO_TASKS_COLORS="$_TODO_INTERNAL_CACHED_COLORS"
        todo_color_index="$_TODO_INTERNAL_CACHED_COLOR_INDEX"
    fi
}

# Regenerate colors for existing tasks when data is inconsistent
function regenerate_colors_for_existing_tasks() {
    local task_count=$(echo "$TODO_TASKS" | tr '\000' '\n' | wc -l)
    local new_colors=()
    local color_index=1

    for (( i = 1; i <= task_count; i++ )); do
        local color_code=$'\e[38;5;'${_TODO_INTERNAL_COLORS[color_index]}$'m'
        new_colors+=("$color_code")
        (( color_index = (color_index % ${#_TODO_INTERNAL_COLORS}) + 1 ))
    done

    # Update in-memory data
    TODO_TASKS_COLORS="$(IFS=$'\000'; echo "${new_colors[*]}")"
    todo_color_index="$color_index"

    # Save to file
    todo_save
}

# Calculate optimal box width based on terminal size and configuration
function calculate_box_width() {
    # Convert fraction to percentage for integer math (0.5 -> 50)
    local percentage=$((${_TODO_INTERNAL_BOX_WIDTH_FRACTION} * 100))
    local desired_width=$((COLUMNS * percentage / 100))
    local width=$desired_width

    # Apply minimum constraint
    if [[ $width -lt $_TODO_INTERNAL_BOX_MIN_WIDTH ]]; then
        width=$_TODO_INTERNAL_BOX_MIN_WIDTH
    fi

    # Apply maximum constraint
    if [[ $width -gt $_TODO_INTERNAL_BOX_MAX_WIDTH ]]; then
        width=$_TODO_INTERNAL_BOX_MAX_WIDTH
    fi

    # Never exceed terminal width
    if [[ $width -gt $COLUMNS ]]; then
        width=$COLUMNS
    fi

    echo $width
}

# Format affirmation text with configurable heart position
function format_affirmation() {
    local text="$1"
    case "$_TODO_INTERNAL_HEART_POSITION" in
        "left")
            echo "${_TODO_INTERNAL_HEART_CHAR} ${text}"
            ;;
        "right")
            echo "${text} ${_TODO_INTERNAL_HEART_CHAR}"
            ;;
        "both")
            echo "${_TODO_INTERNAL_HEART_CHAR} ${text} ${_TODO_INTERNAL_HEART_CHAR}"
            ;;
        "none")
            echo "${text}"
            ;;
        *)
            # Fallback to left if somehow invalid
            echo "${_TODO_INTERNAL_HEART_CHAR} ${text}"
            ;;
    esac
}

# Determine whether to use tinted (theme-adaptive) preset variants
function _should_use_tinted_preset() {
    case "$_TODO_INTERNAL_COLOR_MODE" in
        "static") 
            return 1  # Never use tinted presets
            ;;
        "dynamic") 
            return 0  # Always use tinted presets
            ;;
        "auto")
            # Auto-detect: use tinted if tinted-shell is active or tinty is available
            [[ "$TINTED_SHELL_ENABLE_BASE16_VARS" == "1" ]] && return 0
            command -v tinty >/dev/null 2>&1 && return 0
            return 1  # Default to static if no tinted tools detected
            ;;
    esac
}

autoload -U add-zsh-hook
add-zsh-hook precmd todo_display


# Main todo command dispatcher - pure subcommand interface
function todo() {
    case "${1:-help}" in
        help)
            _todo_help_command "${@:2}"
            ;;
        done)
            _todo_done_command "${@:2}"
            ;;
        hide)
            _todo_hide_command
            ;;
        show)
            _todo_show_command
            ;;
        toggle)
            _todo_toggle_command "${@:2}"
            ;;
        setup)
            _todo_setup_command
            ;;
        config)
            _todo_config_command "${@:2}"
            ;;
        *)
            # Default: add task
            _todo_add_command "$@"
            ;;
    esac
}

# Internal command implementations
function _todo_add_command() {
    if [[ $# -eq 0 ]]; then
        _todo_help_command
        return 1
    fi
    
    # Add a new task with automatic color assignment and validation
    # Source: http://stackoverflow.com/a/8997314/1298019
    local task=$(echo -E "$@" | tr '\n' '\000' | sed 's:\x00\x00.*:\n:g' | tr '\000' '\n')
    
    # Task length validation for security and performance
    if [[ ${#task} -gt 500 ]]; then
        echo "⚠️  Task too long (max 500 characters), truncating..." >&2
        task="${task:0:497}..."
    fi
    
    # Basic input sanitization - remove control characters
    task="${task//[$'\x00'-$'\x1f']/}"
    
    local color=$'\e[38;5;'${_TODO_INTERNAL_COLORS[${todo_color_index}]}$'m'

    load_tasks
    todo_tasks+="$task"
    todo_tasks_colors+="$color"
    (( todo_color_index %= ${#_TODO_INTERNAL_COLORS} ))
    (( todo_color_index += 1 ))
    todo_save
    
    # Success feedback for users
    echo "✅ Task added: \"$task\""
    if [[ ${#todo_tasks} -eq 1 ]]; then
        echo "💡 Your tasks appear above the prompt. Remove with: todo done \"$(echo "$task" | cut -c1-10)\""
    fi
}

function _todo_done_command() {
    local pattern="$1"

    if [[ -z "$pattern" ]]; then
        echo "Usage: todo done <pattern>"
        echo "Example: todo done \"Buy groceries\""
        echo "💡 Use tab completion to see available tasks"
        load_tasks
        if [[ ${#todo_tasks} -gt 0 ]]; then
            echo "Current tasks:"
            local i=1
            for task in "${todo_tasks[@]}"; do
                echo "  $i. $task"
                ((i++))
            done
        fi
        return 1
    fi

    load_tasks
    local index=${(M)todo_tasks[(i)${pattern}*]}

    if [[ $index -le ${#todo_tasks} ]]; then
        local removed_task="${todo_tasks[index]}"
        todo_tasks[index]=()
        todo_tasks_colors[index]=()
        todo_save
        
        # Success feedback
        echo "✅ Task completed: \"$removed_task\""
        if [[ ${#todo_tasks} -eq 0 ]]; then
            echo "🎉 All tasks done! Add new ones with: todo \"task description\""
        fi
    else
        echo "❌ No task found matching: $pattern"
        if [[ ${#todo_tasks} -gt 0 ]]; then
            echo "💡 Available tasks:"
            local i=1
            for task in "${todo_tasks[@]}"; do
                echo "   $i. $task"
                ((i++))
            done
            echo "💡 Try: todo done \"$(echo "${todo_tasks[1]}" | cut -c1-10)\""
        else
            echo "💡 No tasks exist. Add one with: todo \"task description\""
        fi
        return 1
    fi
}

function _todo_hide_command() {
    todo_toggle_all hide
}

function _todo_show_command() {
    todo_toggle_all show
}

function _todo_toggle_command() {
    case "${1:-}" in
        affirmation)
            todo_toggle_affirmation "${@:2}"
            ;;
        box)
            todo_toggle_box "${@:2}"
            ;;
        "")
            todo_toggle_all
            ;;
        *)
            echo "Usage: todo toggle [affirmation|box]"
            echo "  todo toggle           # Toggle everything"
            echo "  todo toggle affirmation # Toggle affirmations only"
            echo "  todo toggle box       # Toggle todo box only"
            return 1
            ;;
    esac
}

function _todo_setup_command() {
    todo_config_wizard
}

function _todo_config_command() {
    case "${1:-}" in
        get)
            if ! autoload_todo_module "wizard"; then
                echo "Error: Wizard module required for get command" >&2
                return 1
            fi
            todo_config_get "${@:2}"
            ;;
        list|show)
            if ! autoload_todo_module "wizard"; then
                echo "Error: Wizard module required for list command" >&2
                return 1
            fi
            todo_config_list "${@:2}"
            ;;
        export)
            # Parse options for export
            local output_file=""
            local colors_only="false"
            local args=("${@:2}")
            
            for arg in "${args[@]}"; do
                case "$arg" in
                    --colors-only)
                        colors_only="true"
                        ;;
                    -*)
                        echo "Unknown option: $arg" >&2
                        return 1
                        ;;
                    *)
                        output_file="$arg"
                        ;;
                esac
            done
            
            todo_config_export_config "$output_file" "$colors_only"
            ;;
        import)
            if [[ -z "${2:-}" ]]; then
                echo "Error: Import requires a config file" >&2
                return 1
            fi
            todo_config_import_config "$2"
            ;;
        set)
            todo_config_set "${@:2}"
            ;;
        reset)
            todo_config_reset "${@:2}"
            ;;
        preset)
            todo_config_preset "${@:2}"
            ;;
        save-preset)
            if [[ -z "${2:-}" ]]; then
                echo "Error: save-preset requires a preset name" >&2
                return 1
            fi
            local preset_name="$2"
            local description="${3:-}"
            todo_config_save_user_preset "$preset_name" "$description"
            ;;
        preview)
            todo_config_preview "${@:2}"
            ;;
        "")
            echo "Usage: todo config <action> [options]"
            echo "Actions:"
            echo "  get <setting>         # Get current value of setting"
            echo "  list                  # List all current settings"
            echo "  set <key> <value>     # Set configuration value"
            echo "  reset                 # Reset to defaults"
            echo "  export [file]         # Export configuration"
            echo "  import <file>         # Import configuration"
            echo "  preset <name>         # Apply preset (${_TODO_INTERNAL_PRESET_LIST})"
            echo "  save-preset <name>    # Save current settings as preset"
            echo "  preview [preset]      # Preview color swatches for presets"
            return 1
            ;;
        *)
            echo "Unknown config action: $1"
            echo "Run 'todo config' for usage help"
            return 1
            ;;
    esac
}

function _todo_help_command() {
    case "${1:-}" in
        --full|--more|-f|-m)
            todo_help_full
            ;;
        --colors)
            todo_colors
            ;;
        --config)
            _todo_show_config_help
            ;;
        "")
            _todo_show_basic_help
            ;;
        *)
            echo "Unknown help option: $1"
            echo "Available help options: --full, --colors, --config"
            return 1
            ;;
    esac
}

function _todo_show_basic_help() {
    local bold=$'\e[1m'
    local reset=$'\e[0m'
    local blue=$'\e[38;5;39m'
    local green=$'\e[38;5;46m'
    local cyan=$'\e[38;5;51m'
    local gray=$'\e[38;5;244m'
    
    echo "${bold}${blue}📝 Todo - Simple Task Management${reset}"
    echo "${gray}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}"
    echo
    echo "${green}Core Commands:${reset}"
    echo "  ${cyan}todo <task>${reset}        Add a new task"
    echo "  ${cyan}todo done <task>${reset}   Complete a task"
    echo "  ${cyan}todo setup${reset}         Interactive configuration"
    echo "  ${cyan}todo help${reset}          Show this help"
    echo
    echo "${green}Examples:${reset}"
    echo "  ${gray}todo \"Buy groceries\"${reset}"
    echo "  ${gray}todo done \"Buy\"${reset}"
    echo
    echo "${green}More Commands:${reset}"
    echo "  ${cyan}todo help --full${reset}     All commands and options"
    echo "  ${cyan}todo help --colors${reset}   Color reference"
    echo "  ${cyan}todo help --config${reset}   Configuration help"
    echo
    echo "${gray}💡 Tasks appear above your prompt automatically${reset}"
}

function _todo_show_config_help() {
    local bold=$'\e[1m'
    local reset=$'\e[0m'
    local blue=$'\e[38;5;39m'
    local green=$'\e[38;5;46m'
    local cyan=$'\e[38;5;51m'
    local gray=$'\e[38;5;244m'
    
    echo "${bold}${blue}⚙️ Configuration Help${reset}"
    echo "${gray}━━━━━━━━━━━━━━━━━━━━━━━━${reset}"
    echo
    echo "${green}Quick Setup:${reset}"
    echo "  ${cyan}todo setup${reset}                Interactive wizard"
    echo
    echo "${green}Advanced Configuration:${reset}"
    echo "  ${cyan}todo config export${reset}        Export settings to file"
    echo "  ${cyan}todo config import <file>${reset} Import settings from file"
    echo "  ${cyan}todo config preset <name>${reset} Apply built-in preset"
    echo "  ${cyan}todo config reset${reset}         Reset to defaults"
    echo
    echo "${green}Available Presets:${reset}"
    echo "  ${gray}${_TODO_INTERNAL_PRESET_LIST}${reset}"
    echo
    echo "${green}Quick Configuration Commands:${reset}"
    echo "  ${cyan}todo config get title${reset}             Get current box title"
    echo "  ${cyan}todo config set title \"MY TASKS\"${reset}   Set custom box title"
    echo "  ${cyan}todo config get colors${reset}            Get current task colors"
    echo "  ${cyan}todo config set colors \"196,46,226\"${reset} Set custom task colors"
    echo "  ${cyan}todo config set heart-char \"💖\"${reset}    Set custom heart character"
    echo "  ${cyan}todo config list${reset}                  Show all current settings"
    echo
    echo "${gray}💡 See ${cyan}todo help --full${gray} for complete documentation${reset}"
}

# Remove a completed task by pattern matching

# ============================================================================
# Tab Completion System
# ============================================================================

# Tab completion for the new pure subcommand interface
function _todo_completion() {
    local context state line
    
    case $CURRENT in
        1) # Completing 'todo' itself - only show 'todo'
            compadd 'todo'
            ;;
        2) # First argument after 'todo' (todo <TAB>)
            local -a commands=(
                '...:Type task description to add new task'
                'done:Complete a task'
                'hide:Hide todo display'
                'show:Show todo display'
                'toggle:Toggle display components'
                'setup:Interactive configuration'
                'config:Advanced configuration'
                'help:Show help'
            )
            _describe 'todo commands' commands
            ;;
        3) # Second argument - context specific completion
            case ${words[2]} in
                done)
                    # Show current tasks for completion
                    load_tasks
                    if [[ ${#todo_tasks} -gt 0 ]]; then
                        compadd "${todo_tasks[@]}"
                    else
                        _message 'no tasks to complete'
                    fi
                    ;;
                toggle)
                    local -a toggle_options=(
                        'affirmation:Toggle affirmation display'
                        'box:Toggle todo box display'
                    )
                    _describe 'toggle options' toggle_options
                    ;;
                config)
                    local -a config_commands=(
                        'export:Export configuration to file'
                        'import:Import configuration from file'
                        'set:Set configuration value'
                        'reset:Reset to defaults'
                        'preset:Apply preset'
                        'save-preset:Save current as preset'
                        'preview:Preview color swatches'
                    )
                    _describe 'config commands' config_commands
                    ;;
                help)
                    local -a help_options=(
                        '--full:Show comprehensive help'
                        '--more:Show comprehensive help'
                        '--colors:Show color reference'
                        '--config:Show configuration help'
                    )
                    _describe 'help options' help_options
                    ;;
                *)
                    _message 'task description'
                    ;;
            esac
            ;;
        4) # Third argument - deeper context completion
            case "${words[2]} ${words[3]}" in
                "config export")
                    _files
                    ;;
                "config import")
                    _files
                    ;;
                "config preset")
                    local -a presets=('subtle' 'balanced' 'vibrant' 'loud')
                    _describe 'presets' presets
                    ;;
                "config set")
                    local -a settings=(
                        'color-mode:Set color selection mode (static|dynamic|auto)'
                        'title:Set box title'
                        'heart-char:Set affirmation heart character'
                        'heart-position:Set heart position (left|right|both|none)'
                        'bullet-char:Set task bullet character'
                        'colors:Set task colors (comma-separated)'
                        'border-color:Set border color'
                        'text-color:Set text color'
                        'padding-left:Set left padding'
                        'box-width:Set box width fraction'
                    )
                    _describe 'settings' settings
                    ;;
                "config preview")
                    local -a presets=('all' 'subtle' 'balanced' 'vibrant' 'loud')
                    _describe 'presets' presets
                    ;;
            esac
            ;;
    esac
}

# Enable tab completion
if command -v compdef >/dev/null 2>&1; then
    # Load completion functions
    autoload -U _describe _message _files
    
    # Register completion for main todo command only
    compdef _todo_completion todo
    
    # Prevent zsh from offering all todo_* functions when completing todo<TAB>
    # This sets up a style that ignores all internal functions for command completion
    zstyle ':completion:*:*:*:*:functions' ignored-patterns \
        'todo_*' '_todo_*' 'autoload_todo_module' 'calculate_box_width' \
        'draw_todo_box' 'fetch_affirmation_async' 'format_affirmation' \
        'format_todo_line' 'load_tasks' 'regenerate_colors_for_existing_tasks' \
        'show_*' 'wrap_todo_text'
        
    # Also ignore internal variables
    zstyle ':completion:*:*:*:*:parameters' ignored-patterns \
        'todo_color_index' 'todo_tasks' 'todo_tasks_colors' \
        'TODO_*' '_TODO_*'
fi

# Wrap text to fit within specified width, handling bullet and text colors separately
# Args: text, max_width, bullet_color, is_title
# Returns: formatted lines with proper bullet prefixes and indentation
function wrap_todo_text() {
    local text="$1"
    local max_width="$2"
    local bullet_color="$3"
    local is_title="$4"
    local gray_color=$'\e[38;5;'${_TODO_INTERNAL_TASK_TEXT_COLOR}$'m'
    local title_color=$'\e[38;5;'${_TODO_INTERNAL_TITLE_COLOR}$'m'

    # Check if this is a title (REMEMBER is a special case)
    if [[ "$is_title" == "true" ]]; then
        # This is a title - no prefix, use bullet color for title
        echo "${title_color}${text}${gray_color}"
        return
    fi

    # For regular tasks, we need to handle bullet and text separately
    # Use the original task-specific bullet color for visual distinction
    local bullet="${bullet_color}${_TODO_INTERNAL_BULLET_CHAR}${gray_color}"

    # Account for bullet display width and space
    local remaining_width=$((max_width - ${(m)#_TODO_INTERNAL_BULLET_CHAR} - 1))

    # Simple word wrapping for the text part only
    local words=(${=text})  # Split into words
    local lines=()
    local current_line=""

    for word in "${words[@]}"; do
        if [[ -z "$current_line" ]]; then
            current_line="$word"
        elif [[ $((${#current_line} + ${#word} + 1)) -le $remaining_width ]]; then
            current_line="$current_line $word"
        else
            lines+=("$current_line")
            current_line="$word"
        fi
    done

    if [[ -n "$current_line" ]]; then
        lines+=("$current_line")
    fi

    # Output first line with bullet, subsequent lines with spacing
    for (( i = 1; i <= ${#lines}; i++ )); do
        if [[ $i -eq 1 ]]; then
            echo "${bullet} ${lines[i]}"
        else
            echo "  ${lines[i]}"  # Indent continuation lines
        fi
    done
}

# Create a line with todo box on right and affirmation on left
function format_todo_line() {
    local left_content="$1"
    local right_content="$2"
    local right_color="$3"

    local box_width=$(calculate_box_width)
    local effective_columns=$((COLUMNS - _TODO_INTERNAL_PADDING_LEFT - _TODO_INTERNAL_PADDING_RIGHT))
    local left_width=$((effective_columns - box_width))
    local affirmation_color=$'\e[38;5;'${_TODO_INTERNAL_AFFIRMATION_COLOR}$'m'

    # Ensure left_width is positive
    if [[ $left_width -lt 10 ]]; then
        left_width=10
    fi

    # Add left padding
    printf "%*s" $_TODO_INTERNAL_PADDING_LEFT ""

    # Display left content (affirmation) at start of line if enabled
    if [[ "$_TODO_INTERNAL_SHOW_AFFIRMATION" == "true" && -n "$left_content" ]]; then
        printf "${affirmation_color}%s$fg[default]" "$left_content"
        # Calculate actual display width (without color codes) for proper spacing
        local clean_content="$(echo "$left_content" | sed 's/\x1b\[[0-9;]*m//g')"
        local content_length=${(m)#clean_content}
        local padding_needed=$((left_width - content_length))
        if [[ $padding_needed -gt 0 ]]; then
            printf "%*s" $padding_needed ""
        fi
    else
        # No affirmation or affirmation disabled, just add spacing for box alignment
        printf "%*s" $left_width ""
    fi

    # Print right content with box formatting
    if [[ -n "$right_content" ]]; then
        printf "${right_color}%s$fg[default]" "$right_content"
    fi

    # Add right padding (note: this might cause line wrapping issues on narrow terminals)
    if [[ $_TODO_INTERNAL_PADDING_RIGHT -gt 0 ]]; then
        printf "%*s" $_TODO_INTERNAL_PADDING_RIGHT ""
    fi

    echo
}

# Draw todo box on right side of terminal with configurable width
function draw_todo_box() {
    setopt LOCAL_OPTIONS
    unsetopt XTRACE
    local box_width=$(calculate_box_width)
    local content_width=$((box_width - 4))  # 2 for borders, 2 for padding
    local border_fg_color=$'\e[38;5;'${_TODO_INTERNAL_BORDER_COLOR}$'m'
    local border_bg_color=$'\e[48;5;'${_TODO_INTERNAL_BORDER_BG_COLOR}$'m'
    local content_bg_color=$'\e[48;5;'${_TODO_INTERNAL_CONTENT_BG_COLOR}$'m'
    local reset_bg=$'\e[49m'

    if [[ ${#todo_tasks} -eq 0 ]]; then
        return
    fi

    # Read cached affirmation if available, otherwise use fallback
    local affirm_text
    if [[ -f "$_TODO_INTERNAL_AFFIRMATION_FILE" && -s "$_TODO_INTERNAL_AFFIRMATION_FILE" ]]; then
        local cached_affirm="$(cat "$_TODO_INTERNAL_AFFIRMATION_FILE" 2>/dev/null)"
        if [[ -n "$cached_affirm" ]]; then
            affirm_text="$(format_affirmation "$cached_affirm")"
        else
            affirm_text="$(format_affirmation "Keep going!")"
        fi
    else
        affirm_text="$(format_affirmation "Keep going!")"
    fi

    # Start background affirmation fetch (safe async execution)
    (fetch_affirmation_async &) 2>/dev/null

    local effective_columns=$((COLUMNS - _TODO_INTERNAL_PADDING_LEFT - _TODO_INTERNAL_PADDING_RIGHT))
    local left_width=$((effective_columns - box_width))

    # Truncate affirmation if too long (preserve formatting and add ellipsis)
    local clean_affirm_text="$(echo "$affirm_text" | sed 's/\x1b\[[0-9;]*m//g')"
    local affirm_display_width=${(m)#clean_affirm_text}
    if [[ $affirm_display_width -gt $left_width ]]; then
        local max_affirm_len=$((left_width - 3))  # Reserve space for "..."

        # Calculate space needed for heart character
        local heart_width=${(m)#_TODO_INTERNAL_HEART_CHAR}

        case "$_TODO_INTERNAL_HEART_POSITION" in
            "left"|"right")
                max_affirm_len=$((max_affirm_len - heart_width - 1))  # Space for heart + space
                ;;
            "both")
                max_affirm_len=$((max_affirm_len - (heart_width + 1) * 2))  # Space for heart+space on both sides
                ;;
            "none")
                # No additional space needed
                ;;
        esac

        # Extract just the core text and truncate, then reformat
        local core_text
        case "$_TODO_INTERNAL_HEART_POSITION" in
            "left")
                core_text="${affirm_text#${_TODO_INTERNAL_HEART_CHAR} }"
                ;;
            "right")
                core_text="${affirm_text% ${_TODO_INTERNAL_HEART_CHAR}}"
                ;;
            "both")
                core_text="${affirm_text#${_TODO_INTERNAL_HEART_CHAR} }"
                core_text="${core_text% ${_TODO_INTERNAL_HEART_CHAR}}"
                ;;
            "none")
                core_text="$affirm_text"
                ;;
        esac

        # Truncate core text and reformat with hearts (ensure non-negative length)
        if [[ $max_affirm_len -gt 0 ]]; then
            local truncated_text="${core_text:0:$max_affirm_len}..."
            affirm_text="$(format_affirmation "$truncated_text")"
        else
            # If no space for text, just show heart(s) if configured
            affirm_text="$(format_affirmation "")"
        fi
    fi

    # Collect all wrapped lines with colors
    local -a all_lines

    # Add title first
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            all_lines+=("$line")
        fi
    done <<< "$(wrap_todo_text "$_TODO_INTERNAL_TITLE" "$content_width" "" "true")"

    # Add regular tasks
    for (( i = 1; i <= ${#todo_tasks}; i++ )); do
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                all_lines+=("$line")
            fi
        done <<< "$(wrap_todo_text "${todo_tasks[i]}" "$content_width" "${todo_tasks_colors[i]}" "false")"
    done

    # Calculate middle line for affirmation
    local middle_line=$((${#all_lines} / 2 + 1))

    # Top border (low contrast) - ensure correct width
    local border_chars=$((box_width - 2))
    local horizontal_line="$(printf "${_TODO_INTERNAL_BOX_HORIZONTAL}%.0s" $(seq 1 $border_chars))"
    local top_border="${_TODO_INTERNAL_BOX_TOP_LEFT}${horizontal_line}${_TODO_INTERNAL_BOX_TOP_RIGHT}"
    format_todo_line "" "${border_fg_color}${border_bg_color}$top_border${reset_bg}" ""

    # Content lines
    for (( i = 1; i <= ${#all_lines}; i++ )); do
        # Strip color codes and calculate display width for proper box alignment
        local clean_line="$(echo "${all_lines[i]}" | sed 's/\x1b\[[0-9;]*m//g')"
        local line_display_width=${(m)#clean_line}
        local padding_needed=$((content_width - line_display_width))
        local padding="$(printf '%*s' $padding_needed '')"
        local content_line="${all_lines[i]}${border_fg_color}${padding}"
        local left_border="${border_fg_color}${border_bg_color}${_TODO_INTERNAL_BOX_VERTICAL}${reset_bg}"
        local right_border="${border_fg_color}${border_bg_color}${_TODO_INTERNAL_BOX_VERTICAL}${reset_bg}"
        local content_space="${content_bg_color} ${content_line} ${reset_bg}"
        local box_line="${left_border}${content_space}${right_border}$fg[default]"
        local left_text=""

        # Show placeholder affirmation on middle line
        if [[ $i -eq $middle_line ]]; then
            left_text="$affirm_text"
        fi

        format_todo_line "$left_text" "$box_line" ""
    done

    # Bottom border (low contrast) - ensure correct width
    local bottom_border="${_TODO_INTERNAL_BOX_BOTTOM_LEFT}${horizontal_line}${_TODO_INTERNAL_BOX_BOTTOM_RIGHT}"
    format_todo_line "" "${border_fg_color}${border_bg_color}$bottom_border${reset_bg}" ""
}

# Fetch new affirmation in background (requires curl and jq) with security improvements
function fetch_affirmation_async() {
    # Check for required dependencies
    if ! command -v curl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
        return 1
    fi

    local new_affirm
    # Add timeouts, SSL verification, and content validation for security
    new_affirm="$(timeout 10 curl -s --max-time 5 --connect-timeout 3 --fail \
        "https://www.affirmations.dev/" 2>/dev/null | \
        timeout 5 jq --raw-output '.affirmation' 2>/dev/null)"

    # Validate content: non-empty, not null, reasonable length, no suspicious characters
    if [[ -n "$new_affirm" && "$new_affirm" != "null" && ${#new_affirm} -lt 200 && ${#new_affirm} -gt 10 ]]; then
        # Additional security: check for potential script injection patterns
        if [[ ! "$new_affirm" =~ [\<\>\;\|\&\$\`] ]]; then
            echo "$new_affirm" > "$_TODO_INTERNAL_AFFIRMATION_FILE"
        fi
    fi
}

# Display todo box with tasks (called before each prompt)
function todo_display() {
    # Skip display if todo box is hidden
    if [[ "$_TODO_INTERNAL_SHOW_TODO_BOX" == "false" ]]; then
        return
    fi

    # Terminal width validation to prevent broken layouts (only for very narrow terminals)
    local effective_width=$((COLUMNS - _TODO_INTERNAL_PADDING_LEFT - _TODO_INTERNAL_PADDING_RIGHT))
    if [[ $effective_width -lt 15 ]]; then
        # Terminal too narrow for safe display - show minimal warning
        if [[ $((RANDOM % 20)) -eq 0 ]]; then  # Only occasionally to avoid spam
            echo "⚠️  Terminal too narrow for todo display (need 15+ columns)" >&2
        fi
        return 1
    fi

    load_tasks
    if [[ ${#todo_tasks} -gt 0 ]]; then
        # Add top padding
        for (( i = 0; i < _TODO_INTERNAL_PADDING_TOP; i++ )); do
            echo
        done

        draw_todo_box

        # Add bottom padding
        for (( i = 0; i < _TODO_INTERNAL_PADDING_BOTTOM; i++ )); do
            echo
        done
        
        # Show progressive hints based on task count
        show_progressive_hints
    else
        # Show empty state hint occasionally (not every prompt)
        show_empty_state_hint
    fi
}

# Show contextual hints for empty state
function show_empty_state_hint() {
    # Skip if hints are disabled
    if [[ "$_TODO_INTERNAL_SHOW_HINTS" != "true" ]]; then
        return
    fi
    
    # Only show hint occasionally to avoid being annoying
    # Create a hash based on current time to show hint ~10% of the time
    # Use seconds + microseconds for better randomness in tests
    local time_hash
    if command -v date >/dev/null 2>&1 && date +%N >/dev/null 2>&1; then
        # GNU date with nanoseconds
        time_hash=$(( ($(date +%s) + $(date +%N) / 1000000) % 10 ))
    else
        # Fallback for macOS/BSD date
        time_hash=$(( $(date +%s) % 10 ))
    fi
    
    if [[ $time_hash -eq 0 ]]; then
        local gray=$'\e[38;5;244m'
        local cyan=$'\e[38;5;51m'
        local reset=$'\e[0m'
        echo "${gray}💡 No tasks yet? Try: ${cyan}todo \"Something to remember\"${gray} (disable: _TODO_INTERNAL_SHOW_HINTS=false)${reset}"
    fi
}

# Show progressive discovery hints based on usage patterns
function show_progressive_hints() {
    # Skip if hints are disabled
    if [[ "$_TODO_INTERNAL_SHOW_HINTS" != "true" ]]; then
        return
    fi
    
    # Only show hints occasionally to avoid spam
    local time_hash=$(( $(date +%s) % 20 ))
    if [[ $time_hash -ne 0 ]]; then
        return
    fi
    
    local gray=$'\e[38;5;244m'
    local cyan=$'\e[38;5;51m'
    local reset=$'\e[0m'
    
    # Show different hints based on task count
    if [[ ${#todo_tasks} -ge 5 && ${#todo_tasks} -lt 8 ]]; then
        echo "${gray}💡 Lots of tasks? Customize colors: ${cyan}todo setup${gray} (disable: _TODO_INTERNAL_SHOW_HINTS=false)${reset}"
    elif [[ ${#todo_tasks} -ge 8 ]]; then
        echo "${gray}💡 Many tasks! Hide display when focused: ${cyan}todo hide${gray} (disable: _TODO_INTERNAL_SHOW_HINTS=false)${reset}"
    fi
}

# Save tasks, colors, and color index to single file (3 lines) with atomic operation
# Load configuration from serialized format
function _todo_load_config_from_line() {
    local config_line="$1"
    
    if [[ -z "$config_line" ]]; then
        return 0  # No config to load, keep defaults
    fi
    
    # Split by null separator and process each key=value pair
    # Split the config line on null bytes
    local -a config_parts
    config_parts=("${(@ps:\000:)config_line}")
    
    for pair in "${config_parts[@]}"; do
        if [[ "$pair" == *"="* ]]; then
            local key="${pair%%=*}"
            local value="${pair#*=}"
            
            # Only load known configuration variables for security
            case "$key" in
                _TODO_INTERNAL_COLOR_MODE|_TODO_INTERNAL_TITLE|_TODO_INTERNAL_HEART_CHAR|_TODO_INTERNAL_HEART_POSITION|_TODO_INTERNAL_BULLET_CHAR|\
                _TODO_INTERNAL_BOX_WIDTH_FRACTION|_TODO_INTERNAL_BOX_MIN_WIDTH|_TODO_INTERNAL_BOX_MAX_WIDTH|\
                _TODO_INTERNAL_SHOW_AFFIRMATION|_TODO_INTERNAL_SHOW_TODO_BOX|_TODO_INTERNAL_SHOW_HINTS|\
                _TODO_INTERNAL_PADDING_TOP|_TODO_INTERNAL_PADDING_RIGHT|_TODO_INTERNAL_PADDING_BOTTOM|_TODO_INTERNAL_PADDING_LEFT|\
                _TODO_INTERNAL_TASK_COLORS|_TODO_INTERNAL_BORDER_COLOR|_TODO_INTERNAL_BORDER_BG_COLOR|_TODO_INTERNAL_CONTENT_BG_COLOR|\
                _TODO_INTERNAL_TASK_TEXT_COLOR|_TODO_INTERNAL_TITLE_COLOR|_TODO_INTERNAL_AFFIRMATION_COLOR|TODO_BULLET_COLOR)
                    # Use typeset to set the variable dynamically
                    typeset -g "$key"="$value"
                    ;;
            esac
        fi
    done
    
    # Rebuild colors array from _TODO_INTERNAL_TASK_COLORS if it was loaded
    if [[ -n "$_TODO_INTERNAL_TASK_COLORS" ]]; then
        _TODO_INTERNAL_COLORS=(${(@s:,:)_TODO_INTERNAL_TASK_COLORS})
    fi
}

# Serialize current configuration for persistence
function _todo_serialize_config() {
    local config_parts=()
    
    # Core configuration variables to persist
    local config_vars=(
        "_TODO_INTERNAL_COLOR_MODE"
        "_TODO_INTERNAL_TITLE"
        "_TODO_INTERNAL_HEART_CHAR" 
        "_TODO_INTERNAL_HEART_POSITION"
        "_TODO_INTERNAL_BULLET_CHAR"
        "_TODO_INTERNAL_BOX_WIDTH_FRACTION"
        "_TODO_INTERNAL_BOX_MIN_WIDTH"
        "_TODO_INTERNAL_BOX_MAX_WIDTH"
        "_TODO_INTERNAL_SHOW_AFFIRMATION"
        "_TODO_INTERNAL_SHOW_TODO_BOX"
        "_TODO_INTERNAL_SHOW_HINTS"
        "_TODO_INTERNAL_PADDING_TOP"
        "_TODO_INTERNAL_PADDING_RIGHT"
        "_TODO_INTERNAL_PADDING_BOTTOM"
        "_TODO_INTERNAL_PADDING_LEFT"
        "_TODO_INTERNAL_TASK_COLORS"
        "_TODO_INTERNAL_BORDER_COLOR"
        "_TODO_INTERNAL_BORDER_BG_COLOR"
        "_TODO_INTERNAL_CONTENT_BG_COLOR"
        "_TODO_INTERNAL_TASK_TEXT_COLOR"
        "_TODO_INTERNAL_TITLE_COLOR"
        "_TODO_INTERNAL_AFFIRMATION_COLOR"
        "TODO_BULLET_COLOR"
    )
    
    # Serialize each variable as key=value
    for var in "${config_vars[@]}"; do
        local value="${(P)var}"  # Get value of variable named in $var
        if [[ -n "$value" ]]; then
            config_parts+=("$var=$value")
        fi
    done
    
    # Join with null separators
    local IFS=$'\000'
    echo "${config_parts[*]}"
}

function todo_save() {
    local temp_file="${_TODO_INTERNAL_SAVE_FILE}.tmp.$$"
    
    # Atomic write: write to temp file first, then move to final location
    local config_line="$(_todo_serialize_config)"
    if {
        echo "$TODO_TASKS"
        echo "$TODO_TASKS_COLORS"
        echo "$todo_color_index"
        echo "$config_line"
    } > "$temp_file" 2>/dev/null && mv "$temp_file" "$_TODO_INTERNAL_SAVE_FILE" 2>/dev/null; then
        # Update cache timestamp after successful save
        if stat -f %m "$_TODO_INTERNAL_SAVE_FILE" >/dev/null 2>&1; then
            _TODO_INTERNAL_FILE_MTIME=$(stat -f %m "$_TODO_INTERNAL_SAVE_FILE" 2>/dev/null)
        elif stat -c %Y "$_TODO_INTERNAL_SAVE_FILE" >/dev/null 2>&1; then
            _TODO_INTERNAL_FILE_MTIME=$(stat -c %Y "$_TODO_INTERNAL_SAVE_FILE" 2>/dev/null)
        else
            _TODO_INTERNAL_FILE_MTIME=$(wc -c < "$_TODO_INTERNAL_SAVE_FILE" 2>/dev/null || echo 0)
        fi
        # Clean and ensure numeric
        _TODO_INTERNAL_FILE_MTIME="${_TODO_INTERNAL_FILE_MTIME//[^0-9]/}"
        _TODO_INTERNAL_FILE_MTIME="${_TODO_INTERNAL_FILE_MTIME:-0}"
        # Update cache with current data
        _TODO_INTERNAL_CACHED_TASKS="$TODO_TASKS"
        _TODO_INTERNAL_CACHED_COLORS="$TODO_TASKS_COLORS"
        _TODO_INTERNAL_CACHED_COLOR_INDEX="$todo_color_index"
        return 0
    else
        # Clean up temp file on failure
        rm -f "$temp_file" 2>/dev/null
        echo "Warning: Could not save todo file $_TODO_INTERNAL_SAVE_FILE" >&2
        return 1
    fi
}

# Toggle or set visibility of affirmations
function todo_toggle_affirmation() {
    local action="${1:-toggle}"
    case "$action" in
        "show")
            _TODO_INTERNAL_SHOW_AFFIRMATION="true"
            echo "Affirmations enabled"
            ;;
        "hide")
            _TODO_INTERNAL_SHOW_AFFIRMATION="false"
            echo "Affirmations disabled"
            ;;
        "toggle")
            if [[ "$_TODO_INTERNAL_SHOW_AFFIRMATION" == "true" ]]; then
                _TODO_INTERNAL_SHOW_AFFIRMATION="false"
                echo "Affirmations disabled"
            else
                _TODO_INTERNAL_SHOW_AFFIRMATION="true"
                echo "Affirmations enabled"
            fi
            ;;
        *)
            echo "Usage: todo_toggle_affirmation [show|hide|toggle]" >&2
            echo "Current state: $_TODO_INTERNAL_SHOW_AFFIRMATION" >&2
            return 1
            ;;
    esac
}

# Toggle or set visibility of todo box
function todo_toggle_box() {
    local action="${1:-toggle}"
    case "$action" in
        "show")
            _TODO_INTERNAL_SHOW_TODO_BOX="true"
            echo "Todo box enabled"
            ;;
        "hide")
            _TODO_INTERNAL_SHOW_TODO_BOX="false"
            echo "Todo box disabled"
            ;;
        "toggle")
            if [[ "$_TODO_INTERNAL_SHOW_TODO_BOX" == "true" ]]; then
                _TODO_INTERNAL_SHOW_TODO_BOX="false"
                echo "Todo box disabled"
            else
                _TODO_INTERNAL_SHOW_TODO_BOX="true"
                echo "Todo box enabled"
            fi
            ;;
        *)
            echo "Usage: todo_toggle_box [show|hide|toggle]" >&2
            echo "Current state: $_TODO_INTERNAL_SHOW_TODO_BOX" >&2
            return 1
            ;;
    esac
}

# Toggle or set visibility of both affirmation and todo box
function todo_toggle_all() {
    local action="${1:-toggle}"
    case "$action" in
        "show")
            _TODO_INTERNAL_SHOW_AFFIRMATION="true"
            _TODO_INTERNAL_SHOW_TODO_BOX="true"
            echo "Affirmations and todo box enabled"
            ;;
        "hide")
            _TODO_INTERNAL_SHOW_AFFIRMATION="false"
            _TODO_INTERNAL_SHOW_TODO_BOX="false"
            echo "Affirmations and todo box disabled"
            ;;
        "toggle")
            if [[ "$_TODO_INTERNAL_SHOW_AFFIRMATION" == "true" && "$_TODO_INTERNAL_SHOW_TODO_BOX" == "true" ]]; then
                _TODO_INTERNAL_SHOW_AFFIRMATION="false"
                _TODO_INTERNAL_SHOW_TODO_BOX="false"
                echo "Affirmations and todo box disabled"
            else
                _TODO_INTERNAL_SHOW_AFFIRMATION="true"
                _TODO_INTERNAL_SHOW_TODO_BOX="true"
                echo "Affirmations and todo box enabled"
            fi
            ;;
        *)
            echo "Usage: todo_toggle_all [show|hide|toggle]" >&2
            echo "Current state - Affirmations: $_TODO_INTERNAL_SHOW_AFFIRMATION, Todo box: $_TODO_INTERNAL_SHOW_TODO_BOX" >&2
            return 1
            ;;
    esac
}

# Display color reference for choosing color values
# Shared function to render a single color with consistent formatting
function render_color_sample() {
    local color="$1"
    local format="${2:-full}"  # full, compact, minimal
    
    # Validate color input
    if [[ ! "$color" =~ ^[0-9]+$ ]] || [[ "$color" -gt 255 ]]; then
        printf "???"
        return 1
    fi
    
    # Use correct ANSI escape sequences: bg color for spaces, fg color for solid characters
    case "$format" in
        "compact")
            # Single colored block with number: 167█ (fg color for solid block)
            printf "%03d\033[38;5;%dm█\033[0m" "$color" "$color"
            ;;
        "minimal")
            # Just colored blocks: ████ (fg color for solid blocks)
            printf "\033[38;5;%dm████\033[0m" "$color"
            ;;
        "dot")
            # Colored dot with number: 167● (fg color for dot)
            printf "%03d\033[38;5;%dm●\033[0m" "$color" "$color"
            ;;
        "square")
            # Colored square with number: 167▪ (fg color for square)
            printf "%03d\033[38;5;%dm▪\033[0m" "$color" "$color"
            ;;
        "sandwich")
            # Blocks on both sides: █167█ (fg color for blocks)
            printf "\033[38;5;%dm█\033[0m%03d\033[38;5;%dm█\033[0m" "$color" "$color" "$color"
            ;;
        "full"|*)
            # Default: number + colored background: 167████ (bg color for spaces)
            printf "%03d\033[48;5;%dm    \033[0m" "$color" "$color"
            ;;
    esac
}

# Helper function to display a row of color squares 
function show_color_square_row() {
    local start_n="$1"
    local count="$2" 
    local row_len="${3:-12}"
    local format="${4:-full}"  # Add format parameter
    
    # Show each color using the shared render function
    for ((i=0; i<count; i++)); do
        local color=$((start_n + i))
        if [[ $color -gt 255 ]]; then break; fi
        render_color_sample "$color" "$format"
        printf " "  # Space between colors
    done
    echo
}

function todo_colors() {
    local max_colors="${1:-256}"  # Show all colors by default
    local row_len=12
    
    echo "🎨 Color Reference (256-color terminal palette)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    echo "Usage: todo config set colors \"num1,num2,num3\"     # Set task colors"
    echo "       todo config set border-color num           # Set border color"
    echo "       todo config get colors                     # See current colors"
    echo
    
    # Basic Colors (0-15) - 8 per row like your script
    echo "System Colors (0-15):"
    show_color_square_row 0 8
    show_color_square_row 8 8  
    echo
    
    # Extended colors (16-231) in organized blocks
    if [[ $max_colors -gt 16 ]]; then
        echo "Extended Colors (16-231):"
        local n=16
        local end_range=$((max_colors < 232 ? max_colors : 232))
        
        # Show in rows of 12 for clean layout
        for ((n=16; n<end_range; n+=row_len)); do
            local remaining=$((end_range - n))
            local count=$((remaining < row_len ? remaining : row_len))
            show_color_square_row $n $count
            
            # Add spacing every few rows for readability
            if [[ $((($n - 16) / row_len % 6)) -eq 5 ]]; then
                echo
            fi
        done
        echo
    fi
    
    # Grayscale Colors (232-255)
    if [[ $max_colors -gt 232 ]]; then
        echo "Grayscale Ramp (232-255):"
        show_color_square_row 232 12
        show_color_square_row 244 12
        echo
    fi
    
    echo "🎨 Current Plugin Colors:"
    
    # Show task colors with normal text + colored rectangles
    echo -n "    Tasks: "
    IFS=',' read -A current_task_colors <<< "$_TODO_INTERNAL_TASK_COLORS"
    for i in "${current_task_colors[@]}"; do
        printf "%03d\e[48;5;%dm    \e[0m " "$i" "$i"
    done
    echo
    
    # Show other current colors with same format, nicely aligned
    printf "    Border:     %03d\e[48;5;%dm    \e[0m\n" "$_TODO_INTERNAL_BORDER_COLOR" "$_TODO_INTERNAL_BORDER_COLOR"
    printf "    Border BG:  %03d\e[48;5;%dm    \e[0m\n" "$_TODO_INTERNAL_BORDER_BG_COLOR" "$_TODO_INTERNAL_BORDER_BG_COLOR"
    printf "    Content BG: %03d\e[48;5;%dm    \e[0m\n" "$_TODO_INTERNAL_CONTENT_BG_COLOR" "$_TODO_INTERNAL_CONTENT_BG_COLOR"
    printf "    Text:       %03d\e[48;5;%dm    \e[0m\n" "$_TODO_INTERNAL_TASK_TEXT_COLOR" "$_TODO_INTERNAL_TASK_TEXT_COLOR"
    printf "    Title:      %03d\e[48;5;%dm    \e[0m\n" "$_TODO_INTERNAL_TITLE_COLOR" "$_TODO_INTERNAL_TITLE_COLOR"
    printf "    Heart:      %03d\e[48;5;%dm    \e[0m\n" "$_TODO_INTERNAL_AFFIRMATION_COLOR" "$_TODO_INTERNAL_AFFIRMATION_COLOR"
}

# Show beginner-friendly help for core functionality
function todo_help() {
    local show_full="$1"
    
    # Handle --more/--full flag or redirect to full help
    if [[ "$show_full" == "--full" || "$show_full" == "-f" || "$show_full" == "--more" || "$show_full" == "-m" ]]; then
        todo_help_full
        return
    fi
    
    # Colors for formatting
    local bold=$'\e[1m'
    local reset=$'\e[0m'
    local blue=$'\e[38;5;39m'
    local green=$'\e[38;5;46m'
    local yellow=$'\e[38;5;226m'
    local cyan=$'\e[38;5;51m'
    local gray=$'\e[38;5;244m'
    
    echo "${bold}${blue}📝 Todo Reminder - Essential Commands${reset}"
    echo "${gray}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}"
    echo
    echo "  ${cyan}todo${reset} \"task description\"       ${gray}Add a new task${reset}"
    echo "  ${cyan}todo done${reset} \"pattern\"           ${gray}Remove completed task (with tab completion)${reset}"
    echo "  ${cyan}todo hide${reset}                       ${gray}Hide todo display${reset}"
    echo "  ${cyan}todo show${reset}                       ${gray}Show todo display${reset}"
    echo "  ${cyan}todo setup${reset}                      ${gray}Interactive customization wizard${reset}"
    echo "  ${cyan}todo help --colors${reset}              ${gray}View color reference for customization${reset}"
    echo
    echo "${bold}${yellow}Quick Start:${reset}"
    echo "  ${gray}todo \"Buy groceries\"     ${cyan}# Add your first task${reset}"
    echo "  ${gray}todo done \"Buy\"          ${cyan}# Remove when done (try tab completion!)${reset}"
    echo "  ${gray}todo setup                ${cyan}# Customize colors and appearance${reset}"
    echo
    echo "${gray}💡 More commands and options: ${cyan}todo help --full${reset}"
}

# Show comprehensive help with all configuration options
function todo_help_full() {
    # Colors for formatting
    local bold=$'\e[1m'
    local reset=$'\e[0m'
    local blue=$'\e[38;5;39m'
    local green=$'\e[38;5;46m'
    local yellow=$'\e[38;5;226m'
    local cyan=$'\e[38;5;51m'
    local magenta=$'\e[38;5;201m'
    local gray=$'\e[38;5;244m'
    local white=$'\e[38;5;255m'
    
    echo "${bold}${blue}📝 Zsh Todo Reminder Plugin - Complete Reference${reset}"
    echo "${gray}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}"
    echo
    echo "${bold}${green}📋 Task Management:${reset}"
    echo "  ${cyan}todo${reset} \"task\"                        ${gray}Add a new task${reset}"
    echo "  ${cyan}todo done${reset} \"pattern\"              ${gray}Remove completed task (tab completion)${reset}"
    echo
    echo "${bold}${green}👁️  Display Controls:${reset}"
    echo "  ${cyan}todo toggle affirmation${reset} [show|hide]     ${gray}Control affirmations${reset}"
    echo "  ${cyan}todo toggle box${reset} [show|hide]             ${gray}Control todo box${reset}"
    echo "  ${cyan}todo toggle all${reset} [show|hide]             ${gray}Control everything${reset}"
    echo "  ${cyan}todo hide${reset}                               ${gray}Hide all components${reset}"
    echo "  ${cyan}todo show${reset}                               ${gray}Show all components${reset}"
    echo "  ${cyan}todo help --colors${reset} [max_colors]           ${gray}Show color reference (default: 256)${reset}"
    echo
    echo "${bold}${green}⚙️  Configuration:${reset}"
    echo "  ${cyan}todo config export${reset} [file] [--colors-only] ${gray}Export configuration${reset}"
    echo "  ${cyan}todo config import${reset} <file> [--colors-only] ${gray}Import configuration${reset}"
    echo "  ${cyan}todo config set${reset} <setting> <value>         ${gray}Change setting${reset}"
    echo "  ${cyan}todo config reset${reset} [--colors-only]         ${gray}Reset to defaults${reset}"
    echo "  ${cyan}todo config preset${reset} <name>                 ${gray}Apply preset (${_TODO_INTERNAL_PRESET_LIST})${reset}"
    echo "    ${gray}Preset Intensities:${reset}"
    echo "      ${white}subtle${reset}   - Minimal decoration, muted colors"
    echo "      ${white}balanced${reset} - Professional appearance, moderate colors"
    echo "      ${white}vibrant${reset}  - Bright colors, full decoration"
    echo "      ${white}loud${reset}     - Maximum contrast, high visibility"
    echo "    ${gray}📌 Theme-adaptive variants (_tinted) are selected automatically${reset}"
    echo "    ${gray}   when tinted-shell or tinty are detected (_TODO_INTERNAL_COLOR_MODE=auto)${reset}"
    if command -v tinty >/dev/null 2>&1; then
        echo "    ${gray}💡 Tip: Use 'tinty apply [theme]' for 200+ additional themes${reset}"
    fi
    echo "  ${cyan}todo config save-preset${reset} <name>            ${gray}Save current as preset${reset}"
    echo "  ${cyan}todo config preview${reset} [preset]              ${gray}Preview color swatches${reset}"
    echo "  ${cyan}todo setup${reset}                               ${gray}Interactive configuration wizard${reset}"
    echo
    echo "${bold}${magenta}⚙️  Configuration Management:${reset}"
    echo "  ${white}Get Current Settings:${reset}"
    echo "    ${cyan}todo config get title${reset}                       ${gray}Get current box title${reset}"
    echo "    ${cyan}todo config get colors${reset}                      ${gray}Get current task colors${reset}"
    echo "    ${cyan}todo config get heart-position${reset}              ${gray}Get heart position (left|right|both|none)${reset}"
    echo
    echo "  ${white}Change Settings:${reset}"
    echo "    ${cyan}todo config set title \"MY TASKS\"${reset}           ${gray}Set custom box title${reset}"
    echo "    ${cyan}todo config set heart-char \"💖\"${reset}            ${gray}Set custom heart character${reset}"
    echo "    ${cyan}todo config set colors \"196,46,226\"${reset}        ${gray}Set custom task colors${reset}"
    echo "    ${cyan}todo config set padding-left 2${reset}              ${gray}Set left padding${reset}"
    echo
    echo "  ${white}View All Settings:${reset}"
    echo "    ${cyan}todo config list${reset}                            ${gray}Show all current settings (table format)${reset}"
    echo "    ${cyan}todo config list export${reset}                     ${gray}Show settings in export format${reset}"
    echo
    echo "  ${white}Quick Setup:${reset}"
    echo "    ${cyan}todo config preset vibrant${reset}                  ${gray}Apply vibrant color preset${reset}"
    echo "    ${cyan}todo config wizard${reset}                          ${gray}Interactive setup wizard${reset}"
    echo "    ${cyan}todo setup${reset}                                  ${gray}Quick setup (alias for wizard)${reset}"
    echo
    echo "${bold}${yellow}🎨 Color Reference:${reset} ${gray}(256-color codes 0-255)${reset}"
    echo "  ${white}View Available Colors:${reset}"
    echo "    ${cyan}todo colors${reset}                                 ${gray}Show color reference with current config${reset}"
    echo "    ${cyan}todo config get colors${reset}                      ${gray}See current task colors${reset}"
    echo "    ${cyan}todo config get border-color${reset}                ${gray}See current border color${reset}"
    echo
    echo "  ${white}Quick Color Examples:${reset}"
    echo "    ${cyan}todo config set colors \"196,46,226,51\"${reset}     ${gray}Bright: red, green, magenta, cyan${reset}"
    echo "    ${cyan}todo config set border-color 255${reset}            ${gray}White border${reset}"
    echo "    ${cyan}todo config set title-color 196${reset}             ${gray}Red title${reset}"
    echo
    echo "${bold}${green}📁 Files:${reset}"
    echo "  ${gray}~/.todo.save                       Task storage${reset}"
    echo "  ${gray}/tmp/todo_affirmation              Affirmation cache${reset}"
    echo
    echo "${bold}${yellow}💡 Advanced Examples:${reset}"
    echo "  ${gray}# Basic usage${reset}"
    echo "  ${cyan}todo${reset} \"Buy groceries\"               ${gray}# Add task${reset}"
    echo "  ${cyan}todo done${reset} \"Buy\"                    ${gray}# Remove task${reset}"
    echo "  ${cyan}todo toggle affirmation${reset} hide       ${gray}# Hide affirmations${reset}"
    echo "  ${cyan}todo help --colors${reset}                ${gray}# Show color reference${reset}"
    echo
    echo "  ${gray}# Customization examples${reset}"
    echo "  ${cyan}todo config set heart-char \"💖\"${reset}            ${gray}# Use emoji heart${reset}"
    echo "  ${cyan}todo config set padding-left 4${reset}              ${gray}# Add left padding${reset}"
    echo "  ${cyan}todo config set colors \"196,46,33,21,129\"${reset}   ${gray}# Bright custom colors${reset}"
    echo "  ${cyan}todo config set border-color 244${reset}            ${gray}# Lighter border${reset}"
    echo "  ${cyan}todo config set title-color 196${reset}             ${gray}# Red title${reset}"
    echo
    echo "  ${gray}# Box style examples${reset}"
    echo "  ${gray}# ASCII style:${reset}"
    echo "  ${cyan}todo config set box-top-left \"+\"${reset}           ${gray}# Simple ASCII corners${reset}"
    echo "  ${cyan}todo config set box-horizontal \"-\"${reset}         ${gray}# ASCII lines${reset}"
    echo
    echo "  ${gray}# Modern styles via presets:${reset}"
    echo "  ${cyan}todo config preset vibrant${reset}                  ${gray}# Bright, energetic colors${reset}"
    echo "  ${cyan}todo config preset subtle${reset}                   ${gray}# Muted, professional look${reset}"
    echo "  ${cyan}todo config preset loud${reset}                     ${gray}# High contrast, bold${reset}"
    echo
    echo "  ${gray}# Advanced configuration:${reset}"
    echo "  ${cyan}todo config export my-config.conf${reset}           ${gray}# Save current settings${reset}"
    echo "  ${cyan}todo config import my-config.conf${reset}           ${gray}# Load saved settings${reset}"
    echo "  ${cyan}todo config save-preset my-style${reset}            ${gray}# Save as custom preset${reset}"
    echo
    echo "${bold}${blue}🔗 Links:${reset}"
    echo "  ${gray}Repository: https://github.com/kindjie/zsh-todo-reminder${reset}"
    echo "  ${gray}Issues:     https://github.com/kindjie/zsh-todo-reminder/issues${reset}"
    echo "  ${gray}Releases:   https://github.com/kindjie/zsh-todo-reminder/releases${reset}"
}


# Set individual configuration values
function todo_config_set() {
    local setting="$1"
    local value="$2"
    
    if [[ -z "$setting" || -z "$value" ]]; then
        echo "Usage: todo_config_set <setting> <value>" >&2
        echo "Settings: color-mode, title, heart-char, heart-position, bullet-char, colors, border-color, text-color, padding-left, etc." >&2
        return 1
    fi
    
    case "$setting" in
        "color-mode")
            if [[ "$value" =~ ^(static|dynamic|auto)$ ]]; then
                typeset -g _TODO_INTERNAL_COLOR_MODE="$value"
                echo "Color mode set to: $value"
                case "$value" in
                    "static") echo "  Will always use regular presets (256-color codes)" ;;
                    "dynamic") echo "  Will always use theme-adaptive presets (base16 colors)" ;;
                    "auto") echo "  Will auto-detect tinted-shell/tinty for theme integration" ;;
                esac
            else
                echo "Error: Color mode must be 'static', 'dynamic', or 'auto'" >&2
                return 1
            fi
            ;;
        "title")
            _TODO_INTERNAL_TITLE="$value"
            echo "Title set to: $value"
            ;;
        "heart-char")
            _TODO_INTERNAL_HEART_CHAR="$value"
            echo "Heart character set to: $value"
            ;;
        "heart-position")
            if [[ "$value" =~ ^(left|right|both|none)$ ]]; then
                _TODO_INTERNAL_HEART_POSITION="$value"
                echo "Heart position set to: $value"
            else
                echo "Error: Heart position must be left, right, both, or none" >&2
                return 1
            fi
            ;;
        "bullet-char")
            _TODO_INTERNAL_BULLET_CHAR="$value"
            echo "Bullet character set to: $value"
            ;;
        "colors")
            if [[ "$value" =~ ^[0-9]+(,[0-9]+)*$ ]]; then
                _TODO_INTERNAL_TASK_COLORS="$value"
                _TODO_INTERNAL_COLORS=(${(@s:,:)_TODO_INTERNAL_TASK_COLORS})
                echo "Task colors set to: $value"
            else
                echo "Error: Colors must be comma-separated numbers (0-255)" >&2
                return 1
            fi
            ;;
        "border-color")
            if [[ "$value" =~ ^[0-9]+$ ]] && [[ $value -le 255 ]]; then
                _TODO_INTERNAL_BORDER_COLOR="$value"
                echo "Border color set to: $value"
            else
                echo "Error: Border color must be a number 0-255" >&2
                return 1
            fi
            ;;
        "text-color"|"task-text-color")
            if [[ "$value" =~ ^[0-9]+$ ]] && [[ $value -le 255 ]]; then
                _TODO_INTERNAL_TASK_TEXT_COLOR="$value"
                echo "Task text color set to: $value"
            else
                echo "Error: Task text color must be a number 0-255" >&2
                return 1
            fi
            ;;
        "padding-left")
            if [[ "$value" =~ ^[0-9]+$ ]]; then
                _TODO_INTERNAL_PADDING_LEFT="$value"
                echo "Left padding set to: $value"
            else
                echo "Error: Padding must be a non-negative number" >&2
                return 1
            fi
            ;;
        "box-width")
            if [[ "$value" =~ ^0\.[0-9]+$ ]] || [[ "$value" =~ ^1\.0$ ]]; then
                _TODO_INTERNAL_BOX_WIDTH_FRACTION="$value"
                echo "Box width fraction set to: $value"
            else
                echo "Error: Box width must be a decimal between 0.0 and 1.0" >&2
                return 1
            fi
            ;;
        *)
            echo "Error: Unknown setting '$setting'" >&2
            echo "Available settings: color-mode, title, heart-char, heart-position, bullet-char, colors, border-color, text-color, padding-left, box-width" >&2
            return 1
            ;;
    esac
    
    # Persist configuration changes
    todo_save
}

# Reset configuration to defaults
function todo_config_reset() {
    local colors_only="$1"
    
    if [[ "$colors_only" == "--colors-only" ]]; then
        # Reset only color settings
        _TODO_INTERNAL_TASK_COLORS="167,71,136,110,139,73"
        _TODO_INTERNAL_BORDER_COLOR="240"
        _TODO_INTERNAL_BORDER_BG_COLOR="235"
        _TODO_INTERNAL_CONTENT_BG_COLOR="235"
        TODO_TEXT_COLOR="240"
        _TODO_INTERNAL_TASK_TEXT_COLOR="240"
        _TODO_INTERNAL_TITLE_COLOR="250"
        _TODO_INTERNAL_AFFIRMATION_COLOR="109"
        TODO_BULLET_COLOR="39"
        _TODO_INTERNAL_COLORS=(${(@s:,:)_TODO_INTERNAL_TASK_COLORS})
        echo "Color configuration reset to defaults"
    else
        # Reset all settings to defaults
        _TODO_INTERNAL_COLOR_MODE="auto"
        _TODO_INTERNAL_TITLE="REMEMBER"
        _TODO_INTERNAL_HEART_CHAR="♥"
        _TODO_INTERNAL_HEART_POSITION="left"
        _TODO_INTERNAL_BULLET_CHAR="▪"
        _TODO_INTERNAL_BOX_WIDTH_FRACTION="0.5"
        _TODO_INTERNAL_SHOW_AFFIRMATION="true"
        _TODO_INTERNAL_SHOW_TODO_BOX="true"
        _TODO_INTERNAL_SHOW_HINTS="true"
        _TODO_INTERNAL_PADDING_TOP="0"
        _TODO_INTERNAL_PADDING_RIGHT="4"
        _TODO_INTERNAL_PADDING_BOTTOM="0"
        _TODO_INTERNAL_PADDING_LEFT="0"
        _TODO_INTERNAL_TASK_COLORS="167,71,136,110,139,73"
        _TODO_INTERNAL_BORDER_COLOR="240"
        _TODO_INTERNAL_BORDER_BG_COLOR="235"
        _TODO_INTERNAL_CONTENT_BG_COLOR="235"
        TODO_TEXT_COLOR="240"
        _TODO_INTERNAL_TASK_TEXT_COLOR="240"
        _TODO_INTERNAL_TITLE_COLOR="250"
        _TODO_INTERNAL_AFFIRMATION_COLOR="109"
        TODO_BULLET_COLOR="39"
        _TODO_INTERNAL_BOX_TOP_LEFT="┌"
        _TODO_INTERNAL_BOX_TOP_RIGHT="┐"
        _TODO_INTERNAL_BOX_BOTTOM_LEFT="└"
        _TODO_INTERNAL_BOX_BOTTOM_RIGHT="┘"
        _TODO_INTERNAL_BOX_HORIZONTAL="─"
        _TODO_INTERNAL_BOX_VERTICAL="│"
        _TODO_INTERNAL_COLORS=(${(@s:,:)_TODO_INTERNAL_TASK_COLORS})
        echo "Configuration reset to defaults"
    fi
}


# Apply presets (delegate to config module)
function todo_config_preset() {
    todo_config_apply_preset "$@"
    
    # Save configuration changes for persistence
    todo_save
}


# Preview color swatches (delegate to config module)
function todo_config_preview() {
    todo_config_preview_presets "$@"
}

# Save current configuration as a preset file

# ============================================================================
# Lazy Loading Infrastructure
# ============================================================================

# Get plugin directory for loading modules
typeset -g _TODO_INTERNAL_PLUGIN_DIR="${_TODO_INTERNAL_PLUGIN_DIR:-$(dirname "${(%):-%x}")}"

# Track loaded modules to avoid duplicate loading
typeset -g -a _TODO_INTERNAL_LOADED_MODULES
_TODO_INTERNAL_LOADED_MODULES=()

# Lazy loading function for optional modules
function autoload_todo_module() {
    local module="$1"
    local module_file="$_TODO_INTERNAL_PLUGIN_DIR/lib/${module}.zsh"
    
    # Check if module is already loaded
    if [[ ${_TODO_INTERNAL_LOADED_MODULES[(ie)$module]} -le ${#_TODO_INTERNAL_LOADED_MODULES} ]]; then
        return 0  # Already loaded
    fi
    
    # Check if module file exists
    if [[ ! -f "$module_file" ]]; then
        echo "Warning: Module '$module' not found at $module_file" >&2
        return 1
    fi
    
    # Load the module
    if source "$module_file" 2>/dev/null; then
        _TODO_INTERNAL_LOADED_MODULES+=("$module")
        return 0
    else
        echo "Error: Failed to load module '$module'" >&2
        return 1
    fi
}

# ============================================================================
# Lazy Loading Wrapper Functions
# ============================================================================

# Configuration wizard and advanced config management
function todo_config() {
    if ! autoload_todo_module "wizard"; then
        echo "Error: Wizard module required for todo_config command" >&2
        return 1
    fi
    _todo_config_real "$@"
}

# Interactive setup wizard (beginner entry point)
function todo_config_wizard() {
    if ! autoload_todo_module "wizard"; then
        echo "Error: Wizard module required for setup" >&2
        return 1
    fi
    _todo_config_wizard_real "$@"
}

# Initialize internal variables from any environment variables
# This must be called after all default variable assignments
if command -v _todo_convert_to_internal_vars >/dev/null 2>&1; then
    _todo_convert_to_internal_vars
fi

