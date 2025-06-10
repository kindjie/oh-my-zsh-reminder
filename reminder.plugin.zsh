# Configuration variables - can be overridden before sourcing plugin
TODO_SAVE_FILE="${TODO_SAVE_FILE:-$HOME/.todo.save}"
TODO_AFFIRMATION_FILE="${TODO_AFFIRMATION_FILE:-${TMPDIR:-/tmp}/todo_affirmation}"

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

TODO_TEXT_COLOR="${TODO_TEXT_COLOR:-240}"                         # Task text color
TODO_TITLE_COLOR="${TODO_TITLE_COLOR:-250}"                       # Box title color
TODO_AFFIRMATION_COLOR="${TODO_AFFIRMATION_COLOR:-109}"           # Affirmation text color

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
for color_var in TODO_BORDER_COLOR TODO_BORDER_BG_COLOR TODO_CONTENT_BG_COLOR TODO_TEXT_COLOR TODO_TITLE_COLOR TODO_AFFIRMATION_COLOR; do
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

# Function to calculate actual display width of a character (handles emojis)
function get_char_display_width() {
    local char="$1"

    # Method 1: Try using python if available (most reliable)
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "
import unicodedata
import sys
char = sys.argv[1]
width = 0
for c in char:
    eaw = unicodedata.east_asian_width(c)
    if eaw in ('F', 'W'):  # Full-width or Wide
        width += 2
    elif unicodedata.category(c).startswith('M'):  # Mark (combining)
        width += 0
    else:
        width += 1
print(width)
" "$char" 2>/dev/null && return
    fi

    # Method 2: Try using perl if available
    if command -v perl >/dev/null 2>&1; then
        perl -Mutf8 -E "
use Unicode::EastAsianWidth;
my \$char = shift @ARGV;
my \$width = 0;
for my \$c (split //, \$char) {
    my \$eaw = Unicode::EastAsianWidth::InEastAsianWidth(\$c);
    if (\$eaw eq 'F' || \$eaw eq 'W') {
        \$width += 2;
    } elsif (\$eaw eq 'A') {
        \$width += 1;  # Ambiguous - assume 1 for most terminals
    } else {
        \$width += 1;
    }
}
say \$width;
" "$char" 2>/dev/null && return
    fi

    # Method 3: Simple heuristic fallback
    # Most emojis are in these ranges and are 2 chars wide
    if [[ "$char" =~ [🀀-🿿] ]] || [[ "$char" =~ [⚀-⚿] ]] || [[ "$char" =~ [✀-✿] ]] || \
       [[ "$char" =~ [🎀-🎿] ]] || [[ "$char" =~ [🚀-🚿] ]] || [[ "$char" =~ [🔀-🔿] ]]; then
        echo 2
    else
        # Default to character count for ASCII and basic Unicode
        echo ${#char}
    fi
}

# Function to calculate actual display width of a string (handles emojis)
function get_string_display_width() {
    local string="$1"

    # Method 1: Try using python if available (most reliable)
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "
import unicodedata
import sys
string = sys.argv[1]
width = 0
for c in string:
    eaw = unicodedata.east_asian_width(c)
    if eaw in ('F', 'W'):  # Full-width or Wide
        width += 2
    elif unicodedata.category(c).startswith('M'):  # Mark (combining)
        width += 0
    else:
        width += 1
print(width)
" "$string" 2>/dev/null && return
    fi

    # Method 2: Try using perl if available
    if command -v perl >/dev/null 2>&1; then
        perl -Mutf8 -E "
use Unicode::EastAsianWidth;
my \$string = shift @ARGV;
my \$width = 0;
for my \$c (split //, \$string) {
    my \$eaw = Unicode::EastAsianWidth::InEastAsianWidth(\$c);
    if (\$eaw eq 'F' || \$eaw eq 'W') {
        \$width += 2;
    } elsif (\$eaw eq 'A') {
        \$width += 1;  # Ambiguous - assume 1 for most terminals
    } else {
        \$width += 1;
    }
}
say \$width;
" "$string" 2>/dev/null && return
    fi

    # Method 3: Simple heuristic fallback
    # Count emojis as 2 chars, everything else as 1
    local width=0
    local i=1
    while [[ $i -le ${#string} ]]; do
        local char="${string:$((i-1)):1}"
        if [[ "$char" =~ [🀀-🿿] ]] || [[ "$char" =~ [⚀-⚿] ]] || [[ "$char" =~ [✀-✿] ]] || \
           [[ "$char" =~ [🎀-🎿] ]] || [[ "$char" =~ [🚀-🚿] ]] || [[ "$char" =~ [🔀-🔿] ]]; then
            width=$((width + 2))
        else
            width=$((width + 1))
        fi
        i=$((i + 1))
    done
    echo $width
}

# Initialize color palette from configuration
typeset -a TODO_COLORS
TODO_COLORS=(${(s:,:)TODO_TASK_COLORS})

# Check for first run and show welcome message
TODO_FIRST_RUN_FILE="${TODO_FIRST_RUN_FILE:-$HOME/.todo_first_run}"
if [[ ! -f "$TODO_FIRST_RUN_FILE" ]]; then
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
        echo "${bold}${blue}│${reset} ${green}📚 Quick help:${reset} ${cyan}todo_help${reset}                           ${bold}${blue}│${reset}"
        echo "${bold}${blue}│${reset} ${green}⚙️  Customize:${reset} ${cyan}todo_setup${reset}                          ${bold}${blue}│${reset}"
        echo "${bold}${blue}└─────────────────────────────────────────────────────┘${reset}"
        echo "${gray}💡 Your tasks will appear above the prompt automatically${reset}"
        echo
        
        # Mark first run as complete and remove this hook
        touch "$TODO_FIRST_RUN_FILE"
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

# Load tasks and colors from single save file
# File format: tasks on line 1, colors on line 2, color_index on line 3
function load_tasks() {
    if [[ -e "$TODO_SAVE_FILE" ]]; then
        if ! local file_content="$(cat "$TODO_SAVE_FILE" 2>/dev/null)"; then
            echo "Warning: Could not read todo file $TODO_SAVE_FILE" >&2
            todo_tasks=()
            todo_tasks_colors=()
            todo_color_index=1
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
    else
        todo_tasks=()
        todo_tasks_colors=()
        todo_color_index=1
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

# Add a new task with automatic color assignment
function todo_add_task() {
    if [[ $# -gt 0 ]]; then
        # Source: http://stackoverflow.com/a/8997314/1298019
        local task=$(echo -E "$@" | tr '\n' '\000' | sed 's:\x00\x00.*:\n:g' | tr '\000' '\n')
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
            echo "💡 Your tasks appear above the prompt. Remove with: todo_remove \"$(echo "$task" | cut -c1-10)\""
        fi
    else
        echo "Usage: todo \"task description\""
        echo "Example: todo \"Buy groceries\""
        echo "💡 For more commands: todo_help"
    fi
}

alias todo=todo_add_task

# Remove a completed task by pattern matching
function todo_task_done() {
    local pattern="$1"

    if [[ -z "$pattern" ]]; then
        echo "Usage: todo_task_done <pattern>" >&2
        echo "       todo_remove <pattern>" >&2
        echo "Example: todo_remove \"Buy groceries\"" >&2
        echo "💡 Use tab completion to see available tasks" >&2
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
        echo "❌ No task found matching: $pattern" >&2
        if [[ ${#todo_tasks} -gt 0 ]]; then
            echo "💡 Available tasks:" >&2
            local i=1
            for task in "${todo_tasks[@]}"; do
                echo "   $i. $task" >&2
                ((i++))
            done
            echo "💡 Try: todo_remove \"$(echo "${todo_tasks[1]}" | cut -c1-10)\"" >&2
        else
            echo "💡 No tasks exist. Add one with: todo \"task description\"" >&2
        fi
        return 1
    fi
}

function _todo_task_done() {
    load_tasks
    if [[ ${#todo_tasks} -gt 0 ]]; then
      compadd $(echo ${TODO_TASKS} | tr '\000' '\n')
    fi
}

# Enable tab completion if compdef is available
if command -v compdef >/dev/null 2>&1; then
    compdef _todo_task_done todo_task_done
    compdef _todo_task_done todo_remove
fi
alias task_done=todo_task_done

# Wrap text to fit within specified width, handling bullet and text colors separately
# Args: text, max_width, bullet_color, is_title
# Returns: formatted lines with proper bullet prefixes and indentation
function wrap_todo_text() {
    local text="$1"
    local max_width="$2"
    local bullet_color="$3"
    local is_title="$4"
    local gray_color=$'\e[38;5;'${TODO_TEXT_COLOR}$'m'
    local title_color=$'\e[38;5;'${TODO_TITLE_COLOR}$'m'

    # Check if this is a title (REMEMBER is a special case)
    if [[ "$is_title" == "true" ]]; then
        # This is a title - no prefix, use bullet color for title
        echo "${title_color}${text}${gray_color}"
        return
    fi

    # For regular tasks, we need to handle bullet and text separately
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

# Fetch new affirmation in background (requires curl and jq)
function fetch_affirmation_async() {
    # Check for required dependencies
    if ! command -v curl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
        return 1
    fi

    local new_affirm
    new_affirm="$(curl -s https://www.affirmations.dev/ 2>/dev/null | jq --raw-output '.affirmation' 2>/dev/null)"

    if [[ -n "$new_affirm" && "$new_affirm" != "null" ]]; then
        echo "$new_affirm" > "$TODO_AFFIRMATION_FILE"
    fi
}

# Display todo box with tasks (called before each prompt)
function todo_display() {
    # Skip display if todo box is hidden
    if [[ "$TODO_SHOW_TODO_BOX" == "false" ]]; then
        return
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
        echo "${gray}💡 Lots of tasks? Customize colors: ${cyan}todo_setup${gray} (disable: TODO_SHOW_HINTS=false)${reset}"
    elif [[ ${#todo_tasks} -ge 8 ]]; then
        echo "${gray}💡 Many tasks! Hide display when focused: ${cyan}todo_hide${gray} (disable: TODO_SHOW_HINTS=false)${reset}"
    fi
}

# Save tasks, colors, and color index to single file (3 lines)
function todo_save() {
    if ! {
        echo "$TODO_TASKS"
        echo "$TODO_TASKS_COLORS"
        echo "$todo_color_index"
    } > "$TODO_SAVE_FILE" 2>/dev/null; then
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
    echo "  ${cyan}todo_remove${reset} \"pattern\"         ${gray}Remove completed task (with tab completion)${reset}"
    echo "  ${cyan}todo_hide${reset}                       ${gray}Hide todo display${reset}"
    echo "  ${cyan}todo_show${reset}                       ${gray}Show todo display${reset}"
    echo "  ${cyan}todo_setup${reset}                      ${gray}Interactive customization wizard${reset}"
    echo "  ${cyan}todo_colors${reset}                     ${gray}View color reference for customization${reset}"
    echo
    echo "${bold}${yellow}Quick Start:${reset}"
    echo "  ${gray}todo \"Buy groceries\"     ${cyan}# Add your first task${reset}"
    echo "  ${gray}todo_remove \"Buy\"        ${cyan}# Remove when done (try tab completion!)${reset}"
    echo "  ${gray}todo_setup                ${cyan}# Customize colors and appearance${reset}"
    echo
    echo "${gray}💡 More commands and options: ${cyan}todo_help --more${reset}"
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
    echo "  ${cyan}task_done${reset} \"pattern\"                ${gray}Remove completed task (tab completion)${reset}"
    echo
    echo "${bold}${green}👁️  Display Controls:${reset}"
    echo "  ${cyan}todo_toggle_affirmation${reset} [show|hide|toggle] ${gray}Control affirmations${reset}"
    echo "  ${cyan}todo_toggle_box${reset} [show|hide|toggle]         ${gray}Control todo box${reset}"
    echo "  ${cyan}todo_toggle_all${reset} [show|hide|toggle]         ${gray}Control everything${reset}"
    echo "  ${cyan}todo_affirm${reset}                                ${gray}Alias for toggle_affirmation${reset}"
    echo "  ${cyan}todo_box${reset}                                   ${gray}Alias for toggle_box${reset}"
    echo "  ${cyan}todo_colors${reset} [max_colors]                   ${gray}Show color reference (default: 72)${reset}"
    echo
    echo "${bold}${green}⚙️  Configuration:${reset}"
    echo "  ${cyan}todo_config export${reset} [file] [--colors-only]  ${gray}Export configuration${reset}"
    echo "  ${cyan}todo_config import${reset} <file> [--colors-only]  ${gray}Import configuration${reset}"
    echo "  ${cyan}todo_config set${reset} <setting> <value>          ${gray}Change setting${reset}"
    echo "  ${cyan}todo_config reset${reset} [--colors-only]          ${gray}Reset to defaults${reset}"
    echo "  ${cyan}todo_config preset${reset} <name>                  ${gray}Apply preset (minimal/colorful/work/dark)${reset}"
    echo "  ${cyan}todo_config save-preset${reset} <name>             ${gray}Save current as preset${reset}"
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
    echo "  ${cyan}task_done${reset} \"Buy\"                    ${gray}# Remove task${reset}"
    echo "  ${cyan}todo_affirm${reset} hide                   ${gray}# Hide affirmations${reset}"
    echo "  ${cyan}todo_colors${reset}                        ${gray}# Show color reference${reset}"
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
        config_content+="TODO_TITLE_COLOR=\"$TODO_TITLE_COLOR\"\n"
        config_content+="TODO_AFFIRMATION_COLOR=\"$TODO_AFFIRMATION_COLOR\"\n"
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
        config_content+="TODO_TITLE_COLOR=\"$TODO_TITLE_COLOR\"\n"
        config_content+="TODO_AFFIRMATION_COLOR=\"$TODO_AFFIRMATION_COLOR\"\n\n"
        
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
    TODO_COLORS=(${(s:,:)TODO_TASK_COLORS})
    
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
                TODO_COLORS=(${(s:,:)TODO_TASK_COLORS})
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
        TODO_TITLE_COLOR="250"
        TODO_AFFIRMATION_COLOR="109"
        TODO_COLORS=(${(s:,:)TODO_TASK_COLORS})
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
        TODO_TITLE_COLOR="250"
        TODO_AFFIRMATION_COLOR="109"
        TODO_BOX_TOP_LEFT="┌"
        TODO_BOX_TOP_RIGHT="┐"
        TODO_BOX_BOTTOM_LEFT="└"
        TODO_BOX_BOTTOM_RIGHT="┘"
        TODO_BOX_HORIZONTAL="─"
        TODO_BOX_VERTICAL="│"
        TODO_COLORS=(${(s:,:)TODO_TASK_COLORS})
        echo "Configuration reset to defaults"
    fi
}

# Apply built-in presets
function todo_config_preset() {
    local preset="$1"
    
    if [[ -z "$preset" ]]; then
        echo "Usage: todo_config_preset <preset>" >&2
        echo "Available presets: minimal, colorful, work, dark" >&2
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
            TODO_TITLE_COLOR="255"
            TODO_AFFIRMATION_COLOR="250"
            TODO_SHOW_AFFIRMATION="false"
            TODO_PADDING_LEFT="0"
            TODO_PADDING_RIGHT="2"
            TODO_COLORS=(${(s:,:)TODO_TASK_COLORS})
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
            TODO_TITLE_COLOR="226"
            TODO_AFFIRMATION_COLOR="213"
            TODO_SHOW_AFFIRMATION="true"
            TODO_PADDING_LEFT="1"
            TODO_PADDING_RIGHT="1"
            TODO_COLORS=(${(s:,:)TODO_TASK_COLORS})
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
            TODO_TITLE_COLOR="39"
            TODO_AFFIRMATION_COLOR="75"
            TODO_SHOW_AFFIRMATION="true"
            TODO_PADDING_LEFT="2"
            TODO_PADDING_RIGHT="2"
            TODO_BOX_WIDTH_FRACTION="0.4"
            TODO_COLORS=(${(s:,:)TODO_TASK_COLORS})
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
            TODO_TITLE_COLOR="255"
            TODO_AFFIRMATION_COLOR="103"
            TODO_SHOW_AFFIRMATION="true"
            TODO_PADDING_LEFT="0"
            TODO_PADDING_RIGHT="4"
            TODO_COLORS=(${(s:,:)TODO_TASK_COLORS})
            echo "Applied dark preset"
            ;;
        *)
            echo "Error: Unknown preset '$preset'" >&2
            echo "Available presets: minimal, colorful, work, dark" >&2
            return 1
            ;;
    esac
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

# Helper function to show a preview of the current configuration
function show_wizard_preview() {
    local preview_title="${1:-Preview}"
    
    echo "${fg[bold]}${fg[blue]}═══ $preview_title ═══${reset_color}"
    echo
    
    # Add some sample tasks temporarily for preview
    local had_tasks=false
    if [[ ${#todo_tasks[@]} -eq 0 ]]; then
        todo_tasks=("Review quarterly reports" "Schedule team meeting" "Update documentation")
        todo_tasks_colors=($'\e[38;5;167m' $'\e[38;5;71m' $'\e[38;5;136m')
        todo_color_index=4
        TODO_TASKS="${todo_tasks[1]}"$'\x00'"${todo_tasks[2]}"$'\x00'"${todo_tasks[3]}"
        TODO_TASKS_COLORS="${todo_tasks_colors[1]}"$'\x00'"${todo_tasks_colors[2]}"$'\x00'"${todo_tasks_colors[3]}"
    else
        had_tasks=true
    fi
    
    # Use the actual todo_display function
    todo_display
    
    # Clean up sample tasks if we added them
    if [[ "$had_tasks" == false ]]; then
        todo_tasks=()
        todo_tasks_colors=()
        todo_color_index=1
        TODO_TASKS=""
        TODO_TASKS_COLORS=""
    fi
    
    echo "${fg[green]}user@computer${reset_color}:${fg[cyan]}~/projects${reset_color}$ █"
    echo
}

# Helper function to read a single character without requiring Enter
function read_single_char() {
    local prompt="$1"
    local valid_chars="$2"
    local default_char="$3"
    local char
    
    while true; do
        printf "$prompt" >&2
        
        # Try different methods for single character input
        if command -v read >/dev/null 2>&1; then
            # First try zsh's read -k
            if read -k1 char 2>/dev/null; then
                echo >&2  # New line after character input
            # Fallback to bash read -n
            elif read -n1 char 2>/dev/null; then
                echo >&2  # New line after character input
            # Final fallback to regular read
            else
                read -r char
            fi
        else
            read -r char
        fi
        
        # Handle empty input (Enter pressed immediately)
        if [[ ( -z "$char" || "$char" == $'\n' ) && -n "$default_char" ]]; then
            char="$default_char"
        fi
        
        # Convert to lowercase for comparison
        local char_lower="${char:l}"
        local valid_lower="${valid_chars:l}"
        
        # Check if character is valid (case insensitive)
        if [[ "$valid_lower" == *"$char_lower"* ]]; then
            echo "$char"
            return 0
        else
            echo "   ${fg[red]}Invalid choice. Please select one of: $valid_chars${reset_color}" >&2
        fi
    done
}

# Helper function to show a step header
function show_step_header() {
    local step_num="$1"
    local step_title="$2"
    local step_desc="$3"
    
    echo "${fg[cyan]}═══ Step $step_num: $step_title ═══${reset_color}"
    echo "${fg[gray]}$step_desc${reset_color}"
    echo
}

# Helper function to show color options with visual indicators
function show_color_option() {
    local option_key="$1"
    local option_desc="$2"
    local color_code="$3"
    
    if [[ -n "$color_code" ]]; then
        # Handle comma-separated color lists by showing each color
        local color_samples=""
        local colors=(${(@s:,:)color_code})  # Split on comma
        
        for color in "${colors[@]}"; do
            # Remove any whitespace
            color="${color// /}"
            if [[ "$color" =~ ^[0-9]+$ ]]; then
                # Show normal text number with colored rectangle
                color_samples+="$(printf "%03d" $color)$(printf "\e[48;5;%dm    \e[0m " $color)"
            fi
        done
        
        printf "   ${fg[cyan]}%s)${reset_color} %-20s %s\n" "$option_key" "$option_desc" "$color_samples"
    else
        printf "   ${fg[cyan]}%s)${reset_color} %s\n" "$option_key" "$option_desc"
    fi
}

# Interactive configuration wizard
function todo_config_wizard() {
    # Clear screen and show header
    clear
    echo "${fg[bold]}${fg[blue]}🧙 Todo Reminder Configuration Wizard${reset_color}"
    echo "${fg[blue]}══════════════════════════════════════${reset_color}"
    echo
    echo "This wizard will help you customize your todo reminder display."
    echo "Use single keystrokes to navigate - no need to press Enter!"
    echo
    
    # Show initial preview
    show_wizard_preview "Current Configuration"
    
    # Step 1: Choose a starting point
    show_step_header "1" "Starting Point" "Choose how to begin your customization"
    
    echo "   ${fg[cyan]}a)${reset_color} Start with current settings"
    echo "   ${fg[cyan]}b)${reset_color} Apply a preset first"
    echo "   ${fg[cyan]}c)${reset_color} Reset to defaults first"
    echo
    
    local start_choice=$(read_single_char "   ${fg[yellow]}Your choice [a]: ${reset_color}" "abcABC" "a")
    
    case "${start_choice}" in
        b|B)
            clear
            show_wizard_preview "Preset Selection"
            show_step_header "1b" "Preset Selection" "Choose a preset theme to start with"
            
            show_color_option "1" "minimal  - Clean, simple" "250"
            show_color_option "2" "colorful - Bright, vibrant" "196"
            show_color_option "3" "work     - Professional blue" "33"
            show_color_option "4" "dark     - Dark theme" "235"
            echo
            
            local preset_choice=$(read_single_char "   ${fg[yellow]}Select preset [1]: ${reset_color}" "1234" "1")
            
            case "$preset_choice" in
                1) preset_name="minimal" ;;
                2) preset_name="colorful" ;;
                3) preset_name="work" ;;
                4) preset_name="dark" ;;
            esac
            
            echo "   ${fg[green]}Applying preset '$preset_name'...${reset_color}"
            todo_config preset "$preset_name" >/dev/null 2>&1
            if [[ $? -eq 0 ]]; then
                echo "   ✅ Preset applied successfully"
            else
                echo "   ❌ Invalid preset. Continuing with current settings."
            fi
            sleep 1
            ;;
        c|C)
            echo "   ${fg[green]}Resetting to defaults...${reset_color}"
            todo_config reset >/dev/null 2>&1
            echo "   ✅ Reset to defaults"
            sleep 1
            ;;
        *)
            echo "   ${fg[green]}Keeping current settings${reset_color}"
            sleep 1
            ;;
    esac
    
    # Step 2: Display Components
    clear
    show_wizard_preview "Display Components"
    show_step_header "2" "Display Components" "Choose which elements to show in your terminal"
    
    # Affirmation toggle
    local current_affirmation="${TODO_SHOW_AFFIRMATION:-true}"
    local affirmation_indicator="${fg[green]}♥ You're doing great!${reset_color}"
    [[ "$current_affirmation" == "false" ]] && affirmation_indicator="${fg[gray]}(hidden)${reset_color}"
    
    # Convert true/false to y/n for valid choice
    local affirmation_default="y"
    [[ "$current_affirmation" == "false" ]] && affirmation_default="n"
    
    echo "   Show motivational affirmations? Current: $affirmation_indicator"
    echo "   ${fg[cyan]}y)${reset_color} Yes, show affirmations"
    echo "   ${fg[cyan]}n)${reset_color} No, hide affirmations"
    echo
    
    local affirmation_choice=$(read_single_char "   ${fg[yellow]}Your choice [$affirmation_default]: ${reset_color}" "ynYN" "$affirmation_default")
    case "${affirmation_choice}" in
        n|N) TODO_SHOW_AFFIRMATION="false" ;;
        *) TODO_SHOW_AFFIRMATION="true" ;;
    esac
    
    # Update preview to show affirmation change
    clear
    show_wizard_preview "Display Components (Updated)"
    show_step_header "2" "Display Components" "Choose which elements to show in your terminal"
    
    # Todo box toggle  
    local current_box="${TODO_SHOW_TODO_BOX:-true}"
    local box_indicator="${fg[blue]}┌─ REMEMBER ─┐${reset_color}"
    [[ "$current_box" == "false" ]] && box_indicator="${fg[gray]}(hidden)${reset_color}"
    
    # Convert true/false to y/n for valid choice
    local box_default="y"
    [[ "$current_box" == "false" ]] && box_default="n"
    
    echo "   Show todo box? Current: $box_indicator"
    echo "   ${fg[cyan]}y)${reset_color} Yes, show todo box"
    echo "   ${fg[cyan]}n)${reset_color} No, hide todo box"
    echo
    
    local box_choice=$(read_single_char "   ${fg[yellow]}Your choice [$box_default]: ${reset_color}" "ynYN" "$box_default")
    case "${box_choice}" in
        n|N) TODO_SHOW_TODO_BOX="false" ;;
        *) TODO_SHOW_TODO_BOX="true" ;;
    esac
    
    # Only ask about box-specific settings if box is enabled
    if [[ "$TODO_SHOW_TODO_BOX" == "true" ]]; then
        # Step 3: Box Appearance
        clear
        show_wizard_preview "Box Appearance"
        show_step_header "3" "Box Appearance" "Customize how your todo box looks"
        
        # Title
        echo "   Box title options:"
        echo "   ${fg[cyan]}1)${reset_color} ${fg[yellow]}REMEMBER${reset_color} (default)"
        echo "   ${fg[cyan]}2)${reset_color} ${fg[yellow]}TODO${reset_color}"
        echo "   ${fg[cyan]}3)${reset_color} ${fg[yellow]}TASKS${reset_color}"
        echo "   ${fg[cyan]}4)${reset_color} ${fg[yellow]}NOTES${reset_color}"
        echo "   ${fg[cyan]}c)${reset_color} Custom title"
        echo
        
        local title_choice=$(read_single_char "   ${fg[yellow]}Your choice [1]: ${reset_color}" "1234cC" "1")
        case "$title_choice" in
            1) TODO_TITLE="REMEMBER" ;;
            2) TODO_TITLE="TODO" ;;
            3) TODO_TITLE="TASKS" ;;
            4) TODO_TITLE="NOTES" ;;
            c|C) 
                echo
                printf "   ${fg[yellow]}Enter custom title: ${reset_color}"
                read -r title_input
                if [[ -n "$title_input" ]]; then
                    TODO_TITLE="$title_input"
                    echo "   ${fg[green]}✅ Title set to: $title_input${reset_color}"
                else
                    echo "   ${fg[yellow]}⚠️  No title entered, keeping default${reset_color}"
                fi
                echo
                ;;
        esac
        
        # Update preview to show title change
        clear
        show_wizard_preview "Box Appearance (Updated)"
        show_step_header "3" "Box Appearance" "Customize how your todo box looks"
        
        # Box width
        local current_width_pct=$(echo "$TODO_BOX_WIDTH_FRACTION * 100" | bc 2>/dev/null || echo "50")
        echo "   Box width options:"
        echo "   ${fg[cyan]}1)${reset_color} Small (30%)"
        echo "   ${fg[cyan]}2)${reset_color} Medium (50%) ${fg[gray]}[current: ${current_width_pct}%]${reset_color}"
        echo "   ${fg[cyan]}3)${reset_color} Large (70%)"
        echo "   ${fg[cyan]}4)${reset_color} Full width (90%)"
        echo
        
        local width_choice=$(read_single_char "   ${fg[yellow]}Your choice [2]: ${reset_color}" "1234" "2")
        case "$width_choice" in
            1) TODO_BOX_WIDTH_FRACTION="0.3" ;;
            2) TODO_BOX_WIDTH_FRACTION="0.5" ;;
            3) TODO_BOX_WIDTH_FRACTION="0.7" ;;
            4) TODO_BOX_WIDTH_FRACTION="0.9" ;;
        esac
        
        # Add spacing between sections  
        echo "   ────────────────────────────────────────"
        echo
        
        # Bullet character
        echo "   Task bullet character options:"
        echo "   ${fg[cyan]}1)${reset_color} ${fg[red]}▪${reset_color} (small square)"
        echo "   ${fg[cyan]}2)${reset_color} ${fg[red]}•${reset_color} (bullet)"
        echo "   ${fg[cyan]}3)${reset_color} ${fg[red]}→${reset_color} (arrow)"
        echo "   ${fg[cyan]}4)${reset_color} ${fg[red]}★${reset_color} (star)"
        echo "   ${fg[cyan]}5)${reset_color} ${fg[red]}◆${reset_color} (diamond)"
        echo
        
        local bullet_choice=$(read_single_char "   ${fg[yellow]}Your choice [1]: ${reset_color}" "12345" "1")
        case "$bullet_choice" in
            1) TODO_BULLET_CHAR="▪" ;;
            2) TODO_BULLET_CHAR="•" ;;
            3) TODO_BULLET_CHAR="→" ;;
            4) TODO_BULLET_CHAR="★" ;;
            5) TODO_BULLET_CHAR="◆" ;;
        esac
    fi
    
    # Only ask about affirmation settings if affirmations are enabled
    if [[ "$TODO_SHOW_AFFIRMATION" == "true" ]]; then
        # Step 4: Affirmation Settings
        clear
        show_wizard_preview "Affirmation Settings"
        show_step_header "4" "Affirmation Settings" "Customize your motivational messages"
        
        # Heart character
        echo "   Heart character options:"
        echo "   ${fg[cyan]}1)${reset_color} ${fg[red]}♥${reset_color} (heart)"
        echo "   ${fg[cyan]}2)${reset_color} ${fg[red]}💖${reset_color} (emoji heart)"
        echo "   ${fg[cyan]}3)${reset_color} ${fg[red]}★${reset_color} (star)"
        echo "   ${fg[cyan]}4)${reset_color} ${fg[red]}💡${reset_color} (lightbulb)"
        echo "   ${fg[cyan]}5)${reset_color} ${fg[red]}🌟${reset_color} (star emoji)"
        echo
        
        local heart_choice=$(read_single_char "   ${fg[yellow]}Your choice [1]: ${reset_color}" "12345" "1")
        case "$heart_choice" in
            1) TODO_HEART_CHAR="♥" ;;
            2) TODO_HEART_CHAR="💖" ;;
            3) TODO_HEART_CHAR="★" ;;
            4) TODO_HEART_CHAR="💡" ;;
            5) TODO_HEART_CHAR="🌟" ;;
        esac
        
        # Heart position
        echo "   Heart position options:"
        echo "   ${fg[cyan]}1)${reset_color} ${TODO_HEART_CHAR} You're doing great! (left)"
        echo "   ${fg[cyan]}2)${reset_color} You're doing great! ${TODO_HEART_CHAR} (right)"
        echo "   ${fg[cyan]}3)${reset_color} ${TODO_HEART_CHAR} You're doing great! ${TODO_HEART_CHAR} (both)"
        echo "   ${fg[cyan]}4)${reset_color} You're doing great! (none)"
        echo
        
        local position_choice=$(read_single_char "   ${fg[yellow]}Your choice [1]: ${reset_color}" "1234" "1")
        case "$position_choice" in
            1) TODO_HEART_POSITION="left" ;;
            2) TODO_HEART_POSITION="right" ;;
            3) TODO_HEART_POSITION="both" ;;
            4) TODO_HEART_POSITION="none" ;;
        esac
    fi
    
    # Step 5: Colors (optional)
    clear
    show_wizard_preview "Color Customization"
    show_step_header "5" "Colors" "Customize the color scheme (optional)"
    
    echo "   Customize colors?"
    echo "   ${fg[cyan]}y)${reset_color} Yes, customize colors"
    echo "   ${fg[cyan]}n)${reset_color} No, keep current colors"
    echo
    
    local color_choice=$(read_single_char "   ${fg[yellow]}Your choice [n]: ${reset_color}" "ynYN" "n")
    
    if [[ "$color_choice" =~ ^[yY]$ ]]; then
        # Task colors
        echo "   Task bullet color themes:"
        show_color_option "1" "Warm (red/orange)" "196,208,220,226,227,228"
        show_color_option "2" "Cool (blue/cyan)" "33,39,45,51,87,123"
        show_color_option "3" "Nature (green)" "22,28,34,40,70,106"
        show_color_option "4" "Current colors" "$TODO_TASK_COLORS"
        echo "   ${fg[cyan]}c)${reset_color} Custom colors"
        echo
        
        local task_color_choice=$(read_single_char "   ${fg[yellow]}Your choice [4]: ${reset_color}" "1234cC" "4")
        case "$task_color_choice" in
            1) TODO_TASK_COLORS="196,208,220,226,227,228" ;;
            2) TODO_TASK_COLORS="33,39,45,51,87,123" ;;
            3) TODO_TASK_COLORS="22,28,34,40,70,106" ;;
            4) ;; # Keep current
            c|C)
                echo
                echo "   ${fg[yellow]}📋 Designer Color Palette - Choose from 96 carefully selected colors:${reset_color}"
                echo "   ${fg[gray]}Format: [number][color square] - Enter comma-separated numbers${reset_color}"
                echo
                
                # System Colors (0-15)
                echo "   System Colors (0-15):"
                printf "   "
                for i in {0..7}; do printf "%03d\e[48;5;${i}m    \e[0m " "$i"; done; echo
                printf "   "
                for i in {8..15}; do printf "%03d\e[48;5;${i}m    \e[0m " "$i"; done; echo
                echo
                
                # Essential Reds
                echo "   Essential Reds:"
                printf "   "
                for i in 196 197 203 204 210 211 88 124 160 161 167 168; do printf "%03d\e[48;5;${i}m    \e[0m " "$i"; done; echo
                echo
                
                # Essential Greens  
                echo "   Essential Greens:"
                printf "   "
                for i in 28 34 40 46 76 82 22 29 35 41 47 83; do printf "%03d\e[48;5;${i}m    \e[0m " "$i"; done; echo
                echo
                
                # Essential Blues
                echo "   Essential Blues:"
                printf "   "
                for i in 33 39 45 51 69 75 81 87 25 31 37 67; do printf "%03d\e[48;5;${i}m    \e[0m " "$i"; done; echo
                echo
                
                # Essential Yellows & Oranges
                echo "   Yellows & Oranges:"
                printf "   "
                for i in 220 221 226 227 228 178 214 215 208 209 172 173; do printf "%03d\e[48;5;${i}m    \e[0m " "$i"; done; echo
                echo
                
                # Purples & Magentas
                echo "   Purples & Magentas:"
                printf "   "
                for i in 125 126 127 129 135 141 147 165 171 177 183 189; do printf "%03d\e[48;5;${i}m    \e[0m " "$i"; done; echo
                echo
                
                # Cyans & Teals
                echo "   Cyans & Teals:"
                printf "   "
                for i in 23 30 36 42 48 49 50 51 73 79 80 86; do printf "%03d\e[48;5;${i}m    \e[0m " "$i"; done; echo
                echo
                
                # Grayscale (232-255)
                echo "   Grayscale (232-255):"
                printf "   "
                for i in {232..243}; do printf "%03d\e[48;5;${i}m    \e[0m " "$i"; done; echo
                printf "   "
                for i in {244..255}; do printf "%03d\e[48;5;${i}m    \e[0m " "$i"; done; echo
                echo
                
                echo "   💡 For the full 256-color palette, use: ${fg[cyan]}todo_colors${reset_color}"
                echo
                printf "   ${fg[yellow]}Enter colors (comma-separated, e.g. 196,46,33): ${reset_color}"
                read -r task_colors_input
                if [[ -n "$task_colors_input" && "$task_colors_input" =~ ^[0-9,\ ]+$ ]]; then
                    # Clean up spaces and validate each color
                    task_colors_input="${task_colors_input// /}"
                    TODO_TASK_COLORS="$task_colors_input"
                    echo "   ✅ Colors updated!"
                else
                    echo "   ⚠️  Invalid format. Keeping current colors."
                fi
                echo
                ;;
        esac
        
        # Border color themes
        echo "   Border color themes:"
        show_color_option "1" "Light gray" "250"
        show_color_option "2" "Dark gray" "240"
        show_color_option "3" "Blue accent" "39"
        show_color_option "4" "Current" "$TODO_BORDER_COLOR"
        echo
        
        local border_color_choice=$(read_single_char "   ${fg[yellow]}Your choice [4]: ${reset_color}" "1234" "4")
        case "$border_color_choice" in
            1) TODO_BORDER_COLOR="250" ;;
            2) TODO_BORDER_COLOR="240" ;;
            3) TODO_BORDER_COLOR="39" ;;
            4) ;; # Keep current
        esac
        
        # Background color themes
        echo "   Background color themes:"
        show_color_option "1" "Very dark" "232"
        show_color_option "2" "Dark" "235"
        show_color_option "3" "Medium" "238"
        show_color_option "4" "Current" "$TODO_CONTENT_BG_COLOR"
        echo
        
        local bg_color_choice=$(read_single_char "   ${fg[yellow]}Your choice [4]: ${reset_color}" "1234" "4")
        case "$bg_color_choice" in
            1) TODO_BORDER_BG_COLOR="232"; TODO_CONTENT_BG_COLOR="232" ;;
            2) TODO_BORDER_BG_COLOR="235"; TODO_CONTENT_BG_COLOR="235" ;;
            3) TODO_BORDER_BG_COLOR="238"; TODO_CONTENT_BG_COLOR="238" ;;
            4) ;; # Keep current
        esac
    fi
    
    # Step 6: Layout (optional)
    clear
    show_wizard_preview "Layout & Spacing"
    show_step_header "6" "Layout" "Adjust spacing and positioning (optional)"
    
    echo "   Adjust spacing/padding?"
    echo "   ${fg[cyan]}y)${reset_color} Yes, customize spacing"
    echo "   ${fg[cyan]}n)${reset_color} No, keep current layout"
    echo
    
    local layout_choice=$(read_single_char "   ${fg[yellow]}Your choice [n]: ${reset_color}" "ynYN" "n")
    
    if [[ "$layout_choice" =~ ^[yY]$ ]]; then
        # Left padding
        echo "   Left padding options:"
        echo "   ${fg[cyan]}1)${reset_color} None (0 spaces)"
        echo "   ${fg[cyan]}2)${reset_color} Small (2 spaces)"
        echo "   ${fg[cyan]}3)${reset_color} Medium (4 spaces)"
        echo "   ${fg[cyan]}4)${reset_color} Large (8 spaces)"
        echo
        
        local left_padding_choice=$(read_single_char "   ${fg[yellow]}Your choice [1]: ${reset_color}" "1234" "1")
        case "$left_padding_choice" in
            1) TODO_PADDING_LEFT="0" ;;
            2) TODO_PADDING_LEFT="2" ;;
            3) TODO_PADDING_LEFT="4" ;;
            4) TODO_PADDING_LEFT="8" ;;
        esac
        
        # Top padding
        echo "   Top padding options:"
        echo "   ${fg[cyan]}1)${reset_color} None (0 lines)"
        echo "   ${fg[cyan]}2)${reset_color} Small (1 line)"
        echo "   ${fg[cyan]}3)${reset_color} Medium (2 lines)"
        echo
        
        local top_padding_choice=$(read_single_char "   ${fg[yellow]}Your choice [1]: ${reset_color}" "123" "1")
        case "$top_padding_choice" in
            1) TODO_PADDING_TOP="0" ;;
            2) TODO_PADDING_TOP="1" ;;
            3) TODO_PADDING_TOP="2" ;;
        esac
    fi
    
    # Reinitialize color array after any changes
    TODO_COLORS=(${(s:,:)TODO_TASK_COLORS})
    
    # Step 7: Final Preview & Save
    clear
    show_wizard_preview "Final Configuration"
    show_step_header "7" "Preview & Save" "Review your customized configuration"
    
    echo "   Save this configuration?"
    echo "   ${fg[cyan]}y)${reset_color} Yes, save and apply"
    echo "   ${fg[cyan]}n)${reset_color} No, discard changes"
    echo "   ${fg[cyan]}p)${reset_color} Save as custom preset"
    echo
    
    local save_choice=$(read_single_char "   ${fg[yellow]}Your choice [y]: ${reset_color}" "ynpYNP" "y")
    
    case "${save_choice}" in
        n|N)
            echo "   ${fg[yellow]}Configuration not saved (changes are temporary)${reset_color}"
            ;;
        p|P)
            printf "   ${fg[yellow]}Enter preset name: ${reset_color}"
            read -r preset_name
            if [[ -n "$preset_name" ]]; then
                todo_config save-preset "$preset_name" >/dev/null 2>&1
                if [[ $? -eq 0 ]]; then
                    echo "   ✅ Configuration saved as preset '$preset_name'"
                else
                    echo "   ⚠️  Could not save preset"
                fi
            fi
            echo "   ✅ Configuration applied and will persist across sessions"
            ;;
        *)
            echo "   ✅ Configuration applied and will persist across sessions"
            echo "   💡 To save permanently: ${fg[cyan]}todo_config export ~/.todo-reminder-config.zsh${reset_color}"
            echo "   💡 To load on startup: Add ${fg[cyan]}source ~/.todo-reminder-config.zsh${reset_color} to your .zshrc"
            ;;
    esac
    
    echo
    echo "${fg[bold]}${fg[green]}🎉 Wizard Complete!${reset_color}"
    echo "${fg[blue]}═══════════════════${reset_color}"
    echo "📋 Use ${fg[cyan]}todo \"task\"${reset_color} to add your first task"
    echo "⚙️  Use ${fg[cyan]}todo_config export${reset_color} to back up your settings"
    echo "❓ Use ${fg[cyan]}todo_help${reset_color} for general plugin help"
    echo
}

# Main configuration command dispatcher
function todo_config() {
    local command="$1"
    shift
    
    case "$command" in
        "export")
            todo_config_export "$@"
            ;;
        "import")
            todo_config_import "$@"
            ;;
        "set")
            todo_config_set "$@"
            ;;
        "reset")
            todo_config_reset "$@"
            ;;
        "preset")
            todo_config_preset "$@"
            ;;
        "save-preset")
            todo_config_save_preset "$@"
            ;;
        "wizard")
            todo_config_wizard "$@"
            ;;
        *)
            echo "Usage: todo_config <command> [args]" >&2
            echo "Commands:" >&2
            echo "  export [file] [--colors-only]    Export configuration" >&2
            echo "  import <file> [--colors-only]    Import configuration" >&2
            echo "  set <setting> <value>           Change setting" >&2
            echo "  reset [--colors-only]           Reset to defaults" >&2
            echo "  preset <name>                   Apply built-in preset" >&2
            echo "  save-preset <name>              Save current as preset" >&2
            echo "  wizard                          Interactive setup wizard" >&2
            return 1
            ;;
    esac
}

# Aliases for convenience
alias todo_affirm=todo_toggle_affirmation
alias todo_box=todo_toggle_box

# Beginner-friendly aliases (Layer 1 commands)
alias todo_remove=todo_task_done
alias todo_hide="todo_toggle_all hide"
alias todo_show="todo_toggle_all show"
alias todo_toggle=todo_toggle_all
alias todo_setup=todo_config_wizard

