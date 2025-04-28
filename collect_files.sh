#!/bin/bash

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo "Usage: $0 <input_dir> <output_dir> [--max_depth <depth>]"
    exit 1
fi

input_dir="$1"
output_dir="$2"
max_depth=""
handle_duplicates=true

if [ "$#" -eq 3 ] && [ "$3" == "--max_depth" ]; then
    echo "Error: --max_depth requires a depth value"
    exit 1
fi

if [ "$#" -eq 4 ] && [ "$3" == "--max_depth" ]; then
    max_depth="$4"
    if ! [[ "$max_depth" =~ ^[0-9]+$ ]]; then
        echo "Error: max_depth must be a positive integer"
        exit 1
    fi
    handle_duplicates=false
fi

if [ ! -d "$input_dir" ]; then
    echo "Error: Input directory does not exist"
    exit 1
fi

mkdir -p "$output_dir"

copy_files() {
    local src="$1"
    local dest="$2"
    local current_depth="$3"
    local max_d="$4"

    if [ -n "$max_d" ] && [ "$current_depth" -gt "$max_d" ]; then
        return
    fi

    for item in "$src"/*; do
        if [ -f "$item" ]; then
            filename=$(basename "$item")
            
            if [ "$handle_duplicates" = true ]; then
                base="${filename%.*}"
                ext="${filename##*.}"
                if [ "$ext" = "$filename" ]; then
                    ext=""
                else
                    ext=".$ext"
                fi
                
                counter=1
                new_filename="$filename"
                while [ -e "$dest/$new_filename" ]; do
                    new_filename="${base}${counter}${ext}"
                    counter=$((counter + 1))
                done
                
                cp "$item" "$dest/$new_filename"
            else
                cp "$item" "$dest/"
            fi
            
        elif [ -d "$item" ]; then
            copy_files "$item" "$dest" $((current_depth + 1)) "$max_d"
        fi
    done
}

copy_with_depth() {
    local src="$1"
    local dest="$2"
    local current_depth=1
    local max_d="$3"

    for item in "$src"/*; do
        if [ -f "$item" ]; then
            filename=$(basename "$item")
            cp "$item" "$dest/"
        elif [ -d "$item" ]; then
            if [ -z "$max_d" ] || [ "$current_depth" -le "$max_d" ]; then
                dirname=$(basename "$item")
                mkdir -p "$dest/$dirname"
                copy_with_depth "$item" "$dest/$dirname" $((current_depth + 1)) "$max_d"
            else
                find "$item" -type f -exec cp {} "$dest/" \;
            fi
        fi
    done
}

if [ -n "$max_depth" ]; then
    copy_with_depth "$input_dir" "$output_dir" 1 "$max_depth"
else
    copy_files "$input_dir" "$output_dir" 1 ""
fi

echo "Files collected successfully to $output_dir"