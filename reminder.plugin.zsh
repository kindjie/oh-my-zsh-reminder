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
if [[ -e "$TODO_SAVE_TASKS_FILE" &&
      -e "$TODO_SAVE_COLOR_FILE" ]]; then
    TODO_TASKS="$(cat $TODO_SAVE_TASKS_FILE)"
    TODO_TASKS_COLORS="$(head -n1 $TODO_SAVE_COLOR_FILE)"
    todo_color_index="$(tail -n1 $TODO_SAVE_COLOR_FILE)"
    if [[ -z "$TODO_TASKS" ]]; then
        todo_tasks[1]=()
        todo_tasks_colors[1]=()
    fi
else
    todo_tasks=()
    todo_tasks_colors=()
    todo_color_index=1
fi
}

todo_colors=(red green yellow blue magenta cyan)
autoload -U add-zsh-hook
add-zsh-hook precmd todo_display

function todo_add_task {
    if [[ $# -gt 0 ]]; then
      # Source: http://stackoverflow.com/a/8997314/1298019
      task=$(echo -E "$@" | tr '\n' '\000' | sed 's:\x00\x00.*:\n:g' | tr '\000' '\n')
      color="${fg[${todo_colors[${todo_color_index}]}]}"
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

# Wrap text to fit within specified width
function wrap_todo_text() {
    local text="$1"
    local max_width="$2"
    local prefixed_text
    
    # Check if this is a title (REMEMBER is a special case)
    if [[ "$text" == "REMEMBER" ]]; then
        # This is a title - no prefix, center it
        prefixed_text="$text"
    else
        # This is a regular task - add bullet prefix
        prefixed_text="- ${text}"
    fi
    
    # Simple word wrapping - split on words that exceed width
    local words=(${=prefixed_text})  # Split into words
    local lines=()
    local current_line=""
    
    for word in "${words[@]}"; do
        if [[ -z "$current_line" ]]; then
            current_line="$word"
        elif [[ $((${#current_line} + ${#word} + 1)) -le $max_width ]]; then
            current_line="$current_line $word"
        else
            lines+=("$current_line")
            current_line="$word"
        fi
    done
    
    if [[ -n "$current_line" ]]; then
        lines+=("$current_line")
    fi
    
    printf '%s\n' "${lines[@]}"
}

# Create a line with todo box on right and affirmation on left
function format_todo_line() {
    local left_content="$1"
    local right_content="$2"
    local right_color="$3"
    
    local box_width=$((COLUMNS / 2))
    local left_width=$((COLUMNS - box_width - 4))
    
    # Pad left content to proper width
    printf "${fg[cyan]}%-${left_width}s$fg[default]" "$left_content"
    
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
    local -a line_colors
    
    for (( i = 1; i <= ${#todo_tasks}; i++ )); do
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                all_lines+=("$line")
                line_colors+=("${todo_tasks_colors[i]}")
            fi
        done <<< "$(wrap_todo_text "${todo_tasks[i]}" "$content_width")"
    done
    
    # Calculate middle line for affirmation
    local middle_line=$((${#all_lines} / 2 + 1))
    
    # Top border (neutral color)
    local top_border="┌$(printf '─%.0s' {1..$((box_width-2))})┐"
    format_todo_line "" "$top_border" "$fg[white]"
    
    # Content lines
    for (( i = 1; i <= ${#all_lines}; i++ )); do
        local content_line="$(printf "%-${content_width}s" "${all_lines[i]}")"
        local box_line="$fg[white]│ ${line_colors[i]}${content_line}$fg[white] │$fg[default]"
        local left_text=""
        
        # Show placeholder affirmation on middle line
        if [[ $i -eq $middle_line ]]; then
            left_text="$affirm_text"
        fi
        
        format_todo_line "$left_text" "$box_line" ""
    done
    
    # Bottom border (neutral color)
    local bottom_border="└$(printf '─%.0s' {1..$((box_width-2))})┘"
    format_todo_line "" "$bottom_border" "$fg[white]"
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

