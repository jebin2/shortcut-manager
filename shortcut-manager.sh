#!/bin/bash
#
# A script to create, view, edit, and delete .desktop application shortcuts
# using the 'gum' tool for a user-friendly command-line interface.
#

# --- CONFIGURATION ---
# The primary directory for user-specific shortcuts. New files are always created here.
USER_SHORTCUT_DIR="$HOME/.local/share/applications"
# System-wide directories to search for existing .desktop files.
SYSTEM_SHORTCUT_DIRS=(
    "/usr/share/applications"
    "/usr/local/share/applications"
)
HEADER_COLOR="99"
mkdir -p "$USER_SHORTCUT_DIR"


# --- HELPER FUNCTIONS ---

# Safely updates a key in a .desktop file.
# It will update the key if it exists, or add it if it doesn't.
update_desktop_key() {
    local file_path="$1"
    local key="$2"
    local value="$3"

    local sed_delimiter='|'
    local escaped_value
    escaped_value=$(sed -e 's/\\/\\\\/g' -e "s/${sed_delimiter}/\\${sed_delimiter}/g" <<< "$value")

    if grep -q "^${key}=" "$file_path"; then
        sed -i "s${sed_delimiter}^${key}=.*${sed_delimiter}${key}=${escaped_value}${sed_delimiter}" "$file_path"
    elif [ -n "$value" ]; then
        echo "${key}=${value}" >> "$file_path"
    fi
}


# --- CORE ACTIONS ---

# A unified function to handle both creating a new shortcut and editing an existing one.
# Takes one optional argument: a file path. If empty, it runs in "create" mode.
process_shortcut() {
    local file_path="${1:-}" # Default to empty if no arg
    local is_edit_mode=false

    # --- Initialize variables ---
    local app_name="" app_comment="" app_exec="" app_path="" app_icon=""
    local app_terminal="false" app_no_display="false" app_categories="Utility;"

    # --- Edit Mode Setup ---
    if [ -n "$file_path" ]; then
        is_edit_mode=true
        
        # Handle system files: create a local copy to edit.
        if [[ ! "$file_path" == "$USER_SHORTCUT_DIR"* ]]; then
            local target_path="$USER_SHORTCUT_DIR/$(basename "$file_path")"
            if gum confirm "This is a system-wide shortcut. To edit, a local copy will be created at '$target_path'. Continue?"; then
                cp "$file_path" "$target_path"
                file_path="$target_path" # From now on, work with the new local copy
                gum spin --title "Local copy created for editing." -- sleep 1
            else
                return # User cancelled
            fi
        fi

        # Pre-fill variables with existing values from the file.
        app_name=$(grep "^Name=" "$file_path" | head -1 | cut -d'=' -f2-)
        app_comment=$(grep "^Comment=" "$file_path" | head -1 | cut -d'=' -f2-)
        app_exec=$(grep "^Exec=" "$file_path" | head -1 | cut -d'=' -f2-)
        app_path=$(grep "^Path=" "$file_path" | head -1 | cut -d'=' -f2-)
        app_icon=$(grep "^Icon=" "$file_path" | head -1 | cut -d'=' -f2-)
        app_terminal=$(grep "^Terminal=" "$file_path" | head -1 | cut -d'=' -f2-)
        [ -z "$app_terminal" ] && app_terminal="false"
        app_no_display=$(grep "^NoDisplay=" "$file_path" | head -1 | cut -d'=' -f2-)
        [ -z "$app_no_display" ] && app_no_display="false"
        app_categories=$(grep "^Categories=" "$file_path" | head -1 | cut -d'=' -f2-)
    fi

    # --- Shared UI for previewing ---
    render_preview() {
        clear
        if [ "$is_edit_mode" = true ]; then
            echo -e "\033[1mEditing Shortcut: $(basename "$file_path") (Ctrl+C/Esc to Discard)\033[0m"
        else
            echo -e "\033[1mCreating New Shortcut (Ctrl+C/Esc to Discard)\033[0m"
        fi
        echo

        local other_keys=""
        if [ "$is_edit_mode" = true ]; then
            other_keys=$(grep -v -E "^(\[Desktop Entry\]|Name=|Comment=|Exec=|Path=|Icon=|Terminal=|NoDisplay=|Categories=|Version=|Type=)" "$file_path" | grep .)
        fi

        local preview_content=$( (
            echo "[Desktop Entry]"
            if [ "$is_edit_mode" = true ]; then
                 grep -E "^(Version|Type)=" "$file_path" 2>/dev/null
            else
                echo "Version=1.0"
                echo "Type=Application"
            fi
            echo "Name=$app_name"
            echo "Comment=$app_comment"
            echo "Exec=$app_exec"
            [ -n "$app_path" ] && echo "Path=$app_path"
            [ -n "$app_icon" ] && echo "Icon=$app_icon"
            echo "Terminal=$app_terminal"
            echo "NoDisplay=$app_no_display"
            [ -n "$app_categories" ] && echo "Categories=$app_categories"
            [ -n "$other_keys" ] && echo "$other_keys"
        ) | grep . )

        echo "$preview_content" | bat --style=plain --language=ini --color=always 2>/dev/null | gum style --border double --padding "1 2" --border-foreground "$HEADER_COLOR"
        echo
    }

    # --- Shared Input Gathering Loop ---
    while true; do
        render_preview
        gum style --padding "0 1" --border "hidden" --foreground 245 "Info: The application name shown in menus. (Required)"
        app_name=$(gum input --value "$app_name" --header.foreground "$HEADER_COLOR" --header "Enter the Application Name" --placeholder "e.g., My Awesome App")
        if [ $? -ne 0 ]; then echo "Cancelled."; sleep 1; return; fi

        render_preview
        gum style --padding "0 1" --border "hidden" --foreground 245 "Info: A short description or tooltip for the application."
        app_comment=$(gum input --value "$app_comment" --header.foreground "$HEADER_COLOR" --header "Enter a Comment" --placeholder "e.g., A script for automating tasks")
        if [ $? -ne 0 ]; then echo "Cancelled."; sleep 1; return; fi
        
        render_preview
        gum style --padding "0 1" --border "hidden" --foreground 245 "Info: The full command to run the program. (Required)"
        app_exec=$(gum input --value "$app_exec" --header.foreground "$HEADER_COLOR" --header "Enter the Exec Command" --placeholder "e.g., /usr/bin/firefox")
        if [ $? -ne 0 ]; then echo "Cancelled."; sleep 1; return; fi

        render_preview
        gum style --padding "0 1" --border "hidden" --foreground 245 "Info: The working directory for the command to run in. Optional."
        app_path=$(gum input --value "$app_path" --header.foreground "$HEADER_COLOR" --header "Enter the Working Directory (Path)" --placeholder "e.g., /home/user/myproject")
        if [ $? -ne 0 ]; then echo "Cancelled."; sleep 1; return; fi
        
        render_preview
        gum style --padding "0 1" --border "hidden" --foreground 245 "Info: The full path to the icon file. Optional."
        app_icon=$(gum input --value "$app_icon" --header.foreground "$HEADER_COLOR" --header "Enter the Icon Path" --placeholder "e.g., /usr/share/icons/icon.png")
        if [ $? -ne 0 ]; then echo "Cancelled."; sleep 1; return; fi

        render_preview
        gum style --padding "0 1" --border "hidden" --foreground 245 "Info: Set to 'true' if this is a command-line application."
        app_terminal=$(printf "false\ntrue" | gum choose --selected "$app_terminal" --header.foreground "$HEADER_COLOR" --header "Select Terminal Option")
        if [ $? -ne 0 ]; then echo "Cancelled."; sleep 1; return; fi

        render_preview
        gum style --padding "0 1" --border "hidden" --foreground 245 "Info: Set to 'true' to hide this application from menus."
        app_no_display=$(printf "false\ntrue" | gum choose --selected "$app_no_display" --header.foreground "$HEADER_COLOR" --header "Hide from Menus (NoDisplay)")
        if [ $? -ne 0 ]; then echo "Cancelled."; sleep 1; return; fi

        render_preview
        gum style --padding "0 1" --border "hidden" --foreground 245 "Info: Semicolon-separated list of types (e.g., Utility;Network;)."
        app_categories=$(gum input --value "$app_categories" --header.foreground "$HEADER_COLOR" --header "Enter Categories" --placeholder "e.g., Development;Game;")
        if [ $? -ne 0 ]; then echo "Cancelled."; sleep 1; return; fi

        # --- Final check for required fields ---
        if [ -n "$app_name" ] && [ -n "$app_exec" ]; then
            break # Validation passed
        else
            render_preview
            gum style --foreground="red" "Error: Name and Exec fields cannot be empty. Restarting."
            sleep 1
        fi
    done

    # --- Saving Logic ---
    render_preview # Show the final version before confirming.

    if [ "$is_edit_mode" = true ]; then
        # --- Edit Mode Saving ---
        if gum confirm "Save these changes?"; then
            update_desktop_key "$file_path" "Name" "$app_name"
            update_desktop_key "$file_path" "Comment" "$app_comment"
            update_desktop_key "$file_path" "Exec" "$app_exec"
            update_desktop_key "$file_path" "Path" "$app_path"
            update_desktop_key "$file_path" "Icon" "$app_icon"
            update_desktop_key "$file_path" "Terminal" "$app_terminal"
            update_desktop_key "$file_path" "NoDisplay" "$app_no_display"
            update_desktop_key "$file_path" "Categories" "$app_categories"
            gum spin --title "Saved!" -- sleep 1
        else
            gum spin --title "Changes discarded." -- sleep 1
        fi
    else
        # --- Create Mode Saving ---
        local filename=$(echo "$app_name" | tr -s ' ' '-' | tr '[:upper:]' '[:lower:]').desktop
        local new_file_path="$USER_SHORTCUT_DIR/$filename"
        
        local final_content
        final_content=$( (
            echo "[Desktop Entry]"
            echo "Version=1.0"
            echo "Type=Application"
            echo "Name=$app_name"
            echo "Comment=$app_comment"
            echo "Exec=$app_exec"
            [ -n "$app_path" ] && echo "Path=$app_path"
            [ -n "$app_icon" ] && echo "Icon=$app_icon"
            echo "Terminal=$app_terminal"
            echo "NoDisplay=$app_no_display"
            [ -n "$app_categories" ] && echo "Categories=$app_categories"
        ) | grep . )

        clear
        echo "The following shortcut will be created at: $new_file_path"
        echo
        echo "$final_content" | gum style --border double --padding "1 2"
        echo

        if gum confirm "Create this shortcut?"; then
            echo "$final_content" > "$new_file_path"
            gum spin --title "Shortcut '$app_name' created!" -- sleep 1
        else
            gum spin --title "Cancelled." -- sleep 1
        fi
    fi
}

# Deletes a user shortcut or hides a system shortcut.
delete_or_hide_shortcut() {
    local file_path="$1"
    if [ -z "$file_path" ]; then return 1; fi

    local bname
    bname=$(basename "$file_path")

    # Handle user-local shortcuts (delete them)
    if [[ "$file_path" == "$USER_SHORTCUT_DIR"* ]]; then
        if gum confirm "Permanently delete the user shortcut '$bname'?"; then
            rm -f "$file_path"
            gum spin --title "Shortcut deleted!" -- sleep 1
        else
            gum spin --title "Action cancelled." -- sleep 1
        fi
        return
    fi

    # Handle system-wide shortcuts (hide them by creating a local override)
    local target_path="$USER_SHORTCUT_DIR/$bname"
    if gum confirm "This is a system shortcut. Hide it from menus by creating a local override?"; then
        cp "$file_path" "$target_path"
        update_desktop_key "$target_path" "NoDisplay" "true"
        gum spin --title "Shortcut '$bname' is now hidden." -- sleep 1
    else
        gum spin --title "Action cancelled." -- sleep 1
    fi
}


# --- MENU HANDLERS ---

# Presents a list of all available shortcuts for selection.
select_shortcut() {
    declare -A seen_files
    declare -a all_files

    if [ -d "$USER_SHORTCUT_DIR" ]; then
        while IFS= read -r file; do
            if [[ -f "$file" ]]; then
                all_files+=("$file")
                seen_files["$(basename "$file")"]=1
            fi
        done < <(find "$USER_SHORTCUT_DIR" -maxdepth 1 -name "*.desktop" 2>/dev/null)
    fi

    for dir in "${SYSTEM_SHORTCUT_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            while IFS= read -r file; do
                if [[ -f "$file" ]]; then
                    bname=$(basename "$file")
                    if [[ -z "${seen_files[$bname]}" ]]; then
                        all_files+=("$file")
                        seen_files["$bname"]=1
                    fi
                fi
            done < <(find "$dir" -maxdepth 1 -name "*.desktop" 2>/dev/null)
        fi
    done

    mapfile -t sorted_files < <(printf "%s\n" "${all_files[@]}" | sort)
    
    printf "%s\n" "${sorted_files[@]}" | gum choose --limit=1 --height 25 --header.foreground "$HEADER_COLOR" --header "Select a shortcut (Ctrl+C/Esc to go back)"
}


# --- MAIN EXECUTION LOOP ---
while true; do
    clear
    gum style --padding "0 2" --margin "1" --border "rounded" --border-foreground "$HEADER_COLOR" \
        "Desktop Shortcut Manager"

    ACTION=$(gum choose "New Shortcut" "Edit Shortcut" "Delete / Hide Shortcut" "Quit")
    
    case "$ACTION" in
        "New Shortcut")
            process_shortcut # Call with no arguments for "create" mode
            ;;

        "Edit Shortcut")
            file_to_edit=$(select_shortcut)
            if [ -n "$file_to_edit" ]; then
                process_shortcut "$file_to_edit" # Call with file path for "edit" mode
            fi
            ;;

        "Delete / Hide Shortcut")
            file_to_delete=$(select_shortcut)
            if [ -n "$file_to_delete" ]; then
                delete_or_hide_shortcut "$file_to_delete"
            fi
            ;;

        "Quit" | "") # Also catch Ctrl+C/Esc
            clear
            exit 0
            ;;
    esac
done
