source("/home/jr453/bioinf-tools/workshop/evalAdmix/visFuns.R")
library(here)

# Retrieve command-line arguments
args <- commandArgs(trailingOnly = TRUE)

# Extract arguments
pop.p <- normalizePath(args[1]) # GT13_Data.vcf.fam
q.p   <- normalizePath(args[2]) # GT13_Data.vcf.1.Q
r.p   <- normalizePath(args[3]) # output.corres.txt

# pop.p <- "/home/jr453/bioinf-tools/pipelines/Autosomal-Pipeline/results/ADMIXTURE/plink_bin/GT_merged.fam"
# q.p   <- "/home/jr453/bioinf-tools/pipelines/Autosomal-Pipeline/results/ADMIXTURE/cv/GT_merged.2.Q"
# r.p   <- "/home/jr453/bioinf-tools/pipelines/Autosomal-Pipeline/results/ADMIXTURE/cv/eval_admix_results/k2/k2_output.corres.txt"

pop <- as.vector(read.table(pop.p)$V1) # N length character vector with each individual population assignment
q <- as.matrix(read.table(q.p)) # admixture porpotions q is optional for visualization but if used for ordering plot might look better
r <- as.matrix(read.table(r.p))

# pop <- as.vector(read.table("/home/jr453/bioinf-tools/pipelines/autosomal-pipeline/ADMIXTURE/result/filtered/GT13.fam")$V1) # N length character vector with each individual population assignment
# q <- as.matrix(read.table("/home/jr453/bioinf-tools/pipelines/autosomal-pipeline/ADMIXTURE/cv/filtered/GT13.4.Q")) # admixture porpotions q is optional for visualization but if used for ordering plot might look better
# r <- as.matrix(read.table("/home/jr453/bioinf-tools/pipelines/autosomal-pipeline/ADMIXTURE/evalAdmx_results/filtered/k4/k4_output.corres.txt"))


ord <- orderInds(pop=pop, q=q) # ord is optional but this make it easy that admixture and correlation of residuals plots will have individuals in same order

png(here('ADMIXTURE', 'cv', 'eval_admix_results', 'admix_plot.png'))
plotAdmix(q=q, pop=pop, ord=ord)
dev.off()

png(here('ADMIXTURE', 'cv', 'eval_admix_results', 'corr_plot.png'))
plotCorRes(cor_mat = r, pop = pop, ord=ord, title = "Admixture evaluation as correlation of residuals", max_z=0.25, min_z=-0.25)
dev.off()

