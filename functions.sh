#!/bin/bash

# Functions
echo "Loading functions..."

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
    EXTENSION=$5

    make_dir "$OUT/plink_bin"

    run_plink() {

        FILE=$1
        OUT=$2
        FNAME=$3
        EXTENSION=$4

        echo "Creating raw binaries using PLINK..."

        if [ "$EXTENSION" = "bed" ]
          then
           echo "The file is .bed... not implemented yet."
           echo $FNAME
           # $TOOLSDIR/plink/plink --vcf $FILE --make-bed --out $OUT/plink_bin/$FNAME --allow-extra-chr

           files=$(dirname "/home/jr453-omen/bioinf-tools/pipelines/Autosomal-Pipeline/reference_admixture/data/HapMap3/hapmap3.bed")
           cp $files/$FNAME.* $OUT/plink_bin

         elif [ "$EXTENSION" = "vcf" ]
          then
           echo "The file is .vcf"
           $TOOLSDIR/plink/plink --vcf $FILE --make-bed --out $OUT/plink_bin/$FNAME --allow-extra-chr

         elif [ "$EXTENSION" = "ped" ]
          then
            echo "The file is .ped"
            echo $FNAME

            $TOOLSDIR/plink/plink --file $FNAME --make-bed --out $OUT/plink_bin/$FNAME --allow-extra-chr
        fi
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

    run_plink $FILE $OUT $FNAME $EXTENSION

    cd "$OUT/plink_bin/"

    filter_snp $FNAME $SNV_FIL

    rename_chr $FNAME
}
extract_extension() { # Function to extract file extension
  local filename=$1
  echo "${filename%.*}"
}
check_extension(){
  local extension=$1

  # Check if the extension is the same as the filename (no extension case)
  if [ "$extension" = "$filename" ]; then
    echo "The file has no extension. Exiting..."
    exit 1
  else
    echo "$extension"
  fi
}
