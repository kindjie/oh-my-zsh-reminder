# Configuration variables - can be overridden before sourcing plugin
TODO_SAVE_FILE="${TODO_SAVE_FILE:-$HOME/.todo.sav}"
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

# Padding/margin configuration (in characters)
TODO_PADDING_TOP="${TODO_PADDING_TOP:-0}"                 # Top padding/margin
TODO_PADDING_RIGHT="${TODO_PADDING_RIGHT:-0}"             # Right padding/margin
TODO_PADDING_BOTTOM="${TODO_PADDING_BOTTOM:-0}"           # Bottom padding/margin
TODO_PADDING_LEFT="${TODO_PADDING_LEFT:-0}"               # Left padding/margin

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

# Validate padding configurations are numeric
for padding_var in TODO_PADDING_TOP TODO_PADDING_RIGHT TODO_PADDING_BOTTOM TODO_PADDING_LEFT; do
    local padding_value="${(P)padding_var}"
    if [[ ! "$padding_value" =~ ^[0-9]+$ ]]; then
        echo "Error: $padding_var must be a non-negative integer, got: '$padding_value'" >&2
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

# Color palette: red, green, yellow, blue, magenta, cyan (256-color terminal codes)
TODO_COLORS=(167 71 136 110 139 73)


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
    fi
}

alias todo=todo_add_task

# Remove a completed task by pattern matching
function todo_task_done() {
    local pattern="$1"
    
    if [[ -z "$pattern" ]]; then
        echo "Usage: todo_task_done <pattern>" >&2
        return 1
    fi
    
    load_tasks
    local index=${(M)todo_tasks[(i)${pattern}*]}
    
    if [[ $index -le ${#todo_tasks} ]]; then
        todo_tasks[index]=()
        todo_tasks_colors[index]=()
        todo_save
    else
        echo "No task found matching: $pattern" >&2
        return 1
    fi
}

function _todo_task_done() {
    load_tasks
    if [[ ${#todo_tasks} -gt 0 ]]; then
      compadd $(echo ${TODO_TASKS} | tr '\000' '\n')
    fi
}

# compdef _todo_task_done todo_task_done
alias task_done=todo_task_done

# Wrap text to fit within specified width, handling bullet and text colors separately
# Args: text, max_width, bullet_color, is_title
# Returns: formatted lines with proper bullet prefixes and indentation
function wrap_todo_text() {
    local text="$1"
    local max_width="$2"
    local bullet_color="$3"
    local is_title="$4"
    local gray_color=$'\e[38;5;240m'
    local title_color=$'\e[38;5;250m'
    
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
    local left_width=$((effective_columns - box_width - 4))
    local affirmation_color=$'\e[38;5;109m'
    
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
    local gray_color=$'\e[38;5;240m'
    local bg_color=$'\e[48;5;235m'
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
    
    local left_width=$((COLUMNS - box_width - 4))
    
    # Truncate affirmation if too long (preserve formatting and add ellipsis)
    if [[ ${#affirm_text} -gt $left_width ]]; then
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
        
        # Truncate core text and reformat with hearts
        local truncated_text="${core_text:0:$max_affirm_len}..."
        affirm_text="$(format_affirmation "$truncated_text")"
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
    local top_border="┌$(printf '─%.0s' $(seq 1 $border_chars))┐"
    format_todo_line "" "${gray_color}${bg_color}$top_border${reset_bg}" ""
    
    # Content lines
    for (( i = 1; i <= ${#all_lines}; i++ )); do
        # Strip color codes and calculate display width for proper box alignment
        local clean_line="$(echo "${all_lines[i]}" | sed 's/\x1b\[[0-9;]*m//g')"
        local line_display_width=${(m)#clean_line}
        local padding_needed=$((content_width - line_display_width))
        local padding="$(printf '%*s' $padding_needed '')"
        local content_line="${all_lines[i]}${gray_color}${padding}"
        local box_line="${gray_color}${bg_color}│ ${content_line} │${reset_bg}$fg[default]"
        local left_text=""
        
        # Show placeholder affirmation on middle line
        if [[ $i -eq $middle_line ]]; then
            left_text="$affirm_text"
        fi
        
        format_todo_line "$left_text" "$box_line" ""
    done
    
    # Bottom border (low contrast) - ensure correct width
    local bottom_border="└$(printf '─%.0s' $(seq 1 $border_chars))┘"
    format_todo_line "" "${gray_color}${bg_color}$bottom_border${reset_bg}" ""
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
    fi
    echo
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

# Aliases for convenience
alias todo_affirm=todo_toggle_affirmation
alias todo_box=todo_toggle_box

