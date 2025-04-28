#!/bin/bash

if ! command -v python3 &> /dev/null; then
    echo "Python 3 is required but not installed. Please install Python 3."
    exit 1
fi

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

python3 "$SCRIPT_DIR/collect_files.py" "$@"