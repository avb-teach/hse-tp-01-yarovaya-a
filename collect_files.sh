#!/bin/bash

max_depth=-1
input_dir=""
output_dir=""

positional_args=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --max_depth)
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                max_depth="$2"
                shift 2
            else
                echo "Error: --max_depth requires a positive integer"
                exit 1
            fi
            ;;
        --*)
            echo "Error: Unknown option $1"
            exit 1
            ;;
        *)
            positional_args+=("$1")
            shift
            ;;
    esac
done

if [[ ${#positional_args[@]} -ne 2 ]]; then
    echo "Usage: $0 [--max_depth N] /path/to/input_dir /path/to/output_dir"
    exit 1
fi

input_dir="${positional_args[0]}"
output_dir="${positional_args[1]}"

if [[ ! -d "$input_dir" ]]; then
    echo "Error: Input directory does not exist: $input_dir"
    exit 1
fi

mkdir -p "$output_dir"

process_item() {
    local src="$1"
    local dest="$2"
    local current_depth="$3"
    local rel_path="$4"

    if [[ -f "$src" ]]; then
        filename=$(basename "$src")
        if [[ -n "$rel_path" ]]; then
            filename="${rel_path}_${filename}"
        fi

        extension="${filename##*.}"
        basename="${filename%.*}"

        counter=1
        new_filename="$filename"
        while [[ -e "$dest/$new_filename" ]]; do
            new_filename="${basename}_${counter}.${extension}"
            ((counter++))
        done

        cp "$src" "$dest/$new_filename"
    elif [[ -d "$src" ]]; then
        if [[ $max_depth -ne -1 && $current_depth -ge $max_depth ]]; then
            for item in "$src"/*; do
                if [[ -f "$item" ]]; then
                    new_rel_path=""
                    if [[ -n "$rel_path" ]]; then
                        new_rel_path="${rel_path}_$(basename "$src")"
                    else
                        new_rel_path="$(basename "$src")"
                    fi
                    process_item "$item" "$dest" $((current_depth + 1)) "$new_rel_path"
                fi
            done
            return
        fi

        for item in "$src"/*; do
            if [[ -e "$item" ]]; then
                process_item "$item" "$dest" $((current_depth + 1)) "$rel_path"
            fi
        done
    fi
}

for item in "$input_dir"/*; do
    if [[ -e "$item" ]]; then
        process_item "$item" "$output_dir" 1 ""
    fi
done

echo "Files copied successfully with max_depth=$max_depth"