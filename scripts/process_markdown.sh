#!/bin/bash

# Ensure the input file is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="${INPUT_FILE%.*}_processed.md"

# Process the file
sed -E '
    # Replace $...$ with italicized content
    s/\$([^$]+)\$/\*\1\*/g

    # Replace _(n) with subscript characters
    s/_0/₀/g
    s/_1/₁/g
    s/_2/₂/g
    s/_3/₃/g
    s/_4/₄/g
    s/_5/₅/g
    s/_6/₆/g
    s/_7/₇/g
    s/_8/₈/g
    s/_9/₉/g
    s/_i/ᵢ/g
' "$INPUT_FILE" > "$OUTPUT_FILE"

echo "Processed file saved as $OUTPUT_FILE"
