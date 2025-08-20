# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains a single ZSH utility script `path.sh` that helps users find and copy file paths in various formats.

## Purpose

The script resolves file paths or command locations and provides them in multiple formats:
- POSIX path (absolute)
- Shell-escaped path (handles spaces and special characters)
- macOS shorthand with tilde (~) for home directory
- File URL (file://)
- Markdown link format
- HTML link format

## Key Dependencies

- **zsh**: Script is written for ZSH shell
- **gum**: Interactive terminal UI library for the selection menu
- **python3**: Used for URL encoding
- **pbcopy**: macOS clipboard utility
- **realpath**: For resolving absolute paths

## Usage

```bash
./path.sh <filename_or_command>
```

The script will:
1. Resolve the file/directory path or command location
2. Present an interactive menu using `gum` to select the desired format
3. Copy the selected format to the clipboard using `pbcopy`

## Script Architecture

- **process_path()**: Main function that generates all path format variations and handles the interactive selection
- Uses `gum` for terminal UI with customizable colors (lines 6-9)
- Error handling for missing arguments and non-existent files
- Supports both local files/directories and commands in PATH

## Development Notes

- The script is macOS-specific due to `pbcopy` usage
- Requires `gum` to be installed for the interactive menu
- Python3 is assumed to be available in PATH for URL encoding