#!/bin/bash

# Variables
PROJECT_ID="252"
TEMPLATE="issue-template.md"
TITLES="titles.txt"
ORG="Particular"

while IFS= read -r TITLE; do
  # Create draft issue
  $(gh project item-create $PROJECT_ID --title "$TITLE" --body "$(cat $TEMPLATE)" --owner "$ORG")
  echo "Created issue: $TITLE"
done < "$TITLES"
