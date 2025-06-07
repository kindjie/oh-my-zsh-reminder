TODO_SAVE_TASKS_FILE="$HOME/.todo.sav"
TODO_SAVE_COLOR_FILE="$HOME/.todo_color.sav"
TODO_AFFIRMATION_FILE="${TMPDIR:-/tmp}/todo_affirmation"

# Allow to use colors
colors
typeset -T -x -g TODO_TASKS todo_tasks
typeset -T -x -g TODO_TASKS_COLORS todo_tasks_colors
typeset -a -x -g todo_colors
typeset -i -x -g todo_color_index

function load_tasks() {
# Load previous tasks from saved file
if [[ -e "$TODO_SAVE_TASKS_FILE" ]]; then
    TODO_TASKS="$(cat $TODO_SAVE_TASKS_FILE)"
    if [[ -z "$TODO_TASKS" ]]; then
        todo_tasks=()
        todo_tasks_colors=()
        todo_color_index=1
        return
    fi
    
    # Count actual number of tasks
    local task_count=$(echo "$TODO_TASKS" | tr ':' '\n' | wc -l)
    
    # Load or regenerate colors
    if [[ -e "$TODO_SAVE_COLOR_FILE" ]]; then
        TODO_TASKS_COLORS="$(head -n1 $TODO_SAVE_COLOR_FILE 2>/dev/null)" || TODO_TASKS_COLORS=""
        local index_line="$(tail -n1 $TODO_SAVE_COLOR_FILE 2>/dev/null)" || index_line=""
        
        # Validate color index is numeric
        if [[ "$index_line" =~ ^[0-9]+$ ]]; then
            todo_color_index="$index_line"
        else
            todo_color_index=""
        fi
        
        # Validate color data
        local color_count=0
        if [[ -n "$TODO_TASKS_COLORS" ]]; then
            color_count=$(echo "$TODO_TASKS_COLORS" | tr ':' '\n' | grep -c .)
        fi
        
        # If color count doesn't match task count, regenerate colors
        if [[ $color_count -ne $task_count ]] || [[ -z "$TODO_TASKS_COLORS" ]] || [[ -z "$todo_color_index" ]]; then
            echo "Regenerating corrupted color file..." >&2
            regenerate_colors_for_existing_tasks
        fi
    else
        # Generate colors for existing tasks
        regenerate_colors_for_existing_tasks
    fi
else
    todo_tasks=()
    todo_tasks_colors=()
    todo_color_index=1
fi
}

function regenerate_colors_for_existing_tasks() {
    local task_count=$(echo "$TODO_TASKS" | tr ':' '\n' | wc -l)
    local new_colors=()
    local color_index=1
    
    for (( i = 1; i <= task_count; i++ )); do
        local color_code=$'\e[38;5;'${todo_colors[color_index]}$'m'
        new_colors+=("$color_code")
        (( color_index = (color_index % ${#todo_colors}) + 1 ))
    done
    
    # Save regenerated colors
    local colors_string="$(IFS=:; echo "${new_colors[*]}")"
    echo "$colors_string" > "$TODO_SAVE_COLOR_FILE"
    echo "$color_index" >> "$TODO_SAVE_COLOR_FILE"
    
    # Reload the corrected data
    TODO_TASKS_COLORS="$colors_string"
    todo_color_index="$color_index"
}

todo_colors=(167 71 136 110 139 73)
autoload -U add-zsh-hook
add-zsh-hook precmd todo_display

function todo_add_task {
    if [[ $# -gt 0 ]]; then
      # Source: http://stackoverflow.com/a/8997314/1298019
      task=$(echo -E "$@" | tr '\n' '\000' | sed 's:\x00\x00.*:\n:g' | tr '\000' '\n')
      color=$'\e[38;5;'${todo_colors[${todo_color_index}]}$'m'
	    load_tasks
      todo_tasks+="$task"
      todo_tasks_colors+="$color"
      (( todo_color_index %= ${#todo_colors} ))
      (( todo_color_index += 1 ))
      todo_save
    fi
}

alias todo=todo_add_task

function todo_task_done {
    pattern="$1"
	  load_tasks
    index=${(M)todo_tasks[(i)${pattern}*]}
    todo_tasks[index]=()
    todo_tasks_colors[index]=()
    todo_save
}

function _todo_task_done {
    load_tasks
    if [[ ${#todo_tasks} -gt 0 ]]; then
      compadd $(echo ${TODO_TASKS} | tr ':' '\n')
    fi
  }

# compdef _todo_task_done todo_task_done
alias task_done=todo_task_done

# Wrap text to fit within specified width, handling bullet and text colors separately
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
    local bullet="${bullet_color}▪${gray_color}"
    local remaining_width=$((max_width - 2))  # Account for bullet and space
    
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
    
    local box_width=$((COLUMNS / 2))
    local left_width=$((COLUMNS - box_width - 4))
    local affirmation_color=$'\e[38;5;109m'
    
    # Pad left content to proper width
    printf "${affirmation_color}%-${left_width}s$fg[default]" "$left_content"
    
    # Print right content with box formatting
    if [[ -n "$right_content" ]]; then
        printf "${right_color}%s$fg[default]" "$right_content"
    fi
    
    echo
}

# Draw todo box on right side of terminal
function draw_todo_box() {
    setopt LOCAL_OPTIONS
    unsetopt XTRACE
    local box_width=$((COLUMNS / 2))
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
            affirm_text="❤️ ${cached_affirm}! ❤️"
        else
            affirm_text="❤️ Keep going! ❤️"
        fi
    else
        affirm_text="❤️ Keep going! ❤️"
    fi
    
    # Start background affirmation fetch
    fetch_affirmation_async &|
    
    local left_width=$((COLUMNS - box_width - 4))
    
    # Truncate if too long
    if [[ ${#affirm_text} -gt $left_width ]]; then
        affirm_text="${affirm_text:0:$((left_width-3))}..."
    fi
    
    # Collect all wrapped lines with colors
    local -a all_lines
    
    for (( i = 1; i <= ${#todo_tasks}; i++ )); do
        local is_title="false"
        if [[ "${todo_tasks[i]}" == "REMEMBER" ]]; then
            is_title="true"
        fi
        
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                all_lines+=("$line")
            fi
        done <<< "$(wrap_todo_text "${todo_tasks[i]}" "$content_width" "${todo_tasks_colors[i]}" "$is_title")"
    done
    
    # Calculate middle line for affirmation
    local middle_line=$((${#all_lines} / 2 + 1))
    
    # Top border (low contrast)
    local top_border="┌$(printf '─%.0s' {1..$((box_width-2))})┐"
    format_todo_line "" "${gray_color}${bg_color}$top_border${reset_bg}" ""
    
    # Content lines
    for (( i = 1; i <= ${#all_lines}; i++ )); do
        # Strip color codes to measure actual text width
        local clean_line="$(echo "${all_lines[i]}" | sed 's/\x1b\[[0-9;]*m//g')"
        local padding_needed=$((content_width - ${#clean_line}))
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
    
    # Bottom border (low contrast)
    local bottom_border="└$(printf '─%.0s' {1..$((box_width-2))})┘"
    format_todo_line "" "${gray_color}${bg_color}$bottom_border${reset_bg}" ""
}

# Fetch new affirmation in background
function fetch_affirmation_async {
    local new_affirm
    new_affirm="$(curl -s https://www.affirmations.dev/ 2>/dev/null | jq --raw-output '.affirmation' 2>/dev/null)"
    
    if [[ -n "$new_affirm" && "$new_affirm" != "null" ]]; then
        echo "$new_affirm" > "$TODO_AFFIRMATION_FILE"
    fi
}

function todo_display {
    load_tasks
    if [[ ${#todo_tasks} -gt 0 ]]; then
        draw_todo_box
    fi
    echo
}

function todo_save {
    echo "$TODO_TASKS" > $TODO_SAVE_TASKS_FILE
    echo "$TODO_TASKS_COLORS" > $TODO_SAVE_COLOR_FILE
    echo "$todo_color_index" >> $TODO_SAVE_COLOR_FILE
}

