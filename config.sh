#!/bin/bash

# config.cfg
echo "Loading configurations..."

# Get the directory of the script
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Initialize the directory with the R scripts
RSCRIPTS="$SCRIPT_DIR/R"
BASHSCRIPTS="$SCRIPT_DIR/BASH"
TOOLSDIR="$SCRIPT_DIR/tools"
EVADMX_PATH="$TOOLSDIR/evalAdmix"

# Constants
num=$(echo "$SNV_FIL")
