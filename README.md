# Multi-Repository PR Review System

A local tool for reviewing GitHub pull requests across multiple repositories.

## Directory Structure

```
review/
├── CLAUDE.md          # Review policies and instructions
├── main.sh          # Main review script
├── repos/             # Cloned repositories
│   └── owner/
│       └── repo/
└── reviews/           # Review outputs
    └── owner-repo/
        └── pr-123/
            ├── raw.diff    # raw pr diff
            ├── summary.txt # PR summary
            └── files/
                └── *.diff
```

## Usage

```bash
# Review a specific PR
./main.sh owner/repo pr-number

# Example
./main.sh facebook/react 12345
```

## Features

- **Multi-repository support**: Manages multiple repositories in organized structure
- **Smart cloning**: Clones repositories on first use, fetches updates on subsequent uses
- **Organized output**: Separates reviews by repository and PR number
- **File splitting**: Splits large diffs into individual file diffs for easier review
- **PR metadata**: Saves PR information (title, author, etc.) alongside diffs

## Prerequisites

- `gh` CLI tool (GitHub CLI) - must be authenticated
- `git`
- `bash`

## Output Structure

For each PR review, the script creates:
- `summary.diff`: Complete PR diff
- `pr-info.json`: PR metadata (title, author, created date, URL)
- `files/`: Directory containing individual file diffs

## Review Process

1. Run the script with repository and PR number
2. Script clones/updates the repository in `repos/`
3. Fetches PR diff and metadata using GitHub CLI
4. Creates organized output in `reviews/owner-repo/pr-number/`
5. Use the generated files with your preferred review tools or AI assistants