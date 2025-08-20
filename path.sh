#!/bin/zsh

set -euo pipefail

readonly SCRIPT_NAME="${0:t}"
readonly CURSOR_FG="212"
readonly SELECTED_FG="212"
readonly HEADER_FG="99"

die() {
    echo "Error: $*" >&2
    exit 1
}

check_dependencies() {
    local -a missing_deps=()

    command -v gum >/dev/null 2>&1 || missing_deps+=(gum)
    command -v python3 >/dev/null 2>&1 || missing_deps+=(python3)
    command -v pbcopy >/dev/null 2>&1 || missing_deps+=(pbcopy)
    command -v realpath >/dev/null 2>&1 || missing_deps+=(realpath)

    if (( ${#missing_deps[@]} > 0 )); then
        die "Missing required dependencies: ${missing_deps[*]}"
    fi
}

process_path() {
    local fullpath="$1"
    local -a menu_items=()

    local filename="${fullpath:t}"
    local filename_no_ext="${filename%.*}"
    local extension="${filename##*.}"
    # Handle files with no extension
    if [[ "$extension" == "$filename" ]]; then
        extension=""
    fi
    
    local dirname="${fullpath:h}"
    local escaped_path="${(q)fullpath}"
    local tilde_path="${fullpath/#$HOME/~}"
    local tilde_escaped="\"${(q)tilde_path}\""
    
    local url_encoded
    if ! url_encoded=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$fullpath" 2>/dev/null); then
        die "Failed to URL-encode path"
    fi
    
    # JSON escape the path
    local json_escaped
    if ! json_escaped=$(python3 -c "import json, sys; print(json.dumps(sys.argv[1]))" "$fullpath" 2>/dev/null); then
        json_escaped="\"$fullpath\""
    fi

    local file_url="file://${url_encoded}"
    local md_link="[${filename}](${file_url})"
    local html_link="<a href=\"${file_url}\">${filename}</a>"

    # Get default app name for the file - simplified approach
    local open_in_label="Open in default app"
    if [[ -f "$fullpath" ]]; then
        local ext="${filename##*.}"
        # Common file type to app mappings
        case "$ext" in
            md|markdown|txt|text)
                # Check for common markdown/text editors
                if [[ -d "/Applications/Marked 2.app" || -d "/Applications/Setapp/Marked 2.app" ]]; then
                    open_in_label="Open in Marked 2"
                elif [[ -d "/Applications/iA Writer.app" ]]; then
                    open_in_label="Open in iA Writer"
                elif [[ -d "/Applications/Typora.app" ]]; then
                    open_in_label="Open in Typora"
                else
                    open_in_label="Open in TextEdit"
                fi
                ;;
            png|jpg|jpeg|gif|bmp|tiff|heic|webp)
                open_in_label="Open in Preview"
                ;;
            pdf)
                open_in_label="Open in Preview"
                ;;
            html|htm)
                open_in_label="Open in Safari"
                ;;
            mp4|mov|avi|mkv|m4v)
                open_in_label="Open in QuickTime Player"
                ;;
            mp3|m4a|wav|aiff)
                open_in_label="Open in Music"
                ;;
            sh|bash|zsh)
                if [[ -d "/Applications/Visual Studio Code.app" ]]; then
                    open_in_label="Open in Visual Studio Code"
                elif [[ -d "/Applications/Terminal.app" ]]; then
                    open_in_label="Open in Terminal"
                fi
                ;;
            py)
                if [[ -d "/Applications/Visual Studio Code.app" ]]; then
                    open_in_label="Open in Visual Studio Code"
                elif [[ -d "/Applications/PyCharm.app" ]]; then
                    open_in_label="Open in PyCharm"
                fi
                ;;
            *)
                open_in_label="Open in default app"
                ;;
        esac
    fi

    local -A format_map=(
        ["Filename"]="$filename"
        ["Filename (No extension)"]="$filename_no_ext"
        ["Just the extension"]="$extension"
        ["Parent Directory"]="$dirname"
        ["Absolute Path"]="$fullpath"
        ["Tilde Path"]="$tilde_path"
        ["Tilde Path (Escaped)"]="$tilde_escaped"
        ["URI Encoded"]="$url_encoded"
        ["JSON String"]="$json_escaped"
        ["File URL"]="$file_url"
        ["HTML Link"]="$html_link"
        ["Markdown Link"]="$md_link"
        ["Quick Look"]="__ACTION__:qlmanage -p \"$fullpath\" >/dev/null 2>&1"
        ["Reveal in Finder"]="__ACTION__:open -R \"$fullpath\""
        ["$open_in_label"]="__ACTION__:open \"$fullpath\""
        ["Open in VS Code"]="__ACTION__:code \"$fullpath\""
    )

    # Build labels array in the specified order
    local -a labels=("Filename")
    [[ -n "$extension" ]] && labels+=("Filename (No extension)" "Just the extension")
    labels+=("Parent Directory" "Absolute Path" "Tilde Path" "Tilde Path (Escaped)" "URI Encoded" "JSON String" "File URL" "HTML Link" "Markdown Link")
    
    # Add separator line before action items
    menu_items+=("")
    
    # Add action items
    labels+=("Quick Look" "Reveal in Finder" "$open_in_label" "Open in VS Code")

    for label in "${labels[@]}"; do
        if [[ -z "$label" ]]; then
            menu_items+=("")
        else
            local value="${format_map[$label]}"
            # For action items, show without the __ACTION__ prefix
            if [[ "$value" == __ACTION__:* ]]; then
                menu_items+=("$(printf "%-27s" "$label")")
            else
                menu_items+=("$(printf "%-27s │ %s" "$label" "$value")")
            fi
        fi
    done

    local choice
    if ! choice=$(gum choose \
        --height=20 \
        --header="Choose path format or action (type to filter)" \
        --cursor.foreground="$CURSOR_FG" \
        --selected.foreground="$SELECTED_FG" \
        --header.foreground="$HEADER_FG" \
        --no-show-help \
        --cursor="→ " \
        "${menu_items[@]}"); then
        echo "No selection made." >&2
        return 1
    fi

    # Extract the label (before the separator or for action items, the whole line)
    local selected_label
    if [[ "$choice" == *"│"* ]]; then
        # Has separator, extract label before it
        selected_label="${choice%%│*}"
        # Trim trailing spaces
        selected_label="${selected_label%% }"
        while [[ "${selected_label: -1}" == " " ]]; do
            selected_label="${selected_label%% }"
        done
    else
        # No separator (action item), use whole line after trimming
        selected_label="${choice}"
        # Trim trailing spaces
        while [[ "${selected_label: -1}" == " " ]]; do
            selected_label="${selected_label%% }"
        done
    fi

    # Get the value from the format_map
    local value="${format_map[$selected_label]}"

    # Check if this is an action item
    if [[ "$value" == __ACTION__:* ]]; then
        # Execute the command
        local cmd="${value#__ACTION__:}"
        eval "$cmd"
    else
        # Copy to clipboard
        if ! print -rn -- "$value" | pbcopy; then
            die "Failed to copy to clipboard"
        fi
        echo "✓ Copied to clipboard"
    fi
}

main() {
    check_dependencies

    if (( $# == 0 )); then
        die "No filename or command provided\nUsage: $SCRIPT_NAME <filename_or_command>"
    fi

    local target="$*"
    local resolved_path

    if [[ -e "$target" ]]; then
        resolved_path=$(realpath -- "$target" 2>/dev/null) || die "Failed to resolve path for '$target'"
    elif command -v "$target" >/dev/null 2>&1; then
        local cmd_path
        cmd_path=$(command -v "$target") || die "Failed to locate command '$target'"
        resolved_path=$(realpath -- "$cmd_path" 2>/dev/null) || die "Failed to resolve path for command '$target'"
    else
        die "'$target' not found as a file, directory, or command"
    fi

    process_path "$resolved_path"
}

main "$@"
