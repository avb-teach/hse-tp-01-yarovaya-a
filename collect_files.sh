#!/bin/bash

if ! command -v uv &> /dev/null; then
    echo "uv not found — installing..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.cargo/bin:$PATH"
fi

uv venv .venv
source .venv/bin/activate

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 /path/to/input_dir /path/to/output_dir [--max_depth N]"
    exit 1
fi

INPUT_DIR=$1
OUTPUT_DIR=$2
MAX_DEPTH=""

if [ "$3" == "--max_depth" ]; then
    if [ -z "$4" ]; then
        echo "Error: --max_depth requires a numeric value"
        exit 1
    fi
    MAX_DEPTH=$4
fi

if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input directory does not exist"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

python3 - <<END
import os
import shutil
import sys

input_dir = "$INPUT_DIR"
output_dir = "$OUTPUT_DIR"
max_depth = "$MAX_DEPTH"

def depth(path, base):
    rel_path = os.path.relpath(path, base)
    if rel_path == '.':
        return 0
    return rel_path.count(os.sep) + 1

name_counter = {}

for root, dirs, files in os.walk(input_dir):
    current_depth = depth(root, input_dir)

    if max_depth and current_depth > int(max_depth):
        dirs[:] = []
        continue

    for file in files:
        src_file = os.path.join(root, file)

        if not max_depth:
            base_name, ext = os.path.splitext(file)
            new_file = file

            counter = 1
            while os.path.exists(os.path.join(output_dir, new_file)):
                new_file = f"{base_name}{counter}{ext}"
                counter += 1

            shutil.copy2(src_file, os.path.join(output_dir, new_file))
        else:
            rel_path = os.path.relpath(root, input_dir)
            target_dir = os.path.join(output_dir, rel_path)
            os.makedirs(target_dir, exist_ok=True)
            shutil.copy2(src_file, os.path.join(target_dir, file))

END