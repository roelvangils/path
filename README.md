# 📂 path

A ZSH utility that helps you quickly copy file paths in various formats. Perfect for developers who frequently need to reference files in different contexts - from terminal commands to documentation.

![Demo of path utility in action](demo.gif?new)

## Features

- **Interactive menu** with 15+ path format options
- **Smart escaping** for paths with spaces and special characters
- **Clipboard integration** - selected format is automatically copied
- **Works with files, directories, and commands**
- **Context-aware options** - only shows relevant formats

## Dependencies

- **zsh** - The script is written for ZSH shell
- **gum** - Provides the interactive terminal UI ([installation](https://github.com/charmbracelet/gum#installation))
- **python3** - Used for URL encoding and JSON escaping
- **pbcopy** - macOS clipboard utility (included in macOS)
- **realpath** - For resolving absolute paths (usually pre-installed)

### Installing dependencies on macOS

```bash
# Install gum using Homebrew
brew install gum

# Other dependencies are typically pre-installed on macOS
```

## Installation

1. Clone this repository:
```bash
git clone https://github.com/roelvangils/path.git
cd path
```

2. Make the script executable:
```bash
chmod +x path.sh
```

3. Optionally, add to your PATH or create an alias:
```bash
# Add to .zshrc for permanent alias
alias path='~/Repos/path/path.sh'
```

## Usage

```bash
./path.sh <filename_or_command>
```

### Examples

```bash
# Get path for a file
./path.sh README.md

# Get path for a directory
./path.sh ~/Documents

# Get path for a command
./path.sh python3

# Get path for files with spaces
./path.sh "My Document.pdf"
```

## Available Formats

The interactive menu provides these format options:

| Format | Example Output | Use Case |
|--------|---------------|----------|
| **Filename** | `README.md` | Just the filename |
| **Filename (No extension)** | `README` | Filename without extension |
| **Just the extension** | `md` | File extension only |
| **Parent Directory** | `/Users/name/Repos/path` | Directory containing the file |
| **Relative Path** | `../path/README.md` | Path relative to current directory |
| **Absolute Path** | `/Users/name/Repos/path/README.md` | Full system path |
| **Absolute Path (Escaped)** | `"/Users/name/My Docs/file.txt"` | Escaped for shell use |
| **Tilde Path** | `~/Repos/path/README.md` | Home-relative path |
| **Tilde Path (Escaped)** | `"~/My Docs/file.txt"` | Escaped home-relative path |
| **URI Encoded** | `%2FUsers%2Fname%2FRepos%2Fpath%2FREADME.md` | URL-safe encoding |
| **JSON String** | `"/Users/name/Repos/path/README.md"` | JSON-escaped string |
| **File URL** | `file:///Users/name/Repos/path/README.md` | File URL format |
| **HTML Link** | `<a href="file://...">README.md</a>` | HTML anchor tag |
| **Markdown Link** | `[README.md](file://...)` | Markdown link format |
| **Reveal in Finder** | Opens Finder at file location | macOS Finder integration |
| **Open with default app** | Opens file with default application | System default app |
| **Open in VS Code** | Opens file in Visual Studio Code | VS Code integration |

Note: Some options only appear when relevant (e.g., escaped versions only show for paths with special characters).

## Tips

- Use arrow keys to navigate the menu
- Press Enter to copy the selected format to clipboard
- Press Esc or Ctrl+C to cancel without copying
- The "Reveal in Finder" and "Open" options execute commands instead of copying

## Credits

Demo GIF created with [VHS](https://github.com/charmbracelet/vhs) - a tool for creating terminal GIFs from code.

## License

MIT
