# Autosomal-Pipeline

This is a pipeline of bash and R scripts, that allow the user to analyse a collection of .vcf data for potential ADMIXTURE proportions, determined by the putative K value. In addition, it evaluates the populations by using the [evalAdmix](https://github.com/GenisGE/evalAdmix) tool. 

Instructions for use:

<pre>
sh run_adx.sh -h (Displays the available options for running the pipeline) <br>
</pre>

Arguments:
<pre>
-f       The folder in which to look for the .vcf files. <br>
-k       An integer for the possible number of populations, minimum 2. <br>
-s       A number between 0 and 1 which represents how much the SNV mutations are filtered. <br>
</pre>


Examples:
<pre>
  Basic run using vcf files with 0.001% filtering rate:
  ./run_adx.sh -f path/to/vcf -e vcf -k 5 -s 0.999 -o path/to/save/results/in 

  Basic run using ped files with 0.001% filtering rate:
  ./run_adx.sh -f path/to/vcf -e ped -k 5 -s 0.999 -o path/to/save/results/in

  To run the pipeline for multiple vcf files that need to be merge use the "-m" argument:
  ./run_adx.sh -f path/to/vcf -e ped -k 5 -s 0.999 -o path/to/save/results/in -m
  
  Using the "compute" argument to save time by skipping all K values except the selected:
  ./run_adx.sh -f ./path/to/vcf -e vcf -k 2 -s 0.999 -o path/to/save/results/in -mc
</pre>


