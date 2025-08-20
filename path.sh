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
    
    # Calculate relative path from current directory
    local relative_path
    if command -v realpath >/dev/null 2>&1; then
        relative_path=$(realpath --relative-to="$PWD" "$fullpath" 2>/dev/null) || relative_path="$fullpath"
    else
        relative_path="$fullpath"
    fi

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

    local -A format_map=(
        ["Filename"]="$filename"
        ["Filename (No extension)"]="$filename_no_ext"
        ["Just the extension"]="$extension"
        ["Parent Directory"]="$dirname"
        ["Relative Path"]="$relative_path"
        ["Absolute Path"]="$fullpath"
        ["Absolute Path (Escaped)"]="\"$escaped_path\""
        ["Tilde Path"]="$tilde_path"
        ["Tilde Path (Escaped)"]="\"${(q)tilde_path}\""
        ["URI Encoded"]="$url_encoded"
        ["JSON String"]="$json_escaped"
        ["File URL"]="$file_url"
        ["HTML Link"]="$html_link"
        ["Markdown Link"]="$md_link"
        ["Reveal in Finder"]="open -R \"$fullpath\""
        ["Open with default app"]="open \"$fullpath\""
        ["Open in VS Code"]="code \"$fullpath\""
    )

    # Build labels array in the specified order
    local -a labels=("Filename")
    [[ -n "$extension" ]] && labels+=("Filename (No extension)" "Just the extension")
    labels+=("Parent Directory")
    [[ "$relative_path" != "$fullpath" ]] && labels+=("Relative Path")
    labels+=("Absolute Path")
    # Only show escaped version if path contains special characters
    [[ "$escaped_path" != "$fullpath" ]] && labels+=("Absolute Path (Escaped)")
    labels+=("Tilde Path")
    # Only show escaped tilde path if it contains special characters
    [[ "${(q)tilde_path}" != "$tilde_path" ]] && labels+=("Tilde Path (Escaped)")
    labels+=("URI Encoded" "JSON String" "File URL" "HTML Link" "Markdown Link" "Reveal in Finder" "Open with default app" "Open in VS Code")

    for label in "${labels[@]}"; do
        menu_items+=("$(printf "%-27s │ %s" "$label" "${format_map[$label]}")")
    done

    local choice
    if ! choice=$(gum choose \
        --height=20 \
        --header="Choose path format (Enter copies to clipboard, or opens the path)" \
        --cursor.foreground="$CURSOR_FG" \
        --selected.foreground="$SELECTED_FG" \
        --header.foreground="$HEADER_FG" \
        --no-show-help \
        --cursor="→ " \
        "${menu_items[@]}"); then
        echo "No selection made." >&2
        return 1
    fi

    # Extract value after the separator "│ "
    local value_to_copy="${choice#*│ }"

    if ! print -rn -- "$value_to_copy" | pbcopy; then
        die "Failed to copy to clipboard"
    fi

    echo "✓ Copied to clipboard"
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
