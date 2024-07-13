#!/bin/bash
# sudo apt install bc
# sudo apt install
# sudo apt install make
# sudo apt install zlib1g-dev
# sudo apt install r-base-core

# Get the directory of the script
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Source necessary files
. $SCRIPT_DIR/functions.sh
. $SCRIPT_DIR/config.sh

# --- Help Function
usage() # This is the help function
{
   # Display Help
   echo "========================================= Run ADMIXTURE Pipeline =============================================="
   echo "                usage: run_adx.sh [-h] [ARGS]                                                             "
   echo "                example: run_adx.sh -f ./data/ -x 2 -s 0.999                                              "
   echo "                                  -f       Path to the folder with the input files                        "
   echo "                                  -e       Specify the file extension of your input files.                "
   echo "                                  -k       Number of guessed populations K (min is 2)                     "
   echo "                                  -s       Number by which to filter the SNVs between 0 and 1.            "
   echo "                                  -o       Set the name of the results folder.                            "
   echo "                                  -m       Merges the vcf files before running analysis.                  "
   echo "                                  -V       Prints out the tool version.                                   "
   echo "                                  -h       Print this Help.                                               "
   echo "                                                                                                          "
   echo "==============================================================================================================="
}

while getopts ":hf:e:k:s:o:mV" flag;
do
    case "${flag}" in
        h) # Display Help Function
              usage
              exit;;
        f)
              FOLDER=${OPTARG}
        ;;
        e)
              EXTENSION=${OPTARG}
        ;;
        k)
              X=${OPTARG}
        ;;
        s)
              SNV_FIL=${OPTARG}
        ;;
        o)
              OUTFOLDER=${OPTARG}
        ;;
        m)
              MERGE="TRUE"
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

# num=$(echo "$SNV_FIL")

# Check if less than 0 or greater than 1 using OR (||) in bc
if [ $(echo "$num < 0 || $num > 1" | bc) -eq 1 ]; then
  show_error_dialog "Error: Value for SNV filter must be any number between 0 and 1."
  exit 1
fi

# Change directory to the script dir
cd "$SCRIPT_DIR" || exit

# Generate the input file in plink format
if [[ -z $OUTFOLDER ]]
  then
    OUT="$SCRIPT_DIR/results/ADMIXTURE"
  else
    OUT="$SCRIPT_DIR/results/$OUTFOLDER/ADMIXTURE"
fi

##### RUN PLINK #####
# Create folder to hold the PLINK binaries
make_dir "$OUT/plink_bin"

# Change to that directory
cd $SCRIPT_DIR/$FOLDER

# Loop over the files in $1 and extract file name and prepare PLINK binaries
for file in *."$EXTENSION"; do
      cd $SCRIPT_DIR/$FOLDER
      FNAME=${file%.*}
      prepare_binaries $SCRIPT_DIR/$FOLDER/$file $OUT $FNAME $SNV_FIL $EXTENSION
done

# # Creates a list of plink binary files to be used for de-duplicating
# echo "$OUT/plink_bin"
cd $OUT/plink_bin

##### MERGE FILES #####
if [ "$MERGE" = "TRUE" ]; then
  echo "Merging files..."

  bash $BASHSCRIPTS/create_plink_bin_list.sh "$OUT/plink_bin"
  FNAME=${FNAME%%[0-9]*}"_merged" # Creates a new file name for the merged files

  # Merges files based on the merge list
  "$TOOLSDIR/plink/plink" --merge-list merge_list.txt --make-bed --out $FNAME

  # Looks for a file with duplicated sample id's
  line_file="$OUT/plink_bin/$FNAME-merge.missnp"

  ##### REMOVE DUPLICATES #####
  # Check if the file with duplicates exists and processe them out, then recreates the PLINK binaries
  if [ -e "$line_file" ]; then

    bash $BASHSCRIPTS/remove_multialleles.sh "$line_file" "$SCRIPT_DIR/$FOLDER"

    rm -r "$SCRIPT_DIR/results"
    make_dir "$OUT/plink_bin"

    cd $SCRIPT_DIR/$FOLDER

    # Loop over the files in $1 and extract file name and prepare PLINK binaries
    for file in *."$EXTENSION"; do
          FNAME=${file%.*}
          prepare_binaries $SCRIPT_DIR/$FOLDER/$file $OUT $FNAME $SNV_FIL $EXTENSION
          cd $SCRIPT_DIR/$FOLDER
    done

    # for vcf_file in *.vcf; do
    #       echo $vcf_file
    #       FNAME=${vcf_file%.*}
    #
    #       prepare_binaries $SCRIPT_DIR/$FOLDER/$vcf_file $OUT $FNAME $SNV_FIL
    # done

    bash $BASHSCRIPTS/create_plink_bin_list.sh "$OUT/plink_bin"
    FNAME=${FNAME%%[0-9]*}"_merged"

    "$TOOLSDIR/plink/plink" --merge-list merge_list.txt --make-bed --out $OUT/plink_bin/$FNAME

  else
    echo "Warning: File line_file does not exist. Skipping merging process..."
  fi

else
  echo "Skipping merging..."

fi

mkdir $OUT/cv
cd $OUT/cv

# Checks the maximum available threads based on users processor and sets the
# the variable to that integer
nthrds=$(nproc)
j="-j$nthrds"

# FNAME=${FNAME%%[0-9]*}"_merged" # Creates a new file name for the merged files
# FNAME=${FNAME%%[0-9]*}
# Starts a loop for each 1 to K, so it caulculates and cross-validates ADMIXTURE proportions for all values of K
# echo $FNAME

##### RUN ADMIXTURE and evalAdmix #####
for K in $(seq 2 $X)
do
    "$TOOLSDIR/admixture/admixture32" --cv $OUT/plink_bin/$FNAME.bed $K $j | tee log${K}.out

    # Run evalAdmix on each K selected
    EVADMX_OUT=$OUT/cv/eval_admix_results/"k$K"

    make_dir $EVADMX_OUT

    "$EVADMX_PATH/evalAdmix" -plink $OUT/plink_bin/$FNAME -fname $OUT/cv/$FNAME.$K.P -qname $OUT/cv/$FNAME.$K.Q -P 6 -o $EVADMX_OUT/k${K}_output.corres.txt # Runs the evalAdmix script

    echo "Running rscripts..."

    Rscript $RSCRIPTS/visualise.R $OUT/plink_bin/$FNAME.fam $OUT/cv/$FNAME.$K.Q $EVADMX_OUT/k${K}_output.corres.txt $OUT/cv/eval_admix_results/ # Visualise the results

done

grep -h CV $OUT/cv/log*.out > $OUT/cv/final_cv_log.out # Aggregates the results into one file

# Redirects output to out.log and errors to error.log
# command > out.log 2> error.log
