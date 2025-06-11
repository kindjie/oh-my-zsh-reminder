# Configuration variables - can be overridden before sourcing plugin
TODO_SAVE_FILE="${TODO_SAVE_FILE:-$HOME/.todo.save}"
TODO_AFFIRMATION_FILE="${TODO_AFFIRMATION_FILE:-${TMPDIR:-/tmp}/todo_affirmation}"

# Available configuration presets (single source of truth)
_TODO_AVAILABLE_PRESETS=("minimal" "colorful" "work" "dark" "monokai" "solarized-dark" "nord" "gruvbox-dark" "base16-auto")
_TODO_PRESET_LIST="${(j:, :)_TODO_AVAILABLE_PRESETS}"

# Box width configuration (fraction of terminal width, with min/max limits)
TODO_BOX_WIDTH_FRACTION="${TODO_BOX_WIDTH_FRACTION:-0.5}"  # 50% by default
TODO_BOX_MIN_WIDTH="${TODO_BOX_MIN_WIDTH:-30}"            # Minimum 30 chars
TODO_BOX_MAX_WIDTH="${TODO_BOX_MAX_WIDTH:-80}"            # Maximum 80 chars

# Display configuration
TODO_TITLE="${TODO_TITLE:-REMEMBER}"                      # Box title
TODO_HEART_CHAR="${TODO_HEART_CHAR:-♥}"                   # Affirmation heart character
TODO_HEART_POSITION="${TODO_HEART_POSITION:-left}"        # Heart position: "left", "right", "both", "none"
TODO_BULLET_CHAR="${TODO_BULLET_CHAR:-▪}"                 # Task bullet character

# Show/hide state configuration
TODO_SHOW_AFFIRMATION="${TODO_SHOW_AFFIRMATION:-true}"    # Show affirmations: "true", "false"
TODO_SHOW_TODO_BOX="${TODO_SHOW_TODO_BOX:-true}"          # Show todo box: "true", "false"
TODO_SHOW_HINTS="${TODO_SHOW_HINTS:-true}"                # Show contextual hints: "true", "false"

# Padding/margin configuration (in characters)
TODO_PADDING_TOP="${TODO_PADDING_TOP:-0}"                 # Top padding/margin
TODO_PADDING_RIGHT="${TODO_PADDING_RIGHT:-4}"             # Right padding/margin
TODO_PADDING_BOTTOM="${TODO_PADDING_BOTTOM:-0}"           # Bottom padding/margin
TODO_PADDING_LEFT="${TODO_PADDING_LEFT:-0}"               # Left padding/margin

# Color configuration (256-color terminal codes)
TODO_TASK_COLORS="${TODO_TASK_COLORS:-167,71,136,110,139,73}"    # Task bullet colors (comma-separated)
TODO_BORDER_COLOR="${TODO_BORDER_COLOR:-240}"                     # Box border foreground color

# Handle legacy compatibility first
if [[ -n "${TODO_BACKGROUND_COLOR:-}" ]]; then
    # If TODO_BACKGROUND_COLOR is set, use it as default for both new variables
    TODO_BORDER_BG_COLOR="${TODO_BORDER_BG_COLOR:-$TODO_BACKGROUND_COLOR}"
    TODO_CONTENT_BG_COLOR="${TODO_CONTENT_BG_COLOR:-$TODO_BACKGROUND_COLOR}"
else
    # Use individual defaults if legacy variable not set
    TODO_BORDER_BG_COLOR="${TODO_BORDER_BG_COLOR:-235}"               # Box border background color
    TODO_CONTENT_BG_COLOR="${TODO_CONTENT_BG_COLOR:-235}"             # Box content background color
fi

TODO_TEXT_COLOR="${TODO_TEXT_COLOR:-240}"                         # Task text color (legacy)
TODO_TASK_TEXT_COLOR="${TODO_TASK_TEXT_COLOR:-240}"               # Task text color
TODO_TITLE_COLOR="${TODO_TITLE_COLOR:-250}"                       # Box title color
TODO_AFFIRMATION_COLOR="${TODO_AFFIRMATION_COLOR:-109}"           # Affirmation text color
TODO_BULLET_COLOR="${TODO_BULLET_COLOR:-39}"                      # Bullet color

# Box drawing characters configuration
TODO_BOX_TOP_LEFT="${TODO_BOX_TOP_LEFT:-┌}"                       # Top left corner
TODO_BOX_TOP_RIGHT="${TODO_BOX_TOP_RIGHT:-┐}"                     # Top right corner
TODO_BOX_BOTTOM_LEFT="${TODO_BOX_BOTTOM_LEFT:-└}"                 # Bottom left corner
TODO_BOX_BOTTOM_RIGHT="${TODO_BOX_BOTTOM_RIGHT:-┘}"               # Bottom right corner
TODO_BOX_HORIZONTAL="${TODO_BOX_HORIZONTAL:-─}"                   # Horizontal line
TODO_BOX_VERTICAL="${TODO_BOX_VERTICAL:-│}"                       # Vertical line

# Validate heart character display width (allows Unicode characters including emojis)
if [[ -z "$TODO_HEART_CHAR" ]] || [[ ${#TODO_HEART_CHAR} -gt 4 ]]; then
    echo "Error: TODO_HEART_CHAR must be a single character or emoji, got: '$TODO_HEART_CHAR'" >&2
    return 1
fi

# Validate heart position
if [[ "$TODO_HEART_POSITION" != "left" && "$TODO_HEART_POSITION" != "right" && "$TODO_HEART_POSITION" != "both" && "$TODO_HEART_POSITION" != "none" ]]; then
    echo "Error: TODO_HEART_POSITION must be 'left', 'right', 'both', or 'none', got: '$TODO_HEART_POSITION'" >&2
    return 1
fi

# Validate bullet character display width (allows Unicode characters including emojis)
if [[ -z "$TODO_BULLET_CHAR" ]] || [[ ${#TODO_BULLET_CHAR} -gt 4 ]]; then
    echo "Error: TODO_BULLET_CHAR must be a single character or emoji, got: '$TODO_BULLET_CHAR'" >&2
    return 1
fi

# Validate show/hide configurations
if [[ "$TODO_SHOW_AFFIRMATION" != "true" && "$TODO_SHOW_AFFIRMATION" != "false" ]]; then
    echo "Error: TODO_SHOW_AFFIRMATION must be 'true' or 'false', got: '$TODO_SHOW_AFFIRMATION'" >&2
    return 1
fi

if [[ "$TODO_SHOW_TODO_BOX" != "true" && "$TODO_SHOW_TODO_BOX" != "false" ]]; then
    echo "Error: TODO_SHOW_TODO_BOX must be 'true' or 'false', got: '$TODO_SHOW_TODO_BOX'" >&2
    return 1
fi

if [[ "$TODO_SHOW_HINTS" != "true" && "$TODO_SHOW_HINTS" != "false" ]]; then
    echo "Error: TODO_SHOW_HINTS must be 'true' or 'false', got: '$TODO_SHOW_HINTS'" >&2
    return 1
fi

# Validate padding configurations are numeric
for padding_var in TODO_PADDING_TOP TODO_PADDING_RIGHT TODO_PADDING_BOTTOM TODO_PADDING_LEFT; do
    local padding_value="${(P)padding_var}"
    if [[ ! "$padding_value" =~ ^[0-9]+$ ]]; then
        echo "Error: $padding_var must be a non-negative integer, got: '$padding_value'" >&2
        return 1
    fi
done

# Validate color configurations are numeric
for color_var in TODO_BORDER_COLOR TODO_BORDER_BG_COLOR TODO_CONTENT_BG_COLOR TODO_TEXT_COLOR TODO_TASK_TEXT_COLOR TODO_TITLE_COLOR TODO_AFFIRMATION_COLOR TODO_BULLET_COLOR; do
    local color_value="${(P)color_var}"
    if [[ ! "$color_value" =~ ^[0-9]+$ ]] || [[ $color_value -gt 255 ]]; then
        echo "Error: $color_var must be a number between 0-255, got: '$color_value'" >&2
        return 1
    fi
done

# Validate legacy TODO_BACKGROUND_COLOR if set
if [[ -n "${TODO_BACKGROUND_COLOR:-}" ]]; then
    if [[ ! "$TODO_BACKGROUND_COLOR" =~ ^[0-9]+$ ]] || [[ $TODO_BACKGROUND_COLOR -gt 255 ]]; then
        echo "Error: TODO_BACKGROUND_COLOR must be a number between 0-255, got: '$TODO_BACKGROUND_COLOR'" >&2
        return 1
    fi
fi

# Validate and parse task colors
if [[ -z "$TODO_TASK_COLORS" ]] || [[ ! "$TODO_TASK_COLORS" =~ ^[0-9]+(,[0-9]+)*$ ]]; then
    echo "Error: TODO_TASK_COLORS must be comma-separated numbers (0-255), got: '$TODO_TASK_COLORS'" >&2
    return 1
fi

# Convert comma-separated string to array and validate range
IFS=',' read -A task_color_array <<< "$TODO_TASK_COLORS"
for color in "${task_color_array[@]}"; do
    if [[ $color -gt 255 ]]; then
        echo "Error: Task color values must be 0-255, got: '$color'" >&2
        return 1
    fi
done

# Validate box drawing characters (must be single characters)
for box_var in TODO_BOX_TOP_LEFT TODO_BOX_TOP_RIGHT TODO_BOX_BOTTOM_LEFT TODO_BOX_BOTTOM_RIGHT TODO_BOX_HORIZONTAL TODO_BOX_VERTICAL; do
    local box_char="${(P)box_var}"
    if [[ -z "$box_char" ]] || [[ ${#box_char} -gt 4 ]]; then
        echo "Error: $box_var must be a single character, got: '$box_char'" >&2
        return 1
    fi
done


# Initialize color palette from configuration
typeset -a TODO_COLORS
TODO_COLORS=(${(@s:,:)TODO_TASK_COLORS})


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
    if [[ -f "$TODO_SAVE_FILE" ]]; then
        # Try different stat formats for cross-platform compatibility
        if stat -f %m "$TODO_SAVE_FILE" >/dev/null 2>&1; then
            # macOS/BSD stat
            current_mtime=$(stat -f %m "$TODO_SAVE_FILE" 2>/dev/null)
        elif stat -c %Y "$TODO_SAVE_FILE" >/dev/null 2>&1; then
            # GNU stat
            current_mtime=$(stat -c %Y "$TODO_SAVE_FILE" 2>/dev/null)
        else
            # Fallback: use file size + random as a poor approximation
            current_mtime=$(wc -c < "$TODO_SAVE_FILE" 2>/dev/null || echo 0)
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
        
        if [[ -e "$TODO_SAVE_FILE" ]]; then
            if ! local file_content="$(cat "$TODO_SAVE_FILE" 2>/dev/null)"; then
                echo "Warning: Could not read todo file $TODO_SAVE_FILE" >&2
                todo_tasks=()
                todo_tasks_colors=()
                todo_color_index=1
                # Clear cache on error
                _TODO_INTERNAL_CACHED_TASKS=""
                _TODO_INTERNAL_CACHED_COLORS=""
                _TODO_INTERNAL_CACHED_COLOR_INDEX=1
                return 1
            fi

            # Validate file format (should have exactly 3 lines)
            local line_count=$(echo "$file_content" | wc -l)
            if [[ $line_count -ne 3 ]]; then
                echo "Warning: Invalid todo file format (expected 3 lines, got $line_count), creating backup and resetting" >&2
                if cp "$TODO_SAVE_FILE" "$TODO_SAVE_FILE.backup.$(date +%s)" 2>/dev/null; then
                    echo "Backup created: $TODO_SAVE_FILE.backup.$(date +%s)" >&2
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
        local color_code=$'\e[38;5;'${TODO_COLORS[color_index]}$'m'
        new_colors+=("$color_code")
        (( color_index = (color_index % ${#TODO_COLORS}) + 1 ))
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
    local percentage=$((${TODO_BOX_WIDTH_FRACTION} * 100))
    local desired_width=$((COLUMNS * percentage / 100))
    local width=$desired_width

    # Apply minimum constraint
    if [[ $width -lt $TODO_BOX_MIN_WIDTH ]]; then
        width=$TODO_BOX_MIN_WIDTH
    fi

    # Apply maximum constraint
    if [[ $width -gt $TODO_BOX_MAX_WIDTH ]]; then
        width=$TODO_BOX_MAX_WIDTH
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
    case "$TODO_HEART_POSITION" in
        "left")
            echo "${TODO_HEART_CHAR} ${text}"
            ;;
        "right")
            echo "${text} ${TODO_HEART_CHAR}"
            ;;
        "both")
            echo "${TODO_HEART_CHAR} ${text} ${TODO_HEART_CHAR}"
            ;;
        "none")
            echo "${text}"
            ;;
        *)
            # Fallback to left if somehow invalid
            echo "${TODO_HEART_CHAR} ${text}"
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
    
    local color=$'\e[38;5;'${TODO_COLORS[${todo_color_index}]}$'m'

    load_tasks
    todo_tasks+="$task"
    todo_tasks_colors+="$color"
    (( todo_color_index %= ${#TODO_COLORS} ))
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
        export)
            todo_config_export "${@:2}"
            ;;
        import)
            todo_config_import "${@:2}"
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
            todo_config_save_preset "${@:2}"
            ;;
        preview)
            todo_config_preview "${@:2}"
            ;;
        "")
            echo "Usage: todo config <action> [options]"
            echo "Actions:"
            echo "  export [file]         # Export configuration"
            echo "  import <file>         # Import configuration"
            echo "  set <key> <value>     # Set configuration value"
            echo "  reset                 # Reset to defaults"
            echo "  preset <name>         # Apply preset (${_TODO_PRESET_LIST})"
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
    echo "  ${gray}${_TODO_PRESET_LIST}${reset}"
    echo
    echo "${green}Environment Variables:${reset}"
    echo "  ${cyan}TODO_TITLE${reset}               Box title (default: REMEMBER)"
    echo "  ${cyan}TODO_HEART_CHAR${reset}          Affirmation character (default: ♥)"
    echo "  ${cyan}TODO_TASK_COLORS${reset}         Task colors (comma-separated)"
    echo "  ${cyan}TODO_SHOW_AFFIRMATION${reset}    Show affirmations (true/false)"
    echo "  ${cyan}TODO_PADDING_LEFT${reset}        Left padding (default: 0)"
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
                    local -a presets=('minimal' 'colorful' 'work' 'dark' 'monokai' 'solarized-dark' 'nord' 'gruvbox-dark' 'base16-auto')
                    _describe 'presets' presets
                    ;;
                "config set")
                    local -a settings=(
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
                    local -a presets=('all' 'minimal' 'colorful' 'work' 'dark' 'monokai' 'solarized-dark' 'nord' 'gruvbox-dark' 'base16-auto')
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
    local gray_color=$'\e[38;5;'${TODO_TASK_TEXT_COLOR}$'m'
    local title_color=$'\e[38;5;'${TODO_TITLE_COLOR}$'m'

    # Check if this is a title (REMEMBER is a special case)
    if [[ "$is_title" == "true" ]]; then
        # This is a title - no prefix, use bullet color for title
        echo "${title_color}${text}${gray_color}"
        return
    fi

    # For regular tasks, we need to handle bullet and text separately
    # Use the original task-specific bullet color for visual distinction
    local bullet="${bullet_color}${TODO_BULLET_CHAR}${gray_color}"

    # Account for bullet display width and space
    local remaining_width=$((max_width - ${(m)#TODO_BULLET_CHAR} - 1))

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
    local effective_columns=$((COLUMNS - TODO_PADDING_LEFT - TODO_PADDING_RIGHT))
    local left_width=$((effective_columns - box_width))
    local affirmation_color=$'\e[38;5;'${TODO_AFFIRMATION_COLOR}$'m'

    # Ensure left_width is positive
    if [[ $left_width -lt 10 ]]; then
        left_width=10
    fi

    # Add left padding
    printf "%*s" $TODO_PADDING_LEFT ""

    # Display left content (affirmation) at start of line if enabled
    if [[ "$TODO_SHOW_AFFIRMATION" == "true" && -n "$left_content" ]]; then
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
    if [[ $TODO_PADDING_RIGHT -gt 0 ]]; then
        printf "%*s" $TODO_PADDING_RIGHT ""
    fi

    echo
}

# Draw todo box on right side of terminal with configurable width
function draw_todo_box() {
    setopt LOCAL_OPTIONS
    unsetopt XTRACE
    local box_width=$(calculate_box_width)
    local content_width=$((box_width - 4))  # 2 for borders, 2 for padding
    local border_fg_color=$'\e[38;5;'${TODO_BORDER_COLOR}$'m'
    local border_bg_color=$'\e[48;5;'${TODO_BORDER_BG_COLOR}$'m'
    local content_bg_color=$'\e[48;5;'${TODO_CONTENT_BG_COLOR}$'m'
    local reset_bg=$'\e[49m'

    if [[ ${#todo_tasks} -eq 0 ]]; then
        return
    fi

    # Read cached affirmation if available, otherwise use fallback
    local affirm_text
    if [[ -f "$TODO_AFFIRMATION_FILE" && -s "$TODO_AFFIRMATION_FILE" ]]; then
        local cached_affirm="$(cat "$TODO_AFFIRMATION_FILE" 2>/dev/null)"
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

    local effective_columns=$((COLUMNS - TODO_PADDING_LEFT - TODO_PADDING_RIGHT))
    local left_width=$((effective_columns - box_width))

    # Truncate affirmation if too long (preserve formatting and add ellipsis)
    local clean_affirm_text="$(echo "$affirm_text" | sed 's/\x1b\[[0-9;]*m//g')"
    local affirm_display_width=${(m)#clean_affirm_text}
    if [[ $affirm_display_width -gt $left_width ]]; then
        local max_affirm_len=$((left_width - 3))  # Reserve space for "..."

        # Calculate space needed for heart character
        local heart_width=${(m)#TODO_HEART_CHAR}

        case "$TODO_HEART_POSITION" in
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
        case "$TODO_HEART_POSITION" in
            "left")
                core_text="${affirm_text#${TODO_HEART_CHAR} }"
                ;;
            "right")
                core_text="${affirm_text% ${TODO_HEART_CHAR}}"
                ;;
            "both")
                core_text="${affirm_text#${TODO_HEART_CHAR} }"
                core_text="${core_text% ${TODO_HEART_CHAR}}"
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
    done <<< "$(wrap_todo_text "$TODO_TITLE" "$content_width" "" "true")"

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
    local horizontal_line="$(printf "${TODO_BOX_HORIZONTAL}%.0s" $(seq 1 $border_chars))"
    local top_border="${TODO_BOX_TOP_LEFT}${horizontal_line}${TODO_BOX_TOP_RIGHT}"
    format_todo_line "" "${border_fg_color}${border_bg_color}$top_border${reset_bg}" ""

    # Content lines
    for (( i = 1; i <= ${#all_lines}; i++ )); do
        # Strip color codes and calculate display width for proper box alignment
        local clean_line="$(echo "${all_lines[i]}" | sed 's/\x1b\[[0-9;]*m//g')"
        local line_display_width=${(m)#clean_line}
        local padding_needed=$((content_width - line_display_width))
        local padding="$(printf '%*s' $padding_needed '')"
        local content_line="${all_lines[i]}${border_fg_color}${padding}"
        local left_border="${border_fg_color}${border_bg_color}${TODO_BOX_VERTICAL}${reset_bg}"
        local right_border="${border_fg_color}${border_bg_color}${TODO_BOX_VERTICAL}${reset_bg}"
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
    local bottom_border="${TODO_BOX_BOTTOM_LEFT}${horizontal_line}${TODO_BOX_BOTTOM_RIGHT}"
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
            echo "$new_affirm" > "$TODO_AFFIRMATION_FILE"
        fi
    fi
}

# Display todo box with tasks (called before each prompt)
function todo_display() {
    # Skip display if todo box is hidden
    if [[ "$TODO_SHOW_TODO_BOX" == "false" ]]; then
        return
    fi

    # Terminal width validation to prevent broken layouts (only for very narrow terminals)
    local effective_width=$((COLUMNS - TODO_PADDING_LEFT - TODO_PADDING_RIGHT))
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
        for (( i = 0; i < TODO_PADDING_TOP; i++ )); do
            echo
        done

        draw_todo_box

        # Add bottom padding
        for (( i = 0; i < TODO_PADDING_BOTTOM; i++ )); do
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
    if [[ "$TODO_SHOW_HINTS" != "true" ]]; then
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
        echo "${gray}💡 No tasks yet? Try: ${cyan}todo \"Something to remember\"${gray} (disable: TODO_SHOW_HINTS=false)${reset}"
    fi
}

# Show progressive discovery hints based on usage patterns
function show_progressive_hints() {
    # Skip if hints are disabled
    if [[ "$TODO_SHOW_HINTS" != "true" ]]; then
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
        echo "${gray}💡 Lots of tasks? Customize colors: ${cyan}todo setup${gray} (disable: TODO_SHOW_HINTS=false)${reset}"
    elif [[ ${#todo_tasks} -ge 8 ]]; then
        echo "${gray}💡 Many tasks! Hide display when focused: ${cyan}todo hide${gray} (disable: TODO_SHOW_HINTS=false)${reset}"
    fi
}

# Save tasks, colors, and color index to single file (3 lines) with atomic operation
function todo_save() {
    local temp_file="${TODO_SAVE_FILE}.tmp.$$"
    
    # Atomic write: write to temp file first, then move to final location
    if {
        echo "$TODO_TASKS"
        echo "$TODO_TASKS_COLORS"
        echo "$todo_color_index"
    } > "$temp_file" 2>/dev/null && mv "$temp_file" "$TODO_SAVE_FILE" 2>/dev/null; then
        # Update cache timestamp after successful save
        if stat -f %m "$TODO_SAVE_FILE" >/dev/null 2>&1; then
            _TODO_INTERNAL_FILE_MTIME=$(stat -f %m "$TODO_SAVE_FILE" 2>/dev/null)
        elif stat -c %Y "$TODO_SAVE_FILE" >/dev/null 2>&1; then
            _TODO_INTERNAL_FILE_MTIME=$(stat -c %Y "$TODO_SAVE_FILE" 2>/dev/null)
        else
            _TODO_INTERNAL_FILE_MTIME=$(wc -c < "$TODO_SAVE_FILE" 2>/dev/null || echo 0)
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
        echo "Warning: Could not save todo file $TODO_SAVE_FILE" >&2
        return 1
    fi
}

# Toggle or set visibility of affirmations
function todo_toggle_affirmation() {
    local action="${1:-toggle}"
    case "$action" in
        "show")
            TODO_SHOW_AFFIRMATION="true"
            echo "Affirmations enabled"
            ;;
        "hide")
            TODO_SHOW_AFFIRMATION="false"
            echo "Affirmations disabled"
            ;;
        "toggle")
            if [[ "$TODO_SHOW_AFFIRMATION" == "true" ]]; then
                TODO_SHOW_AFFIRMATION="false"
                echo "Affirmations disabled"
            else
                TODO_SHOW_AFFIRMATION="true"
                echo "Affirmations enabled"
            fi
            ;;
        *)
            echo "Usage: todo_toggle_affirmation [show|hide|toggle]" >&2
            echo "Current state: $TODO_SHOW_AFFIRMATION" >&2
            return 1
            ;;
    esac
}

# Toggle or set visibility of todo box
function todo_toggle_box() {
    local action="${1:-toggle}"
    case "$action" in
        "show")
            TODO_SHOW_TODO_BOX="true"
            echo "Todo box enabled"
            ;;
        "hide")
            TODO_SHOW_TODO_BOX="false"
            echo "Todo box disabled"
            ;;
        "toggle")
            if [[ "$TODO_SHOW_TODO_BOX" == "true" ]]; then
                TODO_SHOW_TODO_BOX="false"
                echo "Todo box disabled"
            else
                TODO_SHOW_TODO_BOX="true"
                echo "Todo box enabled"
            fi
            ;;
        *)
            echo "Usage: todo_toggle_box [show|hide|toggle]" >&2
            echo "Current state: $TODO_SHOW_TODO_BOX" >&2
            return 1
            ;;
    esac
}

# Toggle or set visibility of both affirmation and todo box
function todo_toggle_all() {
    local action="${1:-toggle}"
    case "$action" in
        "show")
            TODO_SHOW_AFFIRMATION="true"
            TODO_SHOW_TODO_BOX="true"
            echo "Affirmations and todo box enabled"
            ;;
        "hide")
            TODO_SHOW_AFFIRMATION="false"
            TODO_SHOW_TODO_BOX="false"
            echo "Affirmations and todo box disabled"
            ;;
        "toggle")
            if [[ "$TODO_SHOW_AFFIRMATION" == "true" && "$TODO_SHOW_TODO_BOX" == "true" ]]; then
                TODO_SHOW_AFFIRMATION="false"
                TODO_SHOW_TODO_BOX="false"
                echo "Affirmations and todo box disabled"
            else
                TODO_SHOW_AFFIRMATION="true"
                TODO_SHOW_TODO_BOX="true"
                echo "Affirmations and todo box enabled"
            fi
            ;;
        *)
            echo "Usage: todo_toggle_all [show|hide|toggle]" >&2
            echo "Current state - Affirmations: $TODO_SHOW_AFFIRMATION, Todo box: $TODO_SHOW_TODO_BOX" >&2
            return 1
            ;;
    esac
}

# Display color reference for choosing color values
# Helper function to display a row of color squares 
function show_color_square_row() {
    local start_n="$1"
    local count="$2" 
    local row_len="${3:-12}"
    
    # Show each color as: normal text number + colored rectangle
    for ((i=0; i<count; i++)); do
        local color=$((start_n + i))
        if [[ $color -gt 255 ]]; then break; fi
        # Normal text number followed by colored rectangle
        printf "%03d\e[48;5;${color}m    \e[0m " "$color"
    done
    echo
}

function todo_colors() {
    local max_colors="${1:-256}"  # Show all colors by default
    local row_len=12
    
    echo "🎨 Color Reference (256-color terminal palette)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    echo "Usage: export TODO_TASK_COLORS=\"num1,num2,num3\" # comma-separated"
    echo "       export TODO_BORDER_COLOR=num              # single number"
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
    IFS=',' read -A current_task_colors <<< "$TODO_TASK_COLORS"
    for i in "${current_task_colors[@]}"; do
        printf "%03d\e[48;5;%dm    \e[0m " "$i" "$i"
    done
    echo
    
    # Show other current colors with same format, nicely aligned
    printf "    Border:     %03d\e[48;5;%dm    \e[0m\n" "$TODO_BORDER_COLOR" "$TODO_BORDER_COLOR"
    printf "    Border BG:  %03d\e[48;5;%dm    \e[0m\n" "$TODO_BORDER_BG_COLOR" "$TODO_BORDER_BG_COLOR"
    printf "    Content BG: %03d\e[48;5;%dm    \e[0m\n" "$TODO_CONTENT_BG_COLOR" "$TODO_CONTENT_BG_COLOR"
    printf "    Text:       %03d\e[48;5;%dm    \e[0m\n" "$TODO_TEXT_COLOR" "$TODO_TEXT_COLOR"
    printf "    Title:      %03d\e[48;5;%dm    \e[0m\n" "$TODO_TITLE_COLOR" "$TODO_TITLE_COLOR"
    printf "    Heart:      %03d\e[48;5;%dm    \e[0m\n" "$TODO_AFFIRMATION_COLOR" "$TODO_AFFIRMATION_COLOR"
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
    echo "${gray}💡 More commands and options: ${cyan}todo_help --full${reset}"
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
    echo "  ${cyan}todo help --colors${reset} [max_colors]           ${gray}Show color reference (default: 72)${reset}"
    echo
    echo "${bold}${green}⚙️  Configuration:${reset}"
    echo "  ${cyan}todo config export${reset} [file] [--colors-only] ${gray}Export configuration${reset}"
    echo "  ${cyan}todo config import${reset} <file> [--colors-only] ${gray}Import configuration${reset}"
    echo "  ${cyan}todo config set${reset} <setting> <value>         ${gray}Change setting${reset}"
    echo "  ${cyan}todo config reset${reset} [--colors-only]         ${gray}Reset to defaults${reset}"
    echo "  ${cyan}todo config preset${reset} <name>                 ${gray}Apply preset (${_TODO_PRESET_LIST})${reset}"
    echo "  ${cyan}todo config save-preset${reset} <name>            ${gray}Save current as preset${reset}"
    echo "  ${cyan}todo config preview${reset} [preset]              ${gray}Preview color swatches${reset}"
    echo "  ${cyan}todo setup${reset}                               ${gray}Interactive configuration wizard${reset}"
    echo
    echo "${bold}${magenta}⚙️  Configuration Variables:${reset} ${gray}(set before sourcing plugin)${reset}"
    echo "  ${white}Display Settings:${reset}"
    echo "    ${cyan}TODO_TITLE${reset}                         ${gray}Box title (default: REMEMBER)${reset}"
    echo "    ${cyan}TODO_BULLET_CHAR${reset}                   ${gray}Task bullet (default: ▪)${reset}"
    echo "    ${cyan}TODO_HEART_CHAR${reset}                    ${gray}Affirmation heart (default: ♥)${reset}"
    echo "    ${cyan}TODO_HEART_POSITION${reset}                ${gray}left|right|both|none (default: left)${reset}"
    echo "    ${cyan}TODO_BOX_WIDTH_FRACTION${reset}            ${gray}Box width fraction (default: 0.5)${reset}"
    echo "    ${cyan}TODO_SHOW_AFFIRMATION${reset}              ${gray}true|false (default: true)${reset}"
    echo "    ${cyan}TODO_SHOW_TODO_BOX${reset}                 ${gray}true|false (default: true)${reset}"
    echo "    ${cyan}TODO_SHOW_HINTS${reset}                    ${gray}true|false (default: true)${reset}"
    echo
    echo "  ${white}Padding/Spacing:${reset}"
    echo "    ${cyan}TODO_PADDING_TOP${reset}                   ${gray}Top padding (default: 0)${reset}"
    echo "    ${cyan}TODO_PADDING_RIGHT${reset}                 ${gray}Right padding (default: 4)${reset}"
    echo "    ${cyan}TODO_PADDING_BOTTOM${reset}                ${gray}Bottom padding (default: 0)${reset}"
    echo "    ${cyan}TODO_PADDING_LEFT${reset}                  ${gray}Left padding (default: 0)${reset}"
    echo
    echo "  ${white}Box Drawing Characters:${reset}"
    echo "    ${cyan}TODO_BOX_TOP_LEFT${reset}                  ${gray}Top left corner (default: ┌)${reset}"
    echo "    ${cyan}TODO_BOX_TOP_RIGHT${reset}                 ${gray}Top right corner (default: ┐)${reset}"
    echo "    ${cyan}TODO_BOX_BOTTOM_LEFT${reset}               ${gray}Bottom left corner (default: └)${reset}"
    echo "    ${cyan}TODO_BOX_BOTTOM_RIGHT${reset}              ${gray}Bottom right corner (default: ┘)${reset}"
    echo "    ${cyan}TODO_BOX_HORIZONTAL${reset}                ${gray}Horizontal line (default: ─)${reset}"
    echo "    ${cyan}TODO_BOX_VERTICAL${reset}                  ${gray}Vertical line (default: │)${reset}"
    echo
    echo "${bold}${yellow}🎨 Color Configuration:${reset} ${gray}(256-color codes 0-255)${reset}"
    echo "    ${cyan}TODO_TASK_COLORS${reset}                   ${gray}Task bullet colors (default: 167,71,136,110,139,73)${reset}"
    echo "    ${cyan}TODO_BORDER_COLOR${reset}                  ${gray}Box border foreground color (default: 240)${reset}"
    echo "    ${cyan}TODO_BORDER_BG_COLOR${reset}               ${gray}Box border background color (default: 235)${reset}"
    echo "    ${cyan}TODO_CONTENT_BG_COLOR${reset}              ${gray}Box content background color (default: 235)${reset}"
    echo "    ${cyan}TODO_TEXT_COLOR${reset}                    ${gray}Task text color (default: 240)${reset}"
    echo "    ${cyan}TODO_TITLE_COLOR${reset}                   ${gray}Box title color (default: 250)${reset}"
    echo "    ${cyan}TODO_AFFIRMATION_COLOR${reset}             ${gray}Affirmation text color (default: 109)${reset}"
    echo
    echo "  ${white}Legacy Compatibility:${reset}"
    echo "    ${cyan}TODO_BACKGROUND_COLOR${reset}              ${gray}Sets both border and content bg if new vars not set${reset}"
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
    echo "  ${gray}# Customization${reset}"
    echo "  ${white}export${reset} TODO_HEART_CHAR=\"💖\"        ${gray}# Use emoji heart${reset}"
    echo "  ${white}export${reset} TODO_PADDING_LEFT=4         ${gray}# Add left padding${reset}"
    echo "  ${white}export${reset} TODO_TASK_COLORS=\"196,46,33,21,129,201\"  ${gray}# Custom task colors${reset}"
    echo "  ${white}export${reset} TODO_BORDER_COLOR=244       ${gray}# Lighter border foreground${reset}"
    echo "  ${white}export${reset} TODO_BORDER_BG_COLOR=233    ${gray}# Dark border background${reset}"
    echo "  ${white}export${reset} TODO_CONTENT_BG_COLOR=234   ${gray}# Content background${reset}"
    echo "  ${white}export${reset} TODO_AFFIRMATION_COLOR=33   ${gray}# Blue affirmations${reset}"
    echo
    echo "  ${gray}# Box style examples${reset}"
    echo "  ${gray}# ASCII style:${reset}"
    echo "  ${white}export${reset} TODO_BOX_TOP_LEFT=\"+\" TODO_BOX_TOP_RIGHT=\"+\""
    echo "  ${white}export${reset} TODO_BOX_BOTTOM_LEFT=\"+\" TODO_BOX_BOTTOM_RIGHT=\"+\""
    echo "  ${white}export${reset} TODO_BOX_HORIZONTAL=\"-\" TODO_BOX_VERTICAL=\"|\"" 
    echo
    echo "  ${gray}# Double-line style:${reset}"
    echo "  ${white}export${reset} TODO_BOX_TOP_LEFT=\"╔\" TODO_BOX_TOP_RIGHT=\"╗\""
    echo "  ${white}export${reset} TODO_BOX_BOTTOM_LEFT=\"╚\" TODO_BOX_BOTTOM_RIGHT=\"╝\""
    echo "  ${white}export${reset} TODO_BOX_HORIZONTAL=\"═\" TODO_BOX_VERTICAL=\"║\""
    echo
    echo "  ${gray}# Rounded corners:${reset}"
    echo "  ${white}export${reset} TODO_BOX_TOP_LEFT=\"╭\" TODO_BOX_TOP_RIGHT=\"╮\""
    echo "  ${white}export${reset} TODO_BOX_BOTTOM_LEFT=\"╰\" TODO_BOX_BOTTOM_RIGHT=\"╯\""
    echo
    echo "  ${gray}# Color separation example:${reset}"
    echo "  ${white}export${reset} TODO_BORDER_COLOR=255 TODO_BORDER_BG_COLOR=196"
    echo "  ${white}export${reset} TODO_CONTENT_BG_COLOR=235  ${gray}# Bright white border on red bg, normal content bg${reset}"
    echo
    echo "${bold}${blue}🔗 Links:${reset}"
    echo "  ${gray}Repository: https://github.com/kindjie/zsh-todo-reminder${reset}"
    echo "  ${gray}Issues:     https://github.com/kindjie/zsh-todo-reminder/issues${reset}"
    echo "  ${gray}Releases:   https://github.com/kindjie/zsh-todo-reminder/releases${reset}"
}

# Export current configuration to file
function todo_config_export() {
    local output_file=""
    local colors_only=""
    
    # Parse arguments
    for arg in "$@"; do
        if [[ "$arg" == "--colors-only" ]]; then
            colors_only="--colors-only"
        else
            output_file="$arg"
        fi
    done
    
    # Create configuration content
    local config_content=""
    
    if [[ "$colors_only" == "--colors-only" ]]; then
        # Export only color-related settings
        config_content+="TODO_TASK_COLORS=\"$TODO_TASK_COLORS\"\n"
        config_content+="TODO_BORDER_COLOR=\"$TODO_BORDER_COLOR\"\n"
        config_content+="TODO_BORDER_BG_COLOR=\"$TODO_BORDER_BG_COLOR\"\n"
        config_content+="TODO_CONTENT_BG_COLOR=\"$TODO_CONTENT_BG_COLOR\"\n"
        config_content+="TODO_TEXT_COLOR=\"$TODO_TEXT_COLOR\"\n"
        config_content+="TODO_TASK_TEXT_COLOR=\"$TODO_TASK_TEXT_COLOR\"\n"
        config_content+="TODO_TITLE_COLOR=\"$TODO_TITLE_COLOR\"\n"
        config_content+="TODO_AFFIRMATION_COLOR=\"$TODO_AFFIRMATION_COLOR\"\n"
        config_content+="TODO_BULLET_COLOR=\"$TODO_BULLET_COLOR\"\n"
    else
        # Export all configuration settings
        config_content+="# Todo Reminder Configuration\n"
        config_content+="# Generated on $(date)\n\n"
        
        # Display settings
        config_content+="TODO_TITLE=\"$TODO_TITLE\"\n"
        config_content+="TODO_HEART_CHAR=\"$TODO_HEART_CHAR\"\n"
        config_content+="TODO_HEART_POSITION=\"$TODO_HEART_POSITION\"\n"
        config_content+="TODO_BULLET_CHAR=\"$TODO_BULLET_CHAR\"\n"
        config_content+="TODO_BOX_WIDTH_FRACTION=\"$TODO_BOX_WIDTH_FRACTION\"\n"
        config_content+="TODO_SHOW_AFFIRMATION=\"$TODO_SHOW_AFFIRMATION\"\n"
        config_content+="TODO_SHOW_TODO_BOX=\"$TODO_SHOW_TODO_BOX\"\n"
        config_content+="TODO_SHOW_HINTS=\"$TODO_SHOW_HINTS\"\n\n"
        
        # Padding settings
        config_content+="TODO_PADDING_TOP=\"$TODO_PADDING_TOP\"\n"
        config_content+="TODO_PADDING_RIGHT=\"$TODO_PADDING_RIGHT\"\n"
        config_content+="TODO_PADDING_BOTTOM=\"$TODO_PADDING_BOTTOM\"\n"
        config_content+="TODO_PADDING_LEFT=\"$TODO_PADDING_LEFT\"\n\n"
        
        # Color settings
        config_content+="TODO_TASK_COLORS=\"$TODO_TASK_COLORS\"\n"
        config_content+="TODO_BORDER_COLOR=\"$TODO_BORDER_COLOR\"\n"
        config_content+="TODO_BORDER_BG_COLOR=\"$TODO_BORDER_BG_COLOR\"\n"
        config_content+="TODO_CONTENT_BG_COLOR=\"$TODO_CONTENT_BG_COLOR\"\n"
        config_content+="TODO_TEXT_COLOR=\"$TODO_TEXT_COLOR\"\n"
        config_content+="TODO_TASK_TEXT_COLOR=\"$TODO_TASK_TEXT_COLOR\"\n"
        config_content+="TODO_TITLE_COLOR=\"$TODO_TITLE_COLOR\"\n"
        config_content+="TODO_AFFIRMATION_COLOR=\"$TODO_AFFIRMATION_COLOR\"\n"
        config_content+="TODO_BULLET_COLOR=\"$TODO_BULLET_COLOR\"\n\n"
        
        # Box drawing characters
        config_content+="TODO_BOX_TOP_LEFT=\"$TODO_BOX_TOP_LEFT\"\n"
        config_content+="TODO_BOX_TOP_RIGHT=\"$TODO_BOX_TOP_RIGHT\"\n"
        config_content+="TODO_BOX_BOTTOM_LEFT=\"$TODO_BOX_BOTTOM_LEFT\"\n"
        config_content+="TODO_BOX_BOTTOM_RIGHT=\"$TODO_BOX_BOTTOM_RIGHT\"\n"
        config_content+="TODO_BOX_HORIZONTAL=\"$TODO_BOX_HORIZONTAL\"\n"
        config_content+="TODO_BOX_VERTICAL=\"$TODO_BOX_VERTICAL\"\n"
    fi
    
    # Write to file or stdout
    if [[ "$output_file" != "" ]]; then
        if ! echo -e "$config_content" > "$output_file"; then
            echo "Error: Could not write to file $output_file" >&2
            return 1
        fi
        echo "Configuration exported to $output_file"
    else
        echo -e "$config_content"
    fi
}

# Import configuration from file
function todo_config_import() {
    local input_file=""
    local colors_only=""
    
    # Parse arguments
    for arg in "$@"; do
        if [[ "$arg" == "--colors-only" ]]; then
            colors_only="--colors-only"
        else
            input_file="$arg"
        fi
    done
    
    if [[ -z "$input_file" ]]; then
        echo "Usage: todo_config_import <file> [--colors-only]" >&2
        return 1
    fi
    
    if [[ ! -f "$input_file" ]]; then
        echo "Error: Configuration file $input_file not found" >&2
        return 1
    fi
    
    # Source the configuration file
    if ! source "$input_file"; then
        echo "Error: Could not source configuration file $input_file" >&2
        return 1
    fi
    
    # Reinitialize color array and validate settings
    TODO_COLORS=(${(@s:,:)TODO_TASK_COLORS})
    
    # Basic validation of imported values
    if [[ ! "$TODO_SHOW_AFFIRMATION" =~ ^(true|false)$ ]]; then
        echo "Warning: Invalid TODO_SHOW_AFFIRMATION value, resetting to true" >&2
        TODO_SHOW_AFFIRMATION="true"
    fi
    
    if [[ ! "$TODO_SHOW_TODO_BOX" =~ ^(true|false)$ ]]; then
        echo "Warning: Invalid TODO_SHOW_TODO_BOX value, resetting to true" >&2
        TODO_SHOW_TODO_BOX="true"
    fi
    
    if [[ ! "$TODO_SHOW_HINTS" =~ ^(true|false)$ ]]; then
        echo "Warning: Invalid TODO_SHOW_HINTS value, resetting to true" >&2
        TODO_SHOW_HINTS="true"
    fi
    
    if [[ "$colors_only" == "--colors-only" ]]; then
        echo "Color configuration imported from $input_file"
    else
        echo "Configuration imported from $input_file"
    fi
}

# Set individual configuration values
function todo_config_set() {
    local setting="$1"
    local value="$2"
    
    if [[ -z "$setting" || -z "$value" ]]; then
        echo "Usage: todo_config_set <setting> <value>" >&2
        echo "Settings: title, heart-char, heart-position, bullet-char, colors, border-color, text-color, padding-left, etc." >&2
        return 1
    fi
    
    case "$setting" in
        "title")
            TODO_TITLE="$value"
            echo "Title set to: $value"
            ;;
        "heart-char")
            TODO_HEART_CHAR="$value"
            echo "Heart character set to: $value"
            ;;
        "heart-position")
            if [[ "$value" =~ ^(left|right|both|none)$ ]]; then
                TODO_HEART_POSITION="$value"
                echo "Heart position set to: $value"
            else
                echo "Error: Heart position must be left, right, both, or none" >&2
                return 1
            fi
            ;;
        "bullet-char")
            TODO_BULLET_CHAR="$value"
            echo "Bullet character set to: $value"
            ;;
        "colors")
            if [[ "$value" =~ ^[0-9]+(,[0-9]+)*$ ]]; then
                TODO_TASK_COLORS="$value"
                TODO_COLORS=(${(@s:,:)TODO_TASK_COLORS})
                echo "Task colors set to: $value"
            else
                echo "Error: Colors must be comma-separated numbers (0-255)" >&2
                return 1
            fi
            ;;
        "border-color")
            if [[ "$value" =~ ^[0-9]+$ ]] && [[ $value -le 255 ]]; then
                TODO_BORDER_COLOR="$value"
                echo "Border color set to: $value"
            else
                echo "Error: Border color must be a number 0-255" >&2
                return 1
            fi
            ;;
        "text-color")
            if [[ "$value" =~ ^[0-9]+$ ]] && [[ $value -le 255 ]]; then
                TODO_TEXT_COLOR="$value"
                echo "Text color set to: $value"
            else
                echo "Error: Text color must be a number 0-255" >&2
                return 1
            fi
            ;;
        "padding-left")
            if [[ "$value" =~ ^[0-9]+$ ]]; then
                TODO_PADDING_LEFT="$value"
                echo "Left padding set to: $value"
            else
                echo "Error: Padding must be a non-negative number" >&2
                return 1
            fi
            ;;
        "box-width")
            if [[ "$value" =~ ^0\.[0-9]+$ ]] || [[ "$value" =~ ^1\.0$ ]]; then
                TODO_BOX_WIDTH_FRACTION="$value"
                echo "Box width fraction set to: $value"
            else
                echo "Error: Box width must be a decimal between 0.0 and 1.0" >&2
                return 1
            fi
            ;;
        *)
            echo "Error: Unknown setting '$setting'" >&2
            echo "Available settings: title, heart-char, heart-position, bullet-char, colors, border-color, text-color, padding-left, box-width" >&2
            return 1
            ;;
    esac
}

# Reset configuration to defaults
function todo_config_reset() {
    local colors_only="$1"
    
    if [[ "$colors_only" == "--colors-only" ]]; then
        # Reset only color settings
        TODO_TASK_COLORS="167,71,136,110,139,73"
        TODO_BORDER_COLOR="240"
        TODO_BORDER_BG_COLOR="235"
        TODO_CONTENT_BG_COLOR="235"
        TODO_TEXT_COLOR="240"
        TODO_TASK_TEXT_COLOR="240"
        TODO_TITLE_COLOR="250"
        TODO_AFFIRMATION_COLOR="109"
        TODO_BULLET_COLOR="39"
        TODO_COLORS=(${(@s:,:)TODO_TASK_COLORS})
        echo "Color configuration reset to defaults"
    else
        # Reset all settings to defaults
        TODO_TITLE="REMEMBER"
        TODO_HEART_CHAR="♥"
        TODO_HEART_POSITION="left"
        TODO_BULLET_CHAR="▪"
        TODO_BOX_WIDTH_FRACTION="0.5"
        TODO_SHOW_AFFIRMATION="true"
        TODO_SHOW_TODO_BOX="true"
        TODO_SHOW_HINTS="true"
        TODO_PADDING_TOP="0"
        TODO_PADDING_RIGHT="4"
        TODO_PADDING_BOTTOM="0"
        TODO_PADDING_LEFT="0"
        TODO_TASK_COLORS="167,71,136,110,139,73"
        TODO_BORDER_COLOR="240"
        TODO_BORDER_BG_COLOR="235"
        TODO_CONTENT_BG_COLOR="235"
        TODO_TEXT_COLOR="240"
        TODO_TASK_TEXT_COLOR="240"
        TODO_TITLE_COLOR="250"
        TODO_AFFIRMATION_COLOR="109"
        TODO_BULLET_COLOR="39"
        TODO_BOX_TOP_LEFT="┌"
        TODO_BOX_TOP_RIGHT="┐"
        TODO_BOX_BOTTOM_LEFT="└"
        TODO_BOX_BOTTOM_RIGHT="┘"
        TODO_BOX_HORIZONTAL="─"
        TODO_BOX_VERTICAL="│"
        TODO_COLORS=(${(@s:,:)TODO_TASK_COLORS})
        echo "Configuration reset to defaults"
    fi
}

# Apply built-in presets
function todo_config_preset() {
    local preset="$1"
    
    if [[ -z "$preset" ]]; then
        echo "Usage: todo_config_preset <preset>" >&2
        echo "Available presets: minimal, colorful, work, dark, monokai, solarized-dark, nord, gruvbox-dark, base16-auto" >&2
        return 1
    fi
    
    case "$preset" in
        "minimal")
            TODO_TITLE="TODO"
            TODO_HEART_CHAR="•"
            TODO_HEART_POSITION="none"
            TODO_BULLET_CHAR="•"
            TODO_TASK_COLORS="250,248,246,244,242,240"
            TODO_BORDER_COLOR="238"
            TODO_TEXT_COLOR="245"
            TODO_TASK_TEXT_COLOR="245"
            TODO_TITLE_COLOR="255"
            TODO_AFFIRMATION_COLOR="250"
            TODO_BULLET_COLOR="250"
            TODO_SHOW_AFFIRMATION="false"
            TODO_PADDING_LEFT="0"
            TODO_PADDING_RIGHT="2"
            TODO_COLORS=(${(@s:,:)TODO_TASK_COLORS})
            echo "Applied minimal preset"
            ;;
        "colorful")
            TODO_TITLE="✨ TASKS ✨"
            TODO_HEART_CHAR="💖"
            TODO_HEART_POSITION="both"
            TODO_BULLET_CHAR="🔸"
            TODO_TASK_COLORS="196,202,208,214,220,226"
            TODO_BORDER_COLOR="201"
            TODO_TEXT_COLOR="255"
            TODO_TASK_TEXT_COLOR="255"
            TODO_TITLE_COLOR="226"
            TODO_AFFIRMATION_COLOR="213"
            TODO_BULLET_COLOR="226"
            TODO_SHOW_AFFIRMATION="true"
            TODO_PADDING_LEFT="1"
            TODO_PADDING_RIGHT="1"
            TODO_COLORS=(${(@s:,:)TODO_TASK_COLORS})
            echo "Applied colorful preset"
            ;;
        "work")
            TODO_TITLE="WORK TASKS"
            TODO_HEART_CHAR="💼"
            TODO_HEART_POSITION="left"
            TODO_BULLET_CHAR="▶"
            TODO_TASK_COLORS="21,33,39,45,51,57"
            TODO_BORDER_COLOR="33"
            TODO_TEXT_COLOR="250"
            TODO_TASK_TEXT_COLOR="250"
            TODO_TITLE_COLOR="39"
            TODO_AFFIRMATION_COLOR="75"
            TODO_BULLET_COLOR="39"
            TODO_SHOW_AFFIRMATION="true"
            TODO_PADDING_LEFT="2"
            TODO_PADDING_RIGHT="2"
            TODO_BOX_WIDTH_FRACTION="0.4"
            TODO_COLORS=(${(@s:,:)TODO_TASK_COLORS})
            echo "Applied work preset"
            ;;
        "dark")
            TODO_TITLE="REMEMBER"
            TODO_HEART_CHAR="♥"
            TODO_HEART_POSITION="left"
            TODO_BULLET_CHAR="▪"
            TODO_TASK_COLORS="124,88,52,94,130,166"
            TODO_BORDER_COLOR="235"
            TODO_BORDER_BG_COLOR="232"
            TODO_CONTENT_BG_COLOR="233"
            TODO_TEXT_COLOR="244"
            TODO_TASK_TEXT_COLOR="244"
            TODO_TITLE_COLOR="255"
            TODO_AFFIRMATION_COLOR="103"
            TODO_BULLET_COLOR="166"
            TODO_SHOW_AFFIRMATION="true"
            TODO_PADDING_LEFT="0"
            TODO_PADDING_RIGHT="4"
            TODO_COLORS=(${(@s:,:)TODO_TASK_COLORS})
            echo "Applied dark preset"
            ;;
        "base16-auto")
            # Auto-detect and apply base16 theme from tinted-shell if available
            _todo_apply_base16_auto
            ;;
        "monokai")
            # Based on base16-monokai color scheme
            TODO_TITLE="CODE"
            TODO_HEART_CHAR="♥"
            TODO_HEART_POSITION="left"
            TODO_BULLET_CHAR="▪"
            TODO_TASK_COLORS="249,115,166,230,141,208"  # base08,09,0A,0D,0B,0E variations
            TODO_BORDER_COLOR="59"        # base03 (comments)
            TODO_BORDER_BG_COLOR="235"    # base01 (lighter bg)
            TODO_CONTENT_BG_COLOR="234"   # base00 (default bg) 
            TODO_TEXT_COLOR="248"         # base05 (default fg)
            TODO_TASK_TEXT_COLOR="248"    # base05
            TODO_TITLE_COLOR="141"        # base0B (green)
            TODO_AFFIRMATION_COLOR="208"  # base09 (orange)
            TODO_BULLET_COLOR="249"       # base08 (red)
            TODO_SHOW_AFFIRMATION="true"
            TODO_COLORS=(${(@s:,:)TODO_TASK_COLORS})
            echo "Applied Monokai-inspired preset"
            ;;
        "solarized-dark")
            # Based on base16-solarized-dark
            TODO_TITLE="FOCUS"
            TODO_HEART_CHAR="☀"
            TODO_HEART_POSITION="left"
            TODO_BULLET_CHAR="•"
            TODO_TASK_COLORS="203,166,136,68,160,125"  # solarized accent colors
            TODO_BORDER_COLOR="240"       # base03
            TODO_BORDER_BG_COLOR="234"    # base01
            TODO_CONTENT_BG_COLOR="233"   # base00
            TODO_TEXT_COLOR="244"         # base05
            TODO_TASK_TEXT_COLOR="244"
            TODO_TITLE_COLOR="136"        # base0A (yellow)
            TODO_AFFIRMATION_COLOR="37"   # base0C (cyan)
            TODO_BULLET_COLOR="166"       # base09 (orange)
            TODO_SHOW_AFFIRMATION="true"
            TODO_COLORS=(${(@s:,:)TODO_TASK_COLORS})
            echo "Applied Solarized Dark preset"
            ;;
        "nord")
            # Based on Nord color palette
            TODO_TITLE="ARCTIC"
            TODO_HEART_CHAR="❄"
            TODO_HEART_POSITION="left" 
            TODO_BULLET_CHAR="▸"
            TODO_TASK_COLORS="131,209,150,116,97,139"  # nord reds,oranges,yellows,blues,purples
            TODO_BORDER_COLOR="59"        # nord3 (comment)
            TODO_BORDER_BG_COLOR="236"    # nord1 (darker bg)
            TODO_CONTENT_BG_COLOR="235"   # nord0 (bg)
            TODO_TEXT_COLOR="188"         # nord4 (light fg)
            TODO_TASK_TEXT_COLOR="188"
            TODO_TITLE_COLOR="150"        # nord14 (green)
            TODO_AFFIRMATION_COLOR="116"  # nord8 (light blue)
            TODO_BULLET_COLOR="131"       # nord11 (red)
            TODO_SHOW_AFFIRMATION="true"
            TODO_COLORS=(${(@s:,:)TODO_TASK_COLORS})
            echo "Applied Nord-inspired preset"
            ;;
        "gruvbox-dark")
            # Based on gruvbox-dark color scheme
            TODO_TITLE="RETRO"
            TODO_HEART_CHAR="♥"
            TODO_HEART_POSITION="left"
            TODO_BULLET_CHAR="●"
            TODO_TASK_COLORS="167,208,214,109,175,142"  # gruvbox accent colors
            TODO_BORDER_COLOR="243"       # gruvbox gray
            TODO_BORDER_BG_COLOR="237"    # gruvbox dark1
            TODO_CONTENT_BG_COLOR="235"   # gruvbox dark0
            TODO_TEXT_COLOR="223"         # gruvbox light1
            TODO_TASK_TEXT_COLOR="223"
            TODO_TITLE_COLOR="214"        # gruvbox yellow
            TODO_AFFIRMATION_COLOR="109"  # gruvbox blue
            TODO_BULLET_COLOR="167"       # gruvbox red
            TODO_SHOW_AFFIRMATION="true"
            TODO_COLORS=(${(@s:,:)TODO_TASK_COLORS})
            echo "Applied Gruvbox Dark preset"
            ;;
        *)
            echo "Error: Unknown preset '$preset'" >&2
            echo "Available presets: minimal, colorful, work, dark, base16-auto, monokai, solarized-dark, nord, gruvbox-dark" >&2
            return 1
            ;;
    esac
}

# Auto-apply base16 theme from tinted-shell environment variables
function _todo_apply_base16_auto() {
    # Check if tinted-shell base16 variables are available
    if [[ -n "$BASE16_COLOR_00_HEX" ]] && [[ "$TINTED_SHELL_ENABLE_BASE16_VARS" == "1" ]]; then
        echo "Detected tinted-shell base16 theme, applying..."
        
        # Convert hex colors to 256-color approximations
        local base00=$(printf "%d" "0x${BASE16_COLOR_00_HEX}")
        local base01=$(printf "%d" "0x${BASE16_COLOR_01_HEX}")
        local base03=$(printf "%d" "0x${BASE16_COLOR_03_HEX}")
        local base05=$(printf "%d" "0x${BASE16_COLOR_05_HEX}")
        local base08=$(printf "%d" "0x${BASE16_COLOR_08_HEX}")
        local base09=$(printf "%d" "0x${BASE16_COLOR_09_HEX}")
        local base0A=$(printf "%d" "0x${BASE16_COLOR_0A_HEX}")
        local base0B=$(printf "%d" "0x${BASE16_COLOR_0B_HEX}")
        local base0C=$(printf "%d" "0x${BASE16_COLOR_0C_HEX}")
        local base0D=$(printf "%d" "0x${BASE16_COLOR_0D_HEX}")
        local base0E=$(printf "%d" "0x${BASE16_COLOR_0E_HEX}")
        
        # Map base16 semantics to todo plugin colors
        TODO_TITLE="BASE16"
        TODO_HEART_CHAR="♥"
        TODO_HEART_POSITION="left"
        TODO_BULLET_CHAR="▪"
        TODO_TASK_COLORS="$(_hex_to_256 $BASE16_COLOR_08_HEX),$(_hex_to_256 $BASE16_COLOR_09_HEX),$(_hex_to_256 $BASE16_COLOR_0A_HEX),$(_hex_to_256 $BASE16_COLOR_0D_HEX),$(_hex_to_256 $BASE16_COLOR_0B_HEX),$(_hex_to_256 $BASE16_COLOR_0E_HEX)"
        TODO_BORDER_COLOR="$(_hex_to_256 $BASE16_COLOR_03_HEX)"        # Comments/invisibles
        TODO_BORDER_BG_COLOR="$(_hex_to_256 $BASE16_COLOR_01_HEX)"     # Lighter background
        TODO_CONTENT_BG_COLOR="$(_hex_to_256 $BASE16_COLOR_00_HEX)"    # Default background
        TODO_TEXT_COLOR="$(_hex_to_256 $BASE16_COLOR_05_HEX)"          # Default foreground
        TODO_TASK_TEXT_COLOR="$(_hex_to_256 $BASE16_COLOR_05_HEX)"
        TODO_TITLE_COLOR="$(_hex_to_256 $BASE16_COLOR_0A_HEX)"         # Yellow (classes)
        TODO_AFFIRMATION_COLOR="$(_hex_to_256 $BASE16_COLOR_0C_HEX)"   # Cyan (support)
        TODO_BULLET_COLOR="$(_hex_to_256 $BASE16_COLOR_08_HEX)"        # Red (variables)
        TODO_SHOW_AFFIRMATION="true"
        TODO_COLORS=(${(@s:,:)TODO_TASK_COLORS})
        echo "Applied base16 theme: ${BASE16_THEME:-unknown}"
        
    elif [[ -n "$BASE24_COLOR_00_HEX" ]] && [[ "$TINTED_SHELL_ENABLE_BASE24_VARS" == "1" ]]; then
        echo "Detected tinted-shell base24 theme, applying..."
        # Use base24 with additional bright colors
        TODO_TASK_COLORS="$(_hex_to_256 $BASE24_COLOR_08_HEX),$(_hex_to_256 $BASE24_COLOR_09_HEX),$(_hex_to_256 $BASE24_COLOR_0A_HEX),$(_hex_to_256 $BASE24_COLOR_0D_HEX),$(_hex_to_256 $BASE24_COLOR_12_HEX),$(_hex_to_256 $BASE24_COLOR_15_HEX)"
        # ... same mappings as base16 but with access to bright colors
        _todo_apply_base16_auto  # Reuse base16 logic for now
        echo "Applied base24 theme with enhanced bright colors"
        
    else
        echo "No tinted-shell theme detected. Enable with:"
        echo "  export TINTED_SHELL_ENABLE_BASE16_VARS=1"
        echo "  # or"
        echo "  export TINTED_SHELL_ENABLE_BASE24_VARS=1"
        echo "Then source a tinted-shell theme script."
        return 1
    fi
}

# Convert hex color to closest 256-color terminal code
function _hex_to_256() {
    local hex="$1"
    # Remove # if present
    hex="${hex#\#}"
    
    # Convert to RGB
    local r=$(printf "%d" "0x${hex:0:2}")
    local g=$(printf "%d" "0x${hex:2:2}")  
    local b=$(printf "%d" "0x${hex:4:2}")
    
    # Simple approximation to 256-color space
    # This is a basic implementation - could be enhanced with better color distance calculation
    if [[ $r -eq $g ]] && [[ $g -eq $b ]]; then
        # Grayscale
        if [[ $r -lt 8 ]]; then
            echo "16"
        elif [[ $r -gt 248 ]]; then
            echo "231"
        else
            echo $((232 + (r - 8) / 10))
        fi
    else
        # Color cube (simplified)
        local r6=$((r * 5 / 255))
        local g6=$((g * 5 / 255))
        local b6=$((b * 5 / 255))
        echo $((16 + 36 * r6 + 6 * g6 + b6))
    fi
}

# Preview color swatches for available presets
function todo_config_preview() {
    local preset="${1:-all}"
    
    echo "🎨 Todo Reminder Preset Preview"
    echo "════════════════════════════════"
    echo
    
    if [[ "$preset" == "all" ]]; then
        local presets=("minimal" "colorful" "work" "dark" "monokai" "solarized-dark" "nord" "gruvbox-dark")
        for p in "${presets[@]}"; do
            _todo_show_preset_swatch "$p"
            echo
        done
        
        # Show tinted-shell status
        echo "🔗 Tinted-Shell Integration:"
        if [[ "$TINTED_SHELL_ENABLE_BASE16_VARS" == "1" ]] && [[ -n "$BASE16_COLOR_00_HEX" ]]; then
            echo "  ✅ base16 theme detected: ${BASE16_THEME:-unknown}"
            echo "  Run: todo config preset base16-auto"
        elif [[ "$TINTED_SHELL_ENABLE_BASE24_VARS" == "1" ]] && [[ -n "$BASE24_COLOR_00_HEX" ]]; then
            echo "  ✅ base24 theme detected"  
            echo "  Run: todo config preset base16-auto"
        else
            echo "  ⚠️  No tinted-shell theme detected"
            echo "  Enable: export TINTED_SHELL_ENABLE_BASE16_VARS=1"
        fi
    else
        _todo_show_preset_swatch "$preset"
    fi
}

# Show color swatch for a specific preset
function _todo_show_preset_swatch() {
    local preset="$1"
    
    # Temporarily apply preset to get colors
    local saved_colors="$TODO_TASK_COLORS"
    local saved_border="$TODO_BORDER_COLOR"
    local saved_title="$TODO_TITLE_COLOR"
    local saved_text="$TODO_TEXT_COLOR"
    
    # Apply preset quietly
    todo_config_preset "$preset" >/dev/null 2>&1
    
    if [[ $? -eq 0 ]]; then
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
        echo "  Text: \e[38;5;${TODO_TEXT_COLOR}m▪ Sample task item\e[0m"
    else
        echo "❌ Unknown preset: $preset"
    fi
    
    # Restore previous colors
    TODO_TASK_COLORS="$saved_colors"
    TODO_BORDER_COLOR="$saved_border"  
    TODO_TITLE_COLOR="$saved_title"
    TODO_TEXT_COLOR="$saved_text"
    TODO_COLORS=(${(@s:,:)TODO_TASK_COLORS})
}

# Save current configuration as a preset file
function todo_config_save_preset() {
    local preset_name="$1"
    
    if [[ -z "$preset_name" ]]; then
        echo "Usage: todo_config_save_preset <name>" >&2
        return 1
    fi
    
    local preset_file="$HOME/.config/todo-reminder-${preset_name}.conf"
    
    # Create config directory if it doesn't exist
    mkdir -p "$(dirname "$preset_file")"
    
    # Export current configuration to preset file
    todo_config_export "$preset_file"
    
    if [[ $? -eq 0 ]]; then
        echo "Preset '$preset_name' saved to $preset_file"
    else
        echo "Error: Could not save preset '$preset_name'" >&2
        return 1
    fi
}

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

# ============================================================================
# Legacy Aliases (Backward Compatibility)
# ============================================================================
# Pure Subcommand Interface
# All functionality accessible through: todo <subcommand>
# Legacy functions kept as internal implementation details
# ============================================================================
