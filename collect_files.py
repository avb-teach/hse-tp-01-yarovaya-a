#!/usr/bin/env python3
import os
import shutil
import sys
import argparse

def handle_duplicates(dest_dir, filename):
    base, ext = os.path.splitext(filename)
    counter = 1
    new_filename = filename
    
    while os.path.exists(os.path.join(dest_dir, new_filename)):
        new_filename = f"{base}{counter}{ext}"
        counter += 1
    
    return new_filename

def copy_files(src_dir, dest_dir, max_depth=None, current_depth=1):
    try:
        for item in os.listdir(src_dir):
            item_path = os.path.join(src_dir, item)
            
            if os.path.isfile(item_path):
                if max_depth is None or current_depth <= max_depth:
                    dest_filename = handle_duplicates(dest_dir, item)
                    shutil.copy2(item_path, os.path.join(dest_dir, dest_filename))
            
            elif os.path.isdir(item_path):
                if max_depth is None:
                    copy_files(item_path, dest_dir, max_depth, current_depth + 1)
                else:
                    if current_depth < max_depth:
                        new_dir = os.path.join(dest_dir, item)
                        os.makedirs(new_dir, exist_ok=True)
                        copy_files(item_path, new_dir, max_depth, current_depth + 1)
                    elif current_depth == max_depth:
                        copy_files(item_path, dest_dir, max_depth, current_depth + 1)
                    else: 
                        for root, _, files in os.walk(item_path):
                            for file in files:
                                src_file = os.path.join(root, file)
                                dest_filename = handle_duplicates(dest_dir, file)
                                shutil.copy2(src_file, os.path.join(dest_dir, dest_filename))
    except Exception as e:
        print(f"Error processing {item_path}: {e}", file=sys.stderr)

def main():
    parser = argparse.ArgumentParser(description='Collect files from input directory to output directory.')
    parser.add_argument('input_dir', help='Input directory path')
    parser.add_argument('output_dir', help='Output directory path')
    parser.add_argument('--max_depth', type=int, help='Maximum depth of directory structure to preserve')
    
    args = parser.parse_args()
    
    if not os.path.isdir(args.input_dir):
        print(f"Error: Input directory {args.input_dir} does not exist", file=sys.stderr)
        sys.exit(1)
    
    os.makedirs(args.output_dir, exist_ok=True)
    
    copy_files(args.input_dir, args.output_dir, args.max_depth)
    
    print(f"Files collected successfully to {args.output_dir}")

if __name__ == "__main__":
    main()