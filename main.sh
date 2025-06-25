#!/bin/bash

DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

usage() {
    echo "Usage: $0 <owner/repo pr-number | github-pr-url>"
    echo "Examples:"
    echo "  $0 facebook/react 12345"
    echo "  $0 https://github.com/local-llc/local-llc.com/pull/1607"
    echo "  $0 https://github.com/local-llc/local-llc.com/pull/1607/files"
    exit 1
}

# Parse arguments
if [ $# -eq 1 ]; then
    # Check if it's a GitHub PR URL
    if [[ "$1" =~ ^https://github.com/([^/]+)/([^/]+)/pull/([0-9]+) ]]; then
        owner="${BASH_REMATCH[1]}"
        repo="${BASH_REMATCH[2]}"
        pr_number="${BASH_REMATCH[3]}"
        repo_path="$owner/$repo"
    else
        echo "Error: Invalid GitHub PR URL format"
        usage
    fi
elif [ $# -eq 2 ]; then
    # Traditional format: owner/repo pr-number
    repo_path=$1
    pr_number=$2
    
    if [[ ! "$repo_path" =~ ^[^/]+/[^/]+$ ]]; then
        echo "Error: Repository must be in 'owner/repo' format"
        usage
    fi
    
    owner=$(echo "$repo_path" | cut -d'/' -f1)
    repo=$(echo "$repo_path" | cut -d'/' -f2)
else
    usage
fi

# Setup directories
REPOS_DIR="$DIR/repos"
REVIEWS_DIR="$DIR/reviews"
REPO_DIR="$REPOS_DIR/$owner/$repo"
REVIEW_DIR="$REVIEWS_DIR/${owner}-${repo}/pr-${pr_number}"

# Create necessary directories
mkdir -p "$REPO_DIR"
mkdir -p "$REVIEW_DIR/files"

# Clone or fetch the repository
if [ ! -d "$REPO_DIR/.git" ]; then
    echo "Cloning $repo_path..."
    git clone "git@github.com:$repo_path.git" "$REPO_DIR"
else
    echo "Fetching latest changes for $repo_path..."
    cd "$REPO_DIR"
    git fetch --all
fi

# Change to repository directory
cd "$REPO_DIR"

# Fetch PR branch and checkout
echo "Fetching PR branch..."
gh pr checkout $pr_number

# Clean previous review files
rm -rf "$REVIEW_DIR"/*
mkdir -p "$REVIEW_DIR/files"

# Get the diff using gh CLI
echo "Fetching PR #$pr_number diff..."
diff=$(gh pr diff $pr_number)

if [ -z "$diff" ]; then
    echo "Error: Could not fetch diff for PR #$pr_number"
    echo "Make sure you're authenticated with gh CLI and the PR exists"
    exit 1
fi

# Save the complete diff
echo "$diff" > "$REVIEW_DIR/raw.diff"

# Split the diff into individual files
echo "Splitting diff into individual files..."

# Create a temporary file for processing
temp_file=$(mktemp)
echo "$diff" > "$temp_file"

# Process the diff file
current_file=""
current_content=""
file_count=0

while IFS= read -r line; do
    if [[ "$line" =~ ^diff\ --git\ a/(.*)\ b/ ]]; then
        # Save previous file if exists
        if [[ -n "$current_file" && -n "$current_content" ]]; then
            # Create directory structure
            file_dir=$(dirname "$current_file")
            if [[ "$file_dir" != "." ]]; then
                mkdir -p "$REVIEW_DIR/files/$file_dir"
            fi
            
            # Write content to file
            echo "$current_content" > "$REVIEW_DIR/files/${current_file}.diff"
            ((file_count++))
        fi
        
        # Start new file
        current_file="${BASH_REMATCH[1]}"
        current_content="$line"
    else
        # Append to current file content
        if [[ -n "$current_file" ]]; then
            if [[ -n "$current_content" ]]; then
                current_content="$current_content"$'\n'"$line"
            else
                current_content="$line"
            fi
        fi
    fi
done < "$temp_file"

# Save the last file
if [[ -n "$current_file" && -n "$current_content" ]]; then
    # Create directory structure
    file_dir=$(dirname "$current_file")
    if [[ "$file_dir" != "." ]]; then
        mkdir -p "$REVIEW_DIR/files/$file_dir"
    fi
    
    # Write content to file
    echo "$current_content" > "$REVIEW_DIR/files/${current_file}.diff"
    ((file_count++))
fi

# Clean up
rm -f "$temp_file"

# Save PR metadata
echo "Fetching PR metadata..."
pr_data=$(gh pr view $pr_number --json title,author,createdAt,url,body,state,number,headRefName,baseRefName)
echo "$pr_data" > "$REVIEW_DIR/pr-info.json"

# Create PR summary
echo "Creating PR summary..."
pr_title=$(echo "$pr_data" | jq -r .title)
pr_author=$(echo "$pr_data" | jq -r .author.login)
pr_created=$(echo "$pr_data" | jq -r .createdAt)
pr_url=$(echo "$pr_data" | jq -r .url)
pr_state=$(echo "$pr_data" | jq -r .state)
pr_head=$(echo "$pr_data" | jq -r .headRefName)
pr_base=$(echo "$pr_data" | jq -r .baseRefName)

cat > "$REVIEW_DIR/summary.txt" << EOF
PR #$pr_number: $pr_title
Repository: $repo_path
Author: $pr_author
State: $pr_state
Branch: $pr_head -> $pr_base
Created: $pr_created
URL: $pr_url

Files changed: $file_count
Review generated: $(date)
EOF

echo "Done! Review files created:"
echo "  Repository: $repo_path"
echo "  PR: #$pr_number"
echo "  Review location: $REVIEW_DIR"
echo "  Total files: $file_count"
echo ""
echo "Files available at:"
echo "  - Raw diff: $REVIEW_DIR/raw.diff"
echo "  - Summary: $REVIEW_DIR/summary.txt"
echo "  - Individual files: $REVIEW_DIR/files/"
echo "  - PR info: $REVIEW_DIR/pr-info.json"

# Execute Claude review
echo ""
echo "Executing Claude review..."
claude "Review $REVIEW_DIR" --add-dir "$REVIEW_DIR"