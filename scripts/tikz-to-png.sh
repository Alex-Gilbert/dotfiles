#!/bin/bash

# Check if the filename is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <filename.tex> [width]x[height] [density]"
    echo "Example: $0 diagram.tex 1920x1080 600"
    exit 1
fi

filename="$1"
basename="${filename%.*}"
output_size="${2:-}" # Optional width x height
density="${3:-300}"  # Optional density, default is 300

# Compile TikZ to PDF
pdflatex -shell-escape "$filename"

# Check if the PDF was created successfully
if [ ! -f "${basename}.pdf" ]; then
    echo "Error: PDF compilation failed."
    exit 1
fi

# Convert PDF to PNG with optional resizing and density
if [ -n "$output_size" ]; then
    convert -density "$density" "${basename}.pdf" -resize "$output_size" -quality 100 "${basename}.png"
else
    convert -density "$density" "${basename}.pdf" -quality 100 "${basename}.png"
fi

echo "PNG image saved as ${basename}.png"
