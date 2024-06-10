#!/bin/bash
# sudo apt install bc
# sudo apt install
# sudo apt install make
# sudo apt install zlib1g-dev
# sudo apt install r-base-core

# Functions
make_dir(){ # This function creates directories recursively based on the name/path provided as the positional argument
    DIR=$1
    if [ ! -d "$DIR" ]; then
        # If the directory does not exist, create it
        mkdir -p $DIR
    fi
}
prepare_binaries(){ # This function creates PLINK binary files using 4 positional arguments
    FILE=$1
    OUT=$2
    FNAME=$3
    SNV_FIL=$4

    make_dir "$OUT/plink_bin"

    run_plink() {

        FILE=$1
        OUT=$2
        FNAME=$3

        echo "Creating raw binaries using PLINK..."
        $TOOLSDIR/plink/plink --vcf $FILE --make-bed --out $OUT/plink_bin/$FNAME --allow-extra-chr
    }
    filter_snp() {

        FNAME=$1
        SNV_FIL=$2

        echo "Filtering out rows with $SNV_FIL non-missing SNV mutations..."
        $TOOLSDIR/plink/plink --bfile $FNAME --geno $SNV_FIL --make-bed --out $FNAME --allow-extra-chr # Filter out SNPS with missingness > 99.9% 0.999
    }

    rename_chr () {

        FNAME=$1
        echo "Renaming chromosomes to ADMIXTURE acceptable format and removing non-human chromosome names..."
        # ADMIXTURE does not accept chromosome names that are not human chromosomes. We will thus just exchange the first column by 0
        awk '{$1="0";print $0}' $FNAME.bim > $FNAME.bim.tmp
        mv $FNAME.bim.tmp $FNAME.bim

    }

    run_plink $FILE $OUT $FNAME

    cd "$OUT/plink_bin/"

    filter_snp $FNAME $SNV_FIL

    rename_chr $FNAME
}

# --- Help Function
usage() # This is the help function
{
   # Display Help
   echo "========================================= Run ADMIXTURE Pipeline =============================================="
   echo "                usage: run_adx.sh [-h] [ARGS]                                                             "
   echo "                example: run_adx.sh -f ./data/ -x 2 -s 0.999                                              "
   echo "                                  -f       Path to the folder with the .vcf files.                        "
   echo "                                  -k       Number of guessed populations K (min is 2)                     "
   echo "                                  -s       Number by which to filter the SNVs between 0 and 1.            "
   echo "                                  -V       Prints out the tool version.                                   "
   echo "                                  -h       Print this Help.                                               "
   echo "                                                                                                          "
   echo "==============================================================================================================="
}

while getopts ":hf:k:s:V" flag;
do
    case "${flag}" in
        h) # Display Help Function
              usage
              exit;;
        f)
              FOLDER=${OPTARG}
        ;;
        k)
              X=${OPTARG}
        ;;
        s)
              SNV_FIL=${OPTARG}
        ;;
        V)
              VERSION="version"
              echo $VERSION
        ;;
        ?)
          echo "Error: Invalid option. Try '-h' to see a list of available options."
          exit;;
        *)
          usage
          exit;;
    esac
done

# Checks if the K value is set to correct number
if [ "$X" -lt 2 ]; then
    echo "Error: Value for K must be greater than or equal to 2"
    exit 1
fi

num=$(echo "$SNV_FIL")

# Check if less than 0 or greater than 1 using OR (||) in bc
if [ $(echo "$num < 0 || $num > 1" | bc) -eq 1 ]; then
  show_error_dialog "Error: Value for SNV filter must be any number between 0 and 1."
  exit 1
fi

# Get the directory of the script
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Change directory to the script dir
cd "$SCRIPT_DIR" || exit

# Initialize the directory with the R scripts
RSCRIPTS="$SCRIPT_DIR/R"
BASHSCRIPTS="$SCRIPT_DIR/BASH"
TOOLSDIR="$SCRIPT_DIR/tools"
EVADMX_PATH="$TOOLSDIR/evalAdmix"

# Generate the input file in plink format
OUT="$SCRIPT_DIR/results/ADMIXTURE"

# Create folder to hold the PLINK binaries
make_dir "$OUT/plink_bin"

# Chhange to that directory
cd $SCRIPT_DIR/$FOLDER

# Loop over the files in $1 and extract file name and prepare PLINK binaries
for vcf_file in *.vcf; do
      echo $vcf_file
      FNAME=${vcf_file%.*}

      prepare_binaries $SCRIPT_DIR/$FOLDER/$vcf_file $OUT $FNAME $SNV_FIL

done

# Creates a list of plink binary files to be used for de-duplicating
bash $BASHSCRIPTS/create_plink_bin_list.sh "$OUT/plink_bin"
FNAME=${FNAME%%[0-9]*}"_merged" # Creates a new file name for the merged files

# Merges files based on the merge list
"$TOOLSDIR/plink/plink" --merge-list merge_list.txt --make-bed --out $FNAME

# Looks for a file with duplicated sample id's
line_file="$OUT/plink_bin/GT_merged-merge.missnp"

# Check if the file with duplicates exists and processe them out, then recreates the PLINK binaries
if [ -e "$line_file" ]; then

  bash $BASHSCRIPTS/remove_multialleles.sh "$line_file" "$SCRIPT_DIR/$FOLDER"

  rm -r "$SCRIPT_DIR/results"
  make_dir "$OUT/plink_bin"

  cd $SCRIPT_DIR/$FOLDER

  for vcf_file in *.vcf; do
        echo $vcf_file
        FNAME=${vcf_file%.*}

        prepare_binaries $SCRIPT_DIR/$FOLDER/$vcf_file $OUT $FNAME $SNV_FIL
  done

  bash $BASHSCRIPTS/create_plink_bin_list.sh "$OUT/plink_bin"
  FNAME=${FNAME%%[0-9]*}"_merged"

  "$TOOLSDIR/plink/plink" --merge-list merge_list.txt --make-bed --out $FNAME

else
  echo "Warning: File $line_file does not exist. Skipping merging process..."
fi

mkdir $OUT/cv
cd $OUT/cv

# Starts a loop for each 1 to K, so it caulculates and cross-validates ADMIXTURE proportions for all values of K
for K in $(seq 2 $X)
do
    "$TOOLSDIR/admixture/admixture32" --cv $OUT/plink_bin/$FNAME.bed $K | tee log${K}.out

    # Run evalAdmix on each K selected
    EVADMX_OUT=$OUT/cv/eval_admix_results/"k$K"

    make_dir $EVADMX_OUT

    "$EVADMX_PATH/evalAdmix" -plink $OUT/plink_bin/$FNAME -fname $OUT/cv/$FNAME.$K.P -qname $OUT/cv/$FNAME.$K.Q -P 10 -o $EVADMX_OUT/k${K}_output.corres.txt # Runs the evalAdmix script

    echo "Running rscripts..."

    Rscript $RSCRIPTS/visualise.R $OUT/plink_bin/$FNAME.fam $OUT/cv/$FNAME.$K.Q $EVADMX_OUT/k${K}_output.corres.txt # Visualise the results

done

grep -h CV log*.out > final_cv_log.out # Aggregates the results into one file
