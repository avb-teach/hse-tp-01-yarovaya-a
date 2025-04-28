#!/bin/bash

# Функция для вывода справки
usage() {
    echo "Usage: $0 [--max_depth DEPTH] INPUT_DIR OUTPUT_DIR"
    echo "Copies all files from INPUT_DIR (including subdirectories) to OUTPUT_DIR"
    echo "  --max_depth DEPTH  maximum depth of directory traversal (optional)"
    exit 1
}

# Парсинг аргументов
max_depth=""
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --max_depth)
            max_depth="$2"
            shift 2
            ;;
        *)
            if [[ -z "$input_dir" ]]; then
                input_dir="$1"
            elif [[ -z "$output_dir" ]]; then
                output_dir="$1"
            else
                echo "Error: Too many arguments"
                usage
            fi
            shift
            ;;
    esac
done

# Проверка обязательных аргументов
if [[ -z "$input_dir" || -z "$output_dir" ]]; then
    echo "Error: Missing required arguments"
    usage
fi

# Проверка существования входной директории
if [[ ! -d "$input_dir" ]]; then
    echo "Error: Input directory does not exist: $input_dir"
    exit 1
fi

# Создание выходной директории, если её нет
mkdir -p "$output_dir"

# Функция для обработки конфликтов имен файлов
get_unique_filename() {
    local original_path="$1"
    local filename=$(basename "$original_path")
    local extension="${filename##*.}"
    local name="${filename%.*}"
    
    # Если файл уже существует, добавляем суффикс
    local counter=1
    local new_filename="$filename"
    while [[ -e "$output_dir/$new_filename" ]]; do
        # Для файлов без расширения
        if [[ "$name" == "$extension" ]]; then
            new_filename="${name}${counter}"
        else
            new_filename="${name}${counter}.${extension}"
        fi
        ((counter++))
    done
    
    echo "$new_filename"
}

# Функция для копирования файлов
copy_files() {
    local current_dir="$1"
    local current_depth="$2"
    
    # Проверка максимальной глубины
    if [[ -n "$max_depth" && "$current_depth" -gt "$max_depth" ]]; then
        return
    fi
    
    # Обход содержимого директории
    for item in "$current_dir"/*; do
        if [[ -f "$item" ]]; then
            # Копируем файл с уникальным именем
            local unique_name=$(get_unique_filename "$item")
            cp "$item" "$output_dir/$unique_name"
            echo "Copied: $item -> $output_dir/$unique_name"
        elif [[ -d "$item" ]]; then
            # Рекурсивный обход поддиректорий
            copy_files "$item" $((current_depth + 1))
        fi
    done
}

# Начинаем обход с глубины 1
copy_files "$input_dir" 1

echo "All files have been copied to $output_dir"