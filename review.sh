#!/bin/bash

DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

number=$1
if [ -z "$number" ]; then
  echo "Usage: $0 <number>"
  exit 1
fi

rm -rf "$DIR/d-review"
mkdir -p "$DIR/d-review"

# Get the diff
echo "Fetching PR #$number diff..."
diff=$(gh pr diff $number)

# Save the complete diff
echo "$diff" > "$DIR/d-review/summary.diff"

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
                mkdir -p "$DIR/d-review/$file_dir"
            fi
            
            # Write content to file
            echo "$current_content" > "$DIR/d-review/$current_file"
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
        mkdir -p "$DIR/d-review/$file_dir"
    fi
    
    # Write content to file
    echo "$current_content" > "$DIR/d-review/$current_file"
    ((file_count++))
fi

# Clean up
rm -f "$temp_file"

echo "Done! Split $file_count files into individual diffs under $DIR/d-review/"
echo "Summary diff is available at: $DIR/d-review/summary.diff"

