#!/bin/bash


if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo "Usage: $0 [--max_depth N] /path/to/input_dir /path/to/output_dir"
    exit 1
fi

max_depth=-1
input_dir=""
output_dir=""

if [ "$1" == "--max_depth" ]; then
    if [ "$#" -ne 4 ]; then
        echo "Usage: $0 [--max_depth N] /path/to/input_dir /path/to/output_dir"
        exit 1
    fi
    max_depth=$2
    input_dir=$3
    output_dir=$4
else
    input_dir=$1
    output_dir=$2
fi

if [ ! -d "$input_dir" ]; then
    echo "Input directory does not exist: $input_dir"
    exit 1
fi

if [ ! -d "$output_dir" ]; then
    mkdir -p "$output_dir"
fi

copy_files() {
    local src=$1
    local dest=$2
    local current_depth=$3
    local max_d=$4

    if [ "$max_d" -ne -1 ] && [ "$current_depth" -gt "$max_d" ]; then
        return
    fi

    for item in "$src"/*; do
        if [ -f "$item" ]; then
            filename=$(basename "$item")
            extension="${filename##*.}"
            basename="${filename%.*}"

            counter=1
            new_filename="$filename"
            while [ -f "$dest/$new_filename" ]; do
                new_filename="${basename}${counter}.${extension}"
                counter=$((counter + 1))
            done

            cp "$item" "$dest/$new_filename"
        elif [ -d "$item" ]; then
            copy_files "$item" "$dest" $((current_depth + 1)) "$max_d"
        fi
    done
}

copy_files "$input_dir" "$output_dir" 1 "$max_depth"

echo "Files copied successfully from $input_dir to $output_dir"
