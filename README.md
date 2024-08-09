# Autosomal-Pipeline

This is a pipeline of bash and R scripts, that allow the user to analyse a collection of .vcf data for potential ADMIXTURE proportions, determined by the putative K value. In addition, it evaluates the populations by using the [evalAdmix](https://github.com/GenisGE/evalAdmix) tool. 

**Instructions for use:**

<pre>
./run_adx -h (Displays the available options for running the pipeline) <br>
</pre>

Arguments:
<pre>
-f       The folder in which to look for the .vcf files. <br>
-k       An integer for the possible number of populations, minimum 2. <br>
-s       A number between 0 and 1 which represents how much the SNV mutations are filtered. <br>
-k       Number of guessed populations K (min is 2). <br>
-o       Set the name of the results folder. <br>
-m       Merges the vcf files before running analysis. <br>
-c       Computes and evaluates admixtures for only the specified integer. <br>
-h       Print this Help. <br>
</pre>


Examples:
```
  Basic run using **vcf** files with 0.001% filtering rate:
  ./run_adx -f path/to/vcf -e vcf -k 5 -s 0.999 -o path/to/save/results/in 

  Basic run using **ped** files with 0.001% filtering rate:
  ./run_adx -f path/to/vcf -e ped -k 5 -s 0.999 -o path/to/save/results/in

  To run the pipeline for multiple vcf files that need to be **merged** use the "-m" argument:
  ./run_adx -f path/to/vcf -e ped -k 5 -s 0.999 -o path/to/save/results/in -m
  
  Using the "compute" argument to save time by **skipping all K values except the selected**:
  ./run_adx -f ./path/to/vcf -e vcf -k 2 -s 0.999 -o path/to/save/results/in -mc

<pre>
./run_geomap -h (Displays the available options for running the pipeline) <br>
</pre>

Arguments:
<pre>
-k       Value selected for number of populations. <br>
-f       Path to the folder with all .Q files. <br>
-r       Path to the research cohort .Q file. <br>
-i       Path to the research cohort .fam file. <br>
-o       Path to the folder into which results are saved. <br>
-v       If set to 1, runs the software verbously. <br>
-V       Prints out the tool version. <br>
-h       Print this Help. <br>
</pre>


Examples:
```
  Basic run using example data:
  ./run_geomap.sh -k 5 -f example_data/reference_admixture/K5/ -r example_data/cohort_admixture/DNA35_validation/ -i results/cohort_admixture/DNA35_validation/

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

