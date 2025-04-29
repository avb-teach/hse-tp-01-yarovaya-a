#!/bin/bash

if ! command -v uv &> /dev/null; then
    echo "uv не найден. Устанавливаю..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.cargo/bin:$PATH"
fi

echo "Устанавливаю Python 3.12.3 с помощью uv..."
uv python install 3.12.3

echo "Создаю виртуальное окружение..."
uv venv --python 3.12.3 .venv
source .venv/bin/activate

if [ "$#" -lt 2 ]; then
    echo "Использование: $0 /путь/к/входной_директории /путь/к/выходной_директории [--max_depth N]"
    exit 1
fi

INPUT_DIR=$1
OUTPUT_DIR=$2
MAX_DEPTH=""

if [ "$3" == "--max_depth" ]; then
    if [ -z "$4" ]; then
        echo "Ошибка: --max_depth требует числовое значение"
        exit 1
    fi
    MAX_DEPTH=$4
fi

if [ ! -d "$INPUT_DIR" ]; then
    echo "Ошибка: Входная директория не существует"
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

def get_depth(path, base):
    rel_path = os.path.relpath(path, base)
    if rel_path == '.':
        return 0
    return rel_path.count(os.sep) + 1

name_counter = {}

for root, dirs, files in os.walk(input_dir):
    current_depth = get_depth(root, input_dir)

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
