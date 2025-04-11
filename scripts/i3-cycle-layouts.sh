#!/bin/bash

# Define the layouts in the order you want to cycle through them
LAYOUTS=("vstack" "hstack" "spiral" "2columns" "3columns" "companion" "autosplit")

# File to store the current layout
LAYOUT_FILE="$HOME/.current_i3_layout"

# Initialize layout file if it doesn't exist
if [ ! -f "$LAYOUT_FILE" ]; then
    echo "0" > "$LAYOUT_FILE"
fi

# Read current layout index
CURRENT_INDEX=$(cat "$LAYOUT_FILE")

# Determine the next layout
NEXT_INDEX=$(( (CURRENT_INDEX + 1) % ${#LAYOUTS[@]} ))
NEXT_LAYOUT="${LAYOUTS[$NEXT_INDEX]}"

# Apply the layout
i3l "$NEXT_LAYOUT"

# Store the new layout index
echo "$NEXT_INDEX" > "$LAYOUT_FILE"

# Notify the user
notify-send "Layout: $NEXT_LAYOUT"
