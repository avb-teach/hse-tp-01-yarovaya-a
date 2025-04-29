#!/bin/bash

max_depth=-1
input_dir=""
output_dir=""

positional=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --max_depth)
            if [[ $2 =~ ^[0-9]+$ ]]; then
                max_depth=$2
                shift 2
            else
                echo "Error: --max_depth requires a positive integer" >&2
                exit 1
            fi
            ;;
        --*)
            echo "Error: Unknown option $1" >&2
            exit 1
            ;;
        *)
            positional+=("$1")
            shift
            ;;
    esac
done

if [[ ${#positional[@]} -ne 2 ]]; then
    echo "Usage: $0 [--max_depth N] INPUT_DIR OUTPUT_DIR" >&2
    exit 1
fi

input_dir="${positional[0]}"
output_dir="${positional[1]}"

if [[ ! -d "$input_dir" ]]; then
    echo "Error: Input directory does not exist" >&2
    exit 1
fi

mkdir -p "$output_dir"

copy_files() {
    local src="$1"
    local dest="$2"
    local depth="$3"
    local prefix="$4"

    if [[ -f "$src" ]]; then
        local filename="${prefix}$(basename "$src")"
        local counter=1
        local new_filename="$filename"
        
        while [[ -e "$dest/$new_filename" ]]; do
            new_filename="${filename%.*}_$counter.${filename##*.}"
            ((counter++))
        done
        
        cp "$src" "$dest/$new_filename"
    elif [[ -d "$src" ]]; then
        if [[ $max_depth -ne -1 && $depth -ge $max_depth ]]; then
            return
        fi
        
        for item in "$src"/*; do
            if [[ -e "$item" ]]; then
                local new_prefix="${prefix}$(basename "$src")_"
                copy_files "$item" "$dest" $((depth + 1)) "$new_prefix"
            fi
        done
    fi
}

for item in "$input_dir"/*; do
    if [[ -e "$item" ]]; then
        copy_files "$item" "$output_dir" 1 ""
    fi
done

echo "Files copied successfully to $output_dir"