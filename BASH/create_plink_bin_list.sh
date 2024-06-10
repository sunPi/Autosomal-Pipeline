#!/bin/bash

FILES_DIR=$1

# Create a merge list file
merge_list_file="merge_list.txt"

touch $merge_list_file

# Find all PLINK BED files in the directory
find "$FILES_DIR" -type f -name "*.bed" | while read -r bed_file; do
    # Remove the .bed extension to get the base filename
    base_name="${bed_file%.bed}"
    # Check if the corresponding .bim and .fam files exist
    if [[ -f "${base_name}.bim" && -f "${base_name}.fam" ]]; then
        # Append the filenames to the merge list file
        echo "${bed_file} ${base_name}.bim ${base_name}.fam" >> "$merge_list_file"
    fi
done

echo "Created a list of binary files to merge named $merge_list_file!"
