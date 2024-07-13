#!/bin/bash

# Initialize an empty array


# Reads the "missnp_file" contents as an array
read_into_array() {
  MISSNP_ARRAY=()

  while IFS= read -r line; do
      MISSNP_ARRAY+=("$line")
  done < $1
}


# File from which to read the line
missnp_file=$1

read_into_array $missnp_file

# Read the line into a variable
if [ ! -f "$missnp_file" ]; then
    echo "File $missnp_file does not exist."
    exit 1
fi

# read -r pattern < "$missnp_file"
# echo "Pattern to remove: $pattern"

# Directory containing the .vcf files
directory=$2

# Print the contents of the array
for pattern in "${MISSNP_ARRAY[@]}"; do
    # echo "$pattern"
    # Loop over all .vcf files in the directory
    for file in "$directory"/*.vcf; do
        # Check if the file contains the line with the pattern
        if grep -q "$pattern" "$file"; then
            # Remove the line from the file
            sed -i "/$pattern/d" "$file"
            echo "Removed '$pattern' from $file"
        else
            echo "'$pattern' not found in $file"
        fi
    done
done
