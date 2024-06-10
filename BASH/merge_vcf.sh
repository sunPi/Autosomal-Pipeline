#!/bin/bash

make_dir(){
    DIR=$1
    if [ ! -d "$DIR" ]; then
        # If the directory does not exist, create it
        mkdir -p $DIR
    fi
}

# Globals
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

echo $SCRIPT_DIR

exit 1 
BASHSCRIPTS="$SCRIPT_DIR"
OUT="$SCRIPT_DIR/results/ADMIXTURE"

make_dir "$OUT/plink_bin"

# Output file name
output_file="GT_merged.vcf"

# Change directory to the VCF directory
# cd "$vcf_dir" || exit

# # Compress the .vcf files for bcftools
# for vcf_file in *.vcf; do
#     if [ -f "$vcf_file" ]; then
#         bgzip "$vcf_file"
#     fi
# done

bash $BASHSCRIPTS/create_plink_bin_list.sh "$OUT/plink_bin"
FNAME=${FNAME%%[0-9]*}"_merged"

plink --merge-list merge_list.txt --make-bed --out $FNAME