#!/bin/bash

# Functions
make_dir(){
    DIR=$1
    if [ ! -d "$DIR" ]; then
        # If the directory does not exist, create it
        mkdir -p $DIR
    fi
}


# Define Global Vars
EVADMX_PATH=$(eval echo "~/bioinf-tools/workshop/evalAdmix")

# Introduce Command Line Arguments
FILE=$1 # Input path to the data.vcf file
X=$2
SNV_FIL=$3

if [ "$X" -lt 2 ]; then
    echo "Error: Value for K must be greater than or equal to 2"
    exit 1
fi

if [ "$SNV_FIL" -lt 0 ] || [ "$SNV_FIL" -gt 1 ] 
then
    echo "Error: Value for SNV filter must be any number between 0 and 1."
    exit 1
fi

FNAME=$(basename $FILE)
FNAME=${FNAME%.*}

# Get the directory of the script
SCRIPT_DIR=$(dirname $(pwd))
echo $SCRIPT_DIR
cd $SCRIPT_DIR

# Initialize the directory with the R scripts
RSCRIPTS="$SCRIPT_DIR/R"

# Generate the input file in plink format
OUT="$SCRIPT_DIR/ADMIXTURE"
prepare_binaries(){
    FILE=$1
    OUT=$2
    FNAME=$3
    SNV_FIL=$4

    make_dir "$OUT/plink_bin"

    run_plink() {
        echo "Creating raw binaries using PLINK..."
        plink --vcf $FILE --make-bed --out $OUT/plink_bin/$FNAME --allow-extra-chr
    }
    filter_snp() {
        echo "Filtering out rows with $SNV_FIL non-missing SNV mutations..."
        plink --bfile $FNAME --geno $SNV_FIL --make-bed --out $FNAME --allow-extra-chr # Filter out SNPS with missingness > 99.9% 0.999
    }

    rename_chr () {
        echo "Renaming chromosomes to ADMIXTURE acceptable format and removing non-human chromosome names..."
        # ADMIXTURE does not accept chromosome names that are not human chromosomes. We will thus just exchange the first column by 0
        awk '{$1="0";print $0}' $FNAME.bim > $FNAME.bim.tmp
        mv $FNAME.bim.tmp $FNAME.bim

    }

    run_plink()

    cd $OUT/plink_bin/

    filter_snp()

    rename_chr()
}

for vcf_file in $FOLDER/*.vcf; do
    if [ -f "$vcf_file" ]; then
        prepare_binaries "$vcf_file" $OUT $FNAME $SNV_FIL
    fi
done

exit 1

mkdir $OUT/cv
cd $OUT/cv

# Loop from 1 to x
for K in $(seq 2 $X)
do
    admixture --cv $OUT/plink_bin/$FNAME.bed $K | tee log${K}.out
    
    # Run evalAdmix on each K selected
    EVADMX_OUT=$OUT/cv/eval_admix_results/"k$K"

    make_dir $EVADMX_OUT

    "$EVADMX_PATH/evalAdmix" -plink $OUT/plink_bin/$FNAME -fname $OUT/cv/$FNAME.$K.P -qname $OUT/cv/$FNAME.$K.Q -P 10 -o $EVADMX_OUT/k${K}_output.corres.txt

    Rscript $RSCRIPTS/visualise.R $OUT/plink_bin/$FNAME.fam $OUT/cv/$FNAME.$K.Q $EVADMX_OUT/k${K}_output.corres.txt # Visualise the results
     
done

grep -h CV log*.out > final_cv_log.out





