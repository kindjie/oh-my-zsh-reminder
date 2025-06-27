#!/usr/bin/env zsh

# Wizard Module for zsh-todo-reminder
# Interactive configuration wizard and advanced configuration management

# Ensure this module can be tested independently
if [[ -z "${TODO_COLORS:-}" ]]; then
    # Load core plugin if not already loaded (for testing)
    if [[ -f "${TODO_PLUGIN_DIR:-$(dirname "${(%):-%x}")}/../reminder.plugin.zsh" ]]; then
        source "${TODO_PLUGIN_DIR:-$(dirname "${(%):-%x}")}/../reminder.plugin.zsh"
    fi
fi

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
    
    # Use the actual _todo_display function
    _todo_display
    
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
function show_designer_color_palette() {
    # Show the perfect color picker grid for selection
    echo
    echo "🎨 Designer Color Palette"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    
    # System Colors (0-15) - 8 per row
    echo "System Colors (0-15):"
    show_color_square_row 0 8 8 compact
    show_color_square_row 8 8 8 compact  
    echo
    
    # 216-color cube (6x6x6 RGB combinations)
    echo "216-Color Cube (16-231):"
    local n=16
    for ((n=16; n<=220; n+=12)); do
        show_color_square_row $n 12 12 compact
        # Add spacing every 6 rows for visual grouping
        if [[ $((($n - 16) / 12 % 6)) -eq 5 ]]; then
            echo
        fi
    done
    show_color_square_row 228 4 12 compact  # Last row: 228-231
    echo
    
    # Grayscale (232-255)
    echo "Grayscale Ramp (232-255):"
    show_color_square_row 232 12 12 compact
    show_color_square_row 244 12 12 compact
    echo
}

function show_color_option() {
    local option_key="$1"
    local option_desc="$2"
    local color_code="$3"
    local format="${4:-compact}"  # Default to compact format for wizard
    
    if [[ -n "$color_code" ]]; then
        # Handle comma-separated color lists by showing each color
        local color_samples=""
        local colors=(${(@s:,:)color_code})  # Split on comma
        
        for color in "${colors[@]}"; do
            # Remove any whitespace
            color="${color// /}"
            if [[ "$color" =~ ^[0-9]+$ ]]; then
                # Use shared render function with specified format
                color_samples+="$(render_color_sample "$color" "$format") "
            fi
        done
        
        # Use consistent field width for alignment (40 characters for better spacing)
        printf "   ${fg[cyan]}%s)${reset_color} %-40s %s\n" "$option_key" "$option_desc" "$color_samples"
    else
        printf "   ${fg[cyan]}%s)${reset_color} %s\n" "$option_key" "$option_desc"
    fi
}

# Interactive configuration wizard
function _todo_config_wizard_real() {
    # Ensure colors are properly initialized
    autoload -U colors
    colors
    
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
            
            # Display all available semantic presets with representative color samples
            show_color_option "1" "subtle       - Minimal, muted colors" "250,248,246,244"
            show_color_option "2" "balanced     - Moderate, professional" "167,214,110,109"
            show_color_option "3" "vibrant      - Bright, colorful" "196,208,226,46,51,201"
            show_color_option "4" "loud         - Maximum contrast" "196,208,226,46,51,201,167,214"
            echo
            
            if command -v tinty >/dev/null 2>&1; then
                echo "   💡 Tip: Use 'tinty apply [theme]' for 200+ additional themes"
                echo
            fi
            
            local preset_choice=$(read_single_char "   ${fg[yellow]}Select preset [1]: ${reset_color}" "1234" "1")
            
            # Map selection to preset name using centralized list
            local preset_index=$((preset_choice))
            preset_name="${_TODO_INTERNAL_AVAILABLE_PRESETS[$preset_index]}"
            
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
    
    # Step 5: Color Customization (unified)
    while true; do
        clear
        show_wizard_preview "Color Customization"
        show_step_header "5" "Color Customization" "Customize colors with live preview"
    
        echo "   Current colors:"
        printf "   ${fg[cyan]}1)${reset_color} Title color:       %s " "$TODO_TITLE_COLOR"
        printf "\e[38;5;${TODO_TITLE_COLOR}m████\e[0m\n"
        printf "   ${fg[cyan]}2)${reset_color} Task text color:   %s " "$TODO_TASK_TEXT_COLOR"
        printf "\e[38;5;${TODO_TASK_TEXT_COLOR}m████\e[0m\n"
        printf "   ${fg[cyan]}3)${reset_color} Affirmation color: %s " "$TODO_AFFIRMATION_COLOR"
        printf "\e[38;5;${TODO_AFFIRMATION_COLOR}m████\e[0m\n"
        printf "   ${fg[cyan]}4)${reset_color} Task bullet colors: "
        # Show first few colors from the rotation
        local first_colors=(${(@s:,:)TODO_TASK_COLORS})
        for i in {1..3}; do
            if [[ -n "${first_colors[i]}" ]]; then
                printf "\e[38;5;${first_colors[i]}m▪\e[0m"
            fi
        done
        echo " (rotating)"
        printf "   ${fg[cyan]}5)${reset_color} Border color:      %s " "$TODO_BORDER_COLOR"
        printf "\e[38;5;${TODO_BORDER_COLOR}m████\e[0m\n"
        printf "   ${fg[cyan]}6)${reset_color} Background colors: %s " "$TODO_CONTENT_BG_COLOR"
        printf "\e[38;5;${TODO_CONTENT_BG_COLOR}m████\e[0m\n"
        echo
        echo "   ${fg[cyan]}c)${reset_color} Continue to next step"
        echo
        
        local color_element_choice=$(read_single_char "   ${fg[yellow]}Select [1-6] to customize or 'c' to continue [c]: ${reset_color}" "123456cC" "c")
        
        if [[ "$color_element_choice" =~ ^[cC]$ ]]; then
            # Continue to next step - exit color customization loop
            break
        else
        
        # Handle the selected color element
        case "$color_element_choice" in
            1|2|3)
                # Individual text colors (title, task text, affirmation)
                local element_name
                case "$color_element_choice" in
                    1) element_name="Title" ;;
                    2) element_name="Task text" ;;
                    3) element_name="Affirmation" ;;
                esac
                
                clear
                show_wizard_preview "Color Customization"
                show_step_header "5" "Color Customization" "Customize colors with live preview"
                echo "   ${element_name} color options:"
                show_color_option "1" "Bright white" "255"
                show_color_option "2" "Light gray" "250"
                show_color_option "3" "Medium gray" "245"
                show_color_option "4" "Dark gray" "240"
                show_color_option "5" "Blue accent" "39"
                show_color_option "6" "Green accent" "46"
                echo "   ${fg[cyan]}c)${reset_color} Custom color (full palette)"
                echo
                
                local color_option=$(read_single_char "   ${fg[yellow]}Your choice [2]: ${reset_color}" "123456cC" "2")
                local new_color=""
                
                case "$color_option" in
                    1) new_color="255" ;;
                    2) new_color="250" ;;
                    3) new_color="245" ;;
                    4) new_color="240" ;;
                    5) new_color="39" ;;
                    6) new_color="46" ;;
                    c|C)
                        # Show Designer Palette for custom color selection
                        clear
                        show_wizard_preview "Color Customization"
                        show_step_header "5" "Color Customization" "Choose color for ${element_name:l}"
                        
                        # Use the perfect color picker
                        show_designer_color_palette
                        
                        printf "   ${fg[yellow]}Enter color number (0-255): ${reset_color}"
                        read -r custom_color
                        if [[ "$custom_color" =~ ^[0-9]+$ ]] && [[ "$custom_color" -ge 0 ]] && [[ "$custom_color" -le 255 ]]; then
                            new_color="$custom_color"
                        else
                            continue  # Invalid input, go back to main menu
                        fi
                        ;;
                esac
                
                # Apply the color change
                case "$color_element_choice" in
                    1) TODO_TITLE_COLOR="$new_color" ;;
                    2) TODO_TASK_TEXT_COLOR="$new_color" ;;
                    3) TODO_AFFIRMATION_COLOR="$new_color" ;;
                esac
                ;;
                
            4)
                # Task bullet color themes
                clear
                show_wizard_preview "Color Customization"
                show_step_header "5" "Color Customization" "Customize colors with live preview"
                echo "   Task bullet color themes:"
                show_color_option "1" "Warm (red/orange)" "196,208,220,226,227,228"
                show_color_option "2" "Cool (blue/cyan)" "33,39,45,51,87,123"
                show_color_option "3" "Nature (green)" "22,28,34,40,70,106"
                show_color_option "4" "Current colors" "$TODO_TASK_COLORS"
                echo "   ${fg[cyan]}c)${reset_color} Custom colors"
                echo
                
                local color_option=$(read_single_char "   ${fg[yellow]}Your choice [4]: ${reset_color}" "1234cC" "4")
                
                case "$color_option" in
                    1) TODO_TASK_COLORS="196,208,220,226,227,228" ;;
                    2) TODO_TASK_COLORS="33,39,45,51,87,123" ;;
                    3) TODO_TASK_COLORS="22,28,34,40,70,106" ;;
                    4) ;; # Keep current
                    c|C)
                        # Custom task bullet colors with Designer Palette
                        clear
                        show_wizard_preview "Color Customization"
                        show_step_header "5" "Color Customization" "Choose colors for task bullets"
                        
                        # Use the perfect color picker
                        show_designer_color_palette
                        
                        echo "   ${fg[gray]}Task colors rotate for each task - enter multiple colors separated by commas${reset_color}"
                        echo
                        printf "   ${fg[yellow]}Enter colors (comma-separated, e.g. 196,46,33,226,39,129): ${reset_color}"
                        read -r task_colors_input
                        if [[ -n "$task_colors_input" && "$task_colors_input" =~ ^[0-9,\ ]+$ ]]; then
                            task_colors_input="${task_colors_input// /}"
                            TODO_TASK_COLORS="$task_colors_input"
                        fi
                        ;;
                esac
                TODO_COLORS=(${(@s:,:)TODO_TASK_COLORS})  # Update the colors array
                ;;
                
            5)
                # Border color
                clear
                show_wizard_preview "Color Customization"
                show_step_header "5" "Color Customization" "Customize colors with live preview"
                echo "   Border color options:"
                show_color_option "1" "Light gray" "250"
                show_color_option "2" "Dark gray" "240"
                show_color_option "3" "Blue accent" "39"
                show_color_option "4" "Current" "$TODO_BORDER_COLOR"
                echo "   ${fg[cyan]}c)${reset_color} Custom color (full palette)"
                echo
                
                local border_color_choice=$(read_single_char "   ${fg[yellow]}Your choice [4]: ${reset_color}" "1234cC" "4")
                case "$border_color_choice" in
                    1) TODO_BORDER_COLOR="250" ;;
                    2) TODO_BORDER_COLOR="240" ;;
                    3) TODO_BORDER_COLOR="39" ;;
                    4) ;; # Keep current
                    c|C)
                        # Custom border color with Designer Palette
                        clear
                        show_wizard_preview "Color Customization"
                        show_step_header "5" "Color Customization" "Choose color for border"
                        
                        # Use the perfect color picker
                        show_designer_color_palette
                        
                        printf "   ${fg[yellow]}Enter color number (0-255): ${reset_color}"
                        read -r custom_color
                        if [[ "$custom_color" =~ ^[0-9]+$ ]] && [[ "$custom_color" -ge 0 ]] && [[ "$custom_color" -le 255 ]]; then
                            TODO_BORDER_COLOR="$custom_color"
                        fi
                        ;;
                esac
                ;;
                
            6)
                # Background colors
                clear
                show_wizard_preview "Color Customization"
                show_step_header "5" "Color Customization" "Customize colors with live preview"
                echo "   Background color options:"
                show_color_option "1" "Very dark" "232"
                show_color_option "2" "Dark" "235"
                show_color_option "3" "Medium" "238"
                show_color_option "4" "Current" "$TODO_CONTENT_BG_COLOR"
                echo "   ${fg[cyan]}c)${reset_color} Custom color (full palette)"
                echo
                
                local bg_color_choice=$(read_single_char "   ${fg[yellow]}Your choice [4]: ${reset_color}" "1234cC" "4")
                case "$bg_color_choice" in
                    1) TODO_BORDER_BG_COLOR="232"; TODO_CONTENT_BG_COLOR="232" ;;
                    2) TODO_BORDER_BG_COLOR="235"; TODO_CONTENT_BG_COLOR="235" ;;
                    3) TODO_BORDER_BG_COLOR="238"; TODO_CONTENT_BG_COLOR="238" ;;
                    4) ;; # Keep current
                    c|C)
                        # Custom background color with Designer Palette
                        clear
                        show_wizard_preview "Color Customization"
                        show_step_header "5" "Color Customization" "Choose color for background"
                        
                        # Use the perfect color picker
                        show_designer_color_palette
                        
                        printf "   ${fg[yellow]}Enter color number (0-255): ${reset_color}"
                        read -r custom_color
                        if [[ "$custom_color" =~ ^[0-9]+$ ]] && [[ "$custom_color" -ge 0 ]] && [[ "$custom_color" -le 255 ]]; then
                            TODO_BORDER_BG_COLOR="$custom_color"
                            TODO_CONTENT_BG_COLOR="$custom_color"
                        fi
                        ;;
                esac
                ;;
        esac
        
        # After customizing a color, loop back to color menu
        continue
        fi  # Close the else block
    done  # End color customization loop
    
    # Reinitialize color array after any changes
    TODO_COLORS=(${(@s:,:)TODO_TASK_COLORS})
    
    # Step 6: Layout (optional) - renumbered from step 7
    clear
    show_wizard_preview "Layout & Spacing"
    show_step_header "6" "Layout" "Adjust spacing and positioning (optional)"
    
    echo "   Adjust spacing/padding?"
    echo "   ${fg[cyan]}y)${reset_color} Yes, customize spacing"
    echo "   ${fg[cyan]}n)${reset_color} No, keep current layout"
    echo
    
    local layout_choice=$(read_single_char "   ${fg[yellow]}Your choice [n]: ${reset_color}" "ynYN" "n")
    
    if [[ "$layout_choice" =~ ^[yY]$ ]]; then
        # Padding customization loop
        while true; do
            clear
            show_wizard_preview "Layout & Spacing"
            show_step_header "6" "Layout" "Customize padding and spacing"
            
            echo "   Current padding:"
            echo "   ${fg[cyan]}1)${reset_color} Top padding:    ${TODO_PADDING_TOP:-0} lines"
            echo "   ${fg[cyan]}2)${reset_color} Right padding:  ${TODO_PADDING_RIGHT:-4} spaces"
            echo "   ${fg[cyan]}3)${reset_color} Bottom padding: ${TODO_PADDING_BOTTOM:-0} lines"
            echo "   ${fg[cyan]}4)${reset_color} Left padding:   ${TODO_PADDING_LEFT:-0} spaces"
            echo
            echo "   ${fg[cyan]}c)${reset_color} Continue to next step"
            echo
            
            local padding_choice=$(read_single_char "   ${fg[yellow]}Select [1-4] to customize or 'c' to continue [c]: ${reset_color}" "1234cC" "c")
            
            if [[ "$padding_choice" =~ ^[cC]$ ]]; then
                break
            else
                # Handle padding selection
                case "$padding_choice" in
                    1)
                        echo "   Top padding options:"
                        echo "   ${fg[cyan]}1)${reset_color} None (0 lines)"
                        echo "   ${fg[cyan]}2)${reset_color} Small (1 line)"
                        echo "   ${fg[cyan]}3)${reset_color} Medium (2 lines)"
                        echo "   ${fg[cyan]}4)${reset_color} Large (3 lines)"
                        echo "   ${fg[cyan]}c)${reset_color} Custom number"
                        echo
                        local choice=$(read_single_char "   ${fg[yellow]}Your choice [1]: ${reset_color}" "1234cC" "1")
                        case "$choice" in
                            1) TODO_PADDING_TOP="0" ;;
                            2) TODO_PADDING_TOP="1" ;;
                            3) TODO_PADDING_TOP="2" ;;
                            4) TODO_PADDING_TOP="3" ;;
                            c|C)
                                printf "   ${fg[yellow]}Enter top padding (lines): ${reset_color}"
                                read -r custom_padding
                                if [[ "$custom_padding" =~ ^[0-9]+$ ]] && [[ "$custom_padding" -ge 0 ]] && [[ "$custom_padding" -le 10 ]]; then
                                    TODO_PADDING_TOP="$custom_padding"
                                    echo "   ✅ Top padding set to $custom_padding lines"
                                else
                                    echo "   ⚠️  Invalid input. Please enter a number 0-10"
                                fi
                                sleep 1
                                ;;
                        esac
                        ;;
                    2)
                        echo "   Right padding options:"
                        echo "   ${fg[cyan]}1)${reset_color} None (0 spaces)"
                        echo "   ${fg[cyan]}2)${reset_color} Small (2 spaces)"
                        echo "   ${fg[cyan]}3)${reset_color} Medium (4 spaces)"
                        echo "   ${fg[cyan]}4)${reset_color} Large (8 spaces)"
                        echo "   ${fg[cyan]}c)${reset_color} Custom number"
                        echo
                        local choice=$(read_single_char "   ${fg[yellow]}Your choice [3]: ${reset_color}" "1234cC" "3")
                        case "$choice" in
                            1) TODO_PADDING_RIGHT="0" ;;
                            2) TODO_PADDING_RIGHT="2" ;;
                            3) TODO_PADDING_RIGHT="4" ;;
                            4) TODO_PADDING_RIGHT="8" ;;
                            c|C)
                                printf "   ${fg[yellow]}Enter right padding (spaces): ${reset_color}"
                                read -r custom_padding
                                if [[ "$custom_padding" =~ ^[0-9]+$ ]] && [[ "$custom_padding" -ge 0 ]] && [[ "$custom_padding" -le 20 ]]; then
                                    TODO_PADDING_RIGHT="$custom_padding"
                                    echo "   ✅ Right padding set to $custom_padding spaces"
                                else
                                    echo "   ⚠️  Invalid input. Please enter a number 0-20"
                                fi
                                sleep 1
                                ;;
                        esac
                        ;;
                    3)
                        echo "   Bottom padding options:"
                        echo "   ${fg[cyan]}1)${reset_color} None (0 lines)"
                        echo "   ${fg[cyan]}2)${reset_color} Small (1 line)"
                        echo "   ${fg[cyan]}3)${reset_color} Medium (2 lines)"
                        echo "   ${fg[cyan]}4)${reset_color} Large (3 lines)"
                        echo "   ${fg[cyan]}c)${reset_color} Custom number"
                        echo
                        local choice=$(read_single_char "   ${fg[yellow]}Your choice [1]: ${reset_color}" "1234cC" "1")
                        case "$choice" in
                            1) TODO_PADDING_BOTTOM="0" ;;
                            2) TODO_PADDING_BOTTOM="1" ;;
                            3) TODO_PADDING_BOTTOM="2" ;;
                            4) TODO_PADDING_BOTTOM="3" ;;
                            c|C)
                                printf "   ${fg[yellow]}Enter bottom padding (lines): ${reset_color}"
                                read -r custom_padding
                                if [[ "$custom_padding" =~ ^[0-9]+$ ]] && [[ "$custom_padding" -ge 0 ]] && [[ "$custom_padding" -le 10 ]]; then
                                    TODO_PADDING_BOTTOM="$custom_padding"
                                    echo "   ✅ Bottom padding set to $custom_padding lines"
                                else
                                    echo "   ⚠️  Invalid input. Please enter a number 0-10"
                                fi
                                sleep 1
                                ;;
                        esac
                        ;;
                    4)
                        echo "   Left padding options:"
                        echo "   ${fg[cyan]}1)${reset_color} None (0 spaces)"
                        echo "   ${fg[cyan]}2)${reset_color} Small (2 spaces)"
                        echo "   ${fg[cyan]}3)${reset_color} Medium (4 spaces)"
                        echo "   ${fg[cyan]}4)${reset_color} Large (8 spaces)"
                        echo "   ${fg[cyan]}c)${reset_color} Custom number"
                        echo
                        local choice=$(read_single_char "   ${fg[yellow]}Your choice [1]: ${reset_color}" "1234cC" "1")
                        case "$choice" in
                            1) TODO_PADDING_LEFT="0" ;;
                            2) TODO_PADDING_LEFT="2" ;;
                            3) TODO_PADDING_LEFT="4" ;;
                            4) TODO_PADDING_LEFT="8" ;;
                            c|C)
                                printf "   ${fg[yellow]}Enter left padding (spaces): ${reset_color}"
                                read -r custom_padding
                                if [[ "$custom_padding" =~ ^[0-9]+$ ]] && [[ "$custom_padding" -ge 0 ]] && [[ "$custom_padding" -le 20 ]]; then
                                    TODO_PADDING_LEFT="$custom_padding"
                                    echo "   ✅ Left padding set to $custom_padding spaces"
                                else
                                    echo "   ⚠️  Invalid input. Please enter a number 0-20"
                                fi
                                sleep 1
                                ;;
                        esac
                        ;;
                esac
                # Continue the loop to show updated values
            fi
        done
    fi
    
    # Step 7: Final Preview & Save
    clear
    show_wizard_preview "Final Configuration"
    show_step_header "7" "Preview & Save" "Review your customized configuration"
    
    echo "   Save this configuration?"
    echo "   ${fg[cyan]}y)${reset_color} Yes, save and apply"
    echo "   ${fg[cyan]}n)${reset_color} No, discard changes"
    echo
    
    local save_choice=$(read_single_char "   ${fg[yellow]}Your choice [y]: ${reset_color}" "ynYN" "y")
    
    case "${save_choice}" in
        n|N)
            echo "   ${fg[yellow]}Configuration not saved (changes are temporary)${reset_color}"
            ;;
        *)
            echo "   ✅ Configuration applied and will persist across sessions"
            ;;
    esac
    
    echo
    echo "${fg[bold]}${fg[green]}🎉 Wizard Complete!${reset_color}"
    echo "${fg[blue]}═══════════════════${reset_color}"
}

# Main configuration command dispatcher
# Get current value of a configuration setting
function todo_config_get() {
    local setting="$1"
    
    if [[ -z "$setting" ]]; then
        echo "Usage: todo config get <setting>" >&2
        echo "Available settings:" >&2
        echo "  title, heart-char, heart-position, bullet-char" >&2
        echo "  show-affirmation, show-todo-box, show-hints" >&2
        echo "  padding-top, padding-right, padding-bottom, padding-left" >&2
        echo "  box-width-fraction, box-min-width, box-max-width" >&2
        echo "  colors, border-color, border-bg-color, content-bg-color" >&2
        echo "  task-text-color, title-color, affirmation-color, bullet-color" >&2
        echo "  box-top-left, box-top-right, box-bottom-left, box-bottom-right" >&2
        echo "  box-horizontal, box-vertical, color-mode" >&2
        return 1
    fi
    
    case "$setting" in
        "title")
            echo "$_TODO_INTERNAL_TITLE"
            ;;
        "heart-char")
            echo "$_TODO_INTERNAL_HEART_CHAR"
            ;;
        "heart-position")
            echo "$_TODO_INTERNAL_HEART_POSITION"
            ;;
        "bullet-char")
            echo "$_TODO_INTERNAL_BULLET_CHAR"
            ;;
        "show-affirmation")
            echo "$_TODO_INTERNAL_SHOW_AFFIRMATION"
            ;;
        "show-todo-box")
            echo "$_TODO_INTERNAL_SHOW_TODO_BOX"
            ;;
        "show-hints")
            echo "$_TODO_INTERNAL_SHOW_HINTS"
            ;;
        "padding-top")
            echo "$_TODO_INTERNAL_PADDING_TOP"
            ;;
        "padding-right")
            echo "$_TODO_INTERNAL_PADDING_RIGHT"
            ;;
        "padding-bottom")
            echo "$_TODO_INTERNAL_PADDING_BOTTOM"
            ;;
        "padding-left")
            echo "$_TODO_INTERNAL_PADDING_LEFT"
            ;;
        "box-width-fraction")
            echo "$_TODO_INTERNAL_BOX_WIDTH_FRACTION"
            ;;
        "box-min-width")
            echo "$_TODO_INTERNAL_BOX_MIN_WIDTH"
            ;;
        "box-max-width")
            echo "$_TODO_INTERNAL_BOX_MAX_WIDTH"
            ;;
        "colors"|"task-colors")
            echo "$_TODO_INTERNAL_TASK_COLORS"
            ;;
        "border-color")
            echo "$_TODO_INTERNAL_BORDER_COLOR"
            ;;
        "border-bg-color")
            echo "$_TODO_INTERNAL_BORDER_BG_COLOR"
            ;;
        "content-bg-color")
            echo "$_TODO_INTERNAL_CONTENT_BG_COLOR"
            ;;
        "task-text-color")
            echo "$_TODO_INTERNAL_TASK_TEXT_COLOR"
            ;;
        "title-color")
            echo "$_TODO_INTERNAL_TITLE_COLOR"
            ;;
        "affirmation-color")
            echo "$_TODO_INTERNAL_AFFIRMATION_COLOR"
            ;;
        "bullet-color")
            echo "$_TODO_INTERNAL_BULLET_COLOR"
            ;;
        "box-top-left")
            echo "$_TODO_INTERNAL_BOX_TOP_LEFT"
            ;;
        "box-top-right")
            echo "$_TODO_INTERNAL_BOX_TOP_RIGHT"
            ;;
        "box-bottom-left")
            echo "$_TODO_INTERNAL_BOX_BOTTOM_LEFT"
            ;;
        "box-bottom-right")
            echo "$_TODO_INTERNAL_BOX_BOTTOM_RIGHT"
            ;;
        "box-horizontal")
            echo "$_TODO_INTERNAL_BOX_HORIZONTAL"
            ;;
        "box-vertical")
            echo "$_TODO_INTERNAL_BOX_VERTICAL"
            ;;
        "color-mode")
            echo "$_TODO_INTERNAL_COLOR_MODE"
            ;;
        *)
            echo "Error: Unknown setting '$setting'" >&2
            echo "Use 'todo config get' without arguments to see available settings" >&2
            return 1
            ;;
    esac
}

# List all current configuration settings
function todo_config_list() {
    local format="${1:-table}"
    
    case "$format" in
        "table"|"")
            echo "Current Configuration Settings"
            echo "==============================="
            echo
            echo "Display Settings:"
            printf "  %-20s %s\n" "title" "$_TODO_INTERNAL_TITLE"
            printf "  %-20s %s\n" "heart-char" "$_TODO_INTERNAL_HEART_CHAR"
            printf "  %-20s %s\n" "heart-position" "$_TODO_INTERNAL_HEART_POSITION"
            printf "  %-20s %s\n" "bullet-char" "$_TODO_INTERNAL_BULLET_CHAR"
            echo
            echo "Visibility Settings:"
            printf "  %-20s %s\n" "show-affirmation" "$_TODO_INTERNAL_SHOW_AFFIRMATION"
            printf "  %-20s %s\n" "show-todo-box" "$_TODO_INTERNAL_SHOW_TODO_BOX"
            printf "  %-20s %s\n" "show-hints" "$_TODO_INTERNAL_SHOW_HINTS"
            echo
            echo "Layout Settings:"
            printf "  %-20s %s\n" "padding-top" "$_TODO_INTERNAL_PADDING_TOP"
            printf "  %-20s %s\n" "padding-right" "$_TODO_INTERNAL_PADDING_RIGHT"
            printf "  %-20s %s\n" "padding-bottom" "$_TODO_INTERNAL_PADDING_BOTTOM"
            printf "  %-20s %s\n" "padding-left" "$_TODO_INTERNAL_PADDING_LEFT"
            printf "  %-20s %s\n" "box-width-fraction" "$_TODO_INTERNAL_BOX_WIDTH_FRACTION"
            printf "  %-20s %s\n" "box-min-width" "$_TODO_INTERNAL_BOX_MIN_WIDTH"
            printf "  %-20s %s\n" "box-max-width" "$_TODO_INTERNAL_BOX_MAX_WIDTH"
            echo
            echo "Color Settings:"
            printf "  %-20s %s\n" "color-mode" "$_TODO_INTERNAL_COLOR_MODE"
            printf "  %-20s %s\n" "task-colors" "$_TODO_INTERNAL_TASK_COLORS"
            printf "  %-20s %s\n" "border-color" "$_TODO_INTERNAL_BORDER_COLOR"
            printf "  %-20s %s\n" "border-bg-color" "$_TODO_INTERNAL_BORDER_BG_COLOR"
            printf "  %-20s %s\n" "content-bg-color" "$_TODO_INTERNAL_CONTENT_BG_COLOR"
            printf "  %-20s %s\n" "task-text-color" "$_TODO_INTERNAL_TASK_TEXT_COLOR"
            printf "  %-20s %s\n" "title-color" "$_TODO_INTERNAL_TITLE_COLOR"
            printf "  %-20s %s\n" "affirmation-color" "$_TODO_INTERNAL_AFFIRMATION_COLOR"
            printf "  %-20s %s\n" "bullet-color" "$_TODO_INTERNAL_BULLET_COLOR"
            echo
            echo "Box Characters:"
            printf "  %-20s %s\n" "box-top-left" "$_TODO_INTERNAL_BOX_TOP_LEFT"
            printf "  %-20s %s\n" "box-top-right" "$_TODO_INTERNAL_BOX_TOP_RIGHT"
            printf "  %-20s %s\n" "box-bottom-left" "$_TODO_INTERNAL_BOX_BOTTOM_LEFT"
            printf "  %-20s %s\n" "box-bottom-right" "$_TODO_INTERNAL_BOX_BOTTOM_RIGHT"
            printf "  %-20s %s\n" "box-horizontal" "$_TODO_INTERNAL_BOX_HORIZONTAL"
            printf "  %-20s %s\n" "box-vertical" "$_TODO_INTERNAL_BOX_VERTICAL"
            ;;
        "export")
            echo "# Current Configuration (export format)"
            echo "TODO_TITLE=\"$_TODO_INTERNAL_TITLE\""
            echo "TODO_HEART_CHAR=\"$_TODO_INTERNAL_HEART_CHAR\""
            echo "TODO_HEART_POSITION=\"$_TODO_INTERNAL_HEART_POSITION\""
            echo "TODO_BULLET_CHAR=\"$_TODO_INTERNAL_BULLET_CHAR\""
            echo "TODO_SHOW_AFFIRMATION=\"$_TODO_INTERNAL_SHOW_AFFIRMATION\""
            echo "TODO_SHOW_TODO_BOX=\"$_TODO_INTERNAL_SHOW_TODO_BOX\""
            echo "TODO_SHOW_HINTS=\"$_TODO_INTERNAL_SHOW_HINTS\""
            echo "TODO_PADDING_TOP=\"$_TODO_INTERNAL_PADDING_TOP\""
            echo "TODO_PADDING_RIGHT=\"$_TODO_INTERNAL_PADDING_RIGHT\""
            echo "TODO_PADDING_BOTTOM=\"$_TODO_INTERNAL_PADDING_BOTTOM\""
            echo "TODO_PADDING_LEFT=\"$_TODO_INTERNAL_PADDING_LEFT\""
            echo "TODO_BOX_WIDTH_FRACTION=\"$_TODO_INTERNAL_BOX_WIDTH_FRACTION\""
            echo "TODO_BOX_MIN_WIDTH=\"$_TODO_INTERNAL_BOX_MIN_WIDTH\""
            echo "TODO_BOX_MAX_WIDTH=\"$_TODO_INTERNAL_BOX_MAX_WIDTH\""
            echo "TODO_TASK_COLORS=\"$_TODO_INTERNAL_TASK_COLORS\""
            echo "TODO_BORDER_COLOR=\"$_TODO_INTERNAL_BORDER_COLOR\""
            echo "TODO_BORDER_BG_COLOR=\"$_TODO_INTERNAL_BORDER_BG_COLOR\""
            echo "TODO_CONTENT_BG_COLOR=\"$_TODO_INTERNAL_CONTENT_BG_COLOR\""
            echo "TODO_TASK_TEXT_COLOR=\"$_TODO_INTERNAL_TASK_TEXT_COLOR\""
            echo "TODO_TITLE_COLOR=\"$_TODO_INTERNAL_TITLE_COLOR\""
            echo "TODO_AFFIRMATION_COLOR=\"$_TODO_INTERNAL_AFFIRMATION_COLOR\""
            echo "TODO_BULLET_COLOR=\"$_TODO_INTERNAL_BULLET_COLOR\""
            echo "TODO_BOX_TOP_LEFT=\"$_TODO_INTERNAL_BOX_TOP_LEFT\""
            echo "TODO_BOX_TOP_RIGHT=\"$_TODO_INTERNAL_BOX_TOP_RIGHT\""
            echo "TODO_BOX_BOTTOM_LEFT=\"$_TODO_INTERNAL_BOX_BOTTOM_LEFT\""
            echo "TODO_BOX_BOTTOM_RIGHT=\"$_TODO_INTERNAL_BOX_BOTTOM_RIGHT\""
            echo "TODO_BOX_HORIZONTAL=\"$_TODO_INTERNAL_BOX_HORIZONTAL\""
            echo "TODO_BOX_VERTICAL=\"$_TODO_INTERNAL_BOX_VERTICAL\""
            echo "TODO_COLOR_MODE=\"$_TODO_INTERNAL_COLOR_MODE\""
            ;;
        *)
            echo "Error: Unknown format '$format'" >&2
            echo "Available formats: table, export" >&2
            return 1
            ;;
    esac
}

function _todo_config_real() {
    local command="$1"
    shift
    
    case "$command" in
        "get")
            todo_config_get "$@"
            ;;
        "list"|"show")
            todo_config_list "$@"
            ;;
        "export")
            todo_config_export_config "$@"
            ;;
        "import")
            todo_config_import_config "$@"
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
            todo_config_save_user_preset "$@"
            ;;
        "wizard")
            _todo_config_wizard_real "$@"
            ;;
        *)
            echo "Usage: todo_config <command> [args]" >&2
            echo "Commands:" >&2
            echo "  get <setting>                   Get current value of setting" >&2
            echo "  list                            List all current settings" >&2
            echo "  set <setting> <value>           Change setting" >&2
            echo "  reset [--colors-only]           Reset to defaults" >&2
            echo "  export [file] [--colors-only]   Export configuration" >&2
            echo "  import <file>                   Import configuration" >&2
            echo "  preset <name>                   Apply built-in preset" >&2
            echo "  save-preset <name>              Save current as preset" >&2
            echo "  wizard                          Interactive setup wizard" >&2
            return 1
            ;;
    esac
}