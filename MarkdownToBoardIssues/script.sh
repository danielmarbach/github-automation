#!/bin/bash

# Set variables
REPO="username/repo" # Replace with your repo
PROJECT_ID="254"   # Replace with your project ID
ORG="Particular"
MARKDOWN_FILE="issues.md" # The markdown file containing the sections

# Function to create issues from bullet points and assign to the appropriate column
create_issues_from_section() {
    local column_name="$1"
    local issues=("${!2}")

    # Iterate over issues and create them
    for issue in "${issues[@]}"; do
        # Extract the title and body from the issue string
        title=$(echo "$issue" | cut -d "|" -f1)
        body=$(echo "$issue" | cut -d "|" -f2 | sed 's/\\n/\n/g')

        if [ -n "$title" ]; then
            gh project item-create $PROJECT_ID --title "$title" --body "$body" --owner "$ORG"
            echo "Created issue '$title' and added to the '$column_name' column."
        else
            echo "Skipping issue creation due to empty title."
        fi
    done
}


# Parse the markdown file
section_name=""
section_items=()
current_body=""
while IFS= read -r line; do
    # Check if line is a section header
    if [[ $line =~ ^####\ (.*) ]]; then
        # Process the previous section
        if [ -n "$section_name" ]; then
            if [ -n "$current_body" ]; then
                section_items[-1]+="$current_body"
                current_body=""
            fi
            echo "Processing section: $section_name"
            create_issues_from_section "$section_name" section_items[@]
            echo "Press Enter to continue to the next section..."
            read -r
        fi
        # Start a new section
        section_name="${BASH_REMATCH[1]}"
        section_items=()
    elif [[ $line =~ ^\-\ \[\ \]\ (.*) ]]; then
        # Start a new task
        if [ -n "$current_body" ]; then
            section_items[-1]+="$current_body"
            current_body=""
        fi
        section_items+=("${BASH_REMATCH[1]}|")
    elif [[ $line =~ ^[[:space:]]{2}\-\ \[\ \]\ (.*) ]]; then
        # Add a subtask with a checkbox
        current_body+="\n- [ ] ${BASH_REMATCH[1]}"
    elif [[ $line =~ ^[[:space:]]{2}\-\ (.*) ]]; then
        # Add a subtask without a checkbox
        current_body+="\n- ${BASH_REMATCH[1]}"
    elif [[ $line =~ ^[[:space:]]{4}\-\ \[\ \]\ (.*) ]]; then
        # Add a third-level subtask with a checkbox
        current_body+="\n  - [ ] ${BASH_REMATCH[1]}"
    elif [[ $line =~ ^[[:space:]]{4}\-\ (.*) ]]; then
        # Add a third-level subtask without a checkbox
        current_body+="\n  - ${BASH_REMATCH[1]}"
    fi
done < "$MARKDOWN_FILE"

# Process the last section
if [ -n "$section_name" ]; then
    if [ -n "$current_body" ]; then
        section_items[-1]+="$current_body"
    fi
    echo "Processing section: $section_name"
    create_issues_from_section "$section_name" section_items[@]
fi

echo "All sections processed."
