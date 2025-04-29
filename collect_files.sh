#!/bin/bash

max_depth=-1
input_dir=""
output_dir=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --max_depth)
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                max_depth="$2"
                shift 2
            else
                echo "Error: --max_depth requires a numeric argument"
                exit 1
            fi
            ;;
        *)
            if [[ -z "$input_dir" ]]; then
                input_dir="$1"
            elif [[ -z "$output_dir" ]]; then
                output_dir="$1"
            else
                echo "Error: Too many arguments"
                exit 1
            fi
            shift
            ;;
    esac
done

if [[ -z "$input_dir" || -z "$output_dir" ]]; then
    echo "Usage: $0 [--max_depth N] /path/to/input_dir /path/to/output_dir"
    exit 1
fi

if [ ! -d "$input_dir" ]; then
    echo "Input directory does not exist: $input_dir"
    exit 1
fi

mkdir -p "$output_dir"

process_item() {
    local src=$1
    local dest=$2
    local current_depth=$3

    if [ -f "$src" ]; then
        filename=$(basename "$src")
        extension="${filename##*.}"
        basename="${filename%.*}"

        counter=1
        new_filename="$filename"
        while [ -f "$dest/$new_filename" ]; do
            new_filename="${basename}${counter}.${extension}"
            counter=$((counter + 1))
        done

        cp "$src" "$dest/$new_filename"
    elif [ -d "$src" ]; then
        if [ "$max_depth" -ne -1 ] && [ "$current_depth" -ge "$max_depth" ]; then
            return
        fi

        for item in "$src"/*; do
            if [ -e "$item" ]; then
                process_item "$item" "$dest" $((current_depth + 1))
            fi
        done
    fi
}

for item in "$input_dir"/*; do
    if [ -e "$item" ]; then
        process_item "$item" "$output_dir" 1
    fi
done

echo "Files copied successfully from $input_dir to $output_dir"