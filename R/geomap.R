#---- Requirements ----
# List of package names
packages <- c("here", "tibble", "ggplot2", "dplyr", "tidyr", "docopt")

# Loop through the list and load each package
for (pkg in packages) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
    library(pkg, character.only = TRUE)
  }
}

#---- Functions ----
# Function that fins all .Q files in a given folder and reads them
readQFiles <- function(qfolder){
  # qfolder <- here('results', 'reference_admixture', 'K2')  # Replace with your actual folder path
  
  # List all .Q files in the folder
  qfiles <- list.files(qfolder, pattern = "\\.Q$", full.names = TRUE)
  
  # Read each .Q file as a table and store in a list
  admxs <- lapply(qfiles, read.table)  # Adjust 'header' as needed
  
  # Optional: Name the list elements with the file names (without extensions)
  names(admxs) <- sub("\\.Q$", "", sub("\\..*$", "", basename(qfiles)))
  
  return(admxs)
}
# Function that constructs a dataframe of colmeans
construct.df <- function(qColMeans){
  df <- as.data.frame(do.call(rbind, qColMeans))
  df <- tibble::rownames_to_column(as.data.frame(df), "Population")
  
  return(df)
}
# Function to calculate Euclidean distance
euclidean_distance <- function(vec1, vec2) {
  sqrt(sum((vec1 - vec2) ^ 2))
}
# Function that annotates admixture proportions based on distances
getMappings <- function(research_cohort, reference_averages, verbose){
  # Initialize a matrix to store distances
  distances <- matrix(NA, nrow = nrow(research_cohort), ncol = nrow(reference_averages))
  colnames(distances) <- ref.admxs$Population
  
  # Initialise an empty list to store results in
  res <- list()
  
  ### CLOSEST INDIVIDUAL ###
  # Calculate distances for each individual in the research cohort
  for (i in 1:nrow(research_cohort)) {
    for (j in 1:nrow(reference_averages)) {
      distances[i, j] <- euclidean_distance(research_cohort[i, ], as.numeric(reference_averages[j, 2:ncol(reference_averages)]))
    }
  }
  if(verbose){
    print("Euclidean Distances:")
    print(distances)
  }
  
  
  res$distances <- distances
  ### CLOSEST POPULATION ###
  # Initialize a matrix to store the closest reference population for each admixture component
  closest_population <- matrix(NA, nrow = nrow(research_cohort), ncol = ncol(research_cohort))
  colnames(closest_population) <- paste("Component", 1:ncol(research_cohort), sep = "_")
  
  # Find the closest reference population for each admixture component of each individual
  for (i in 1:nrow(research_cohort)) {
    for (k in 1:ncol(research_cohort)) {
      distances <- sapply(1:nrow(reference_averages), function(j) euclidean_distance(research_cohort[i, k], reference_averages[j, k + 1]))
      closest_population[i, k] <- reference_averages$Population[which.min(distances)]
    }
  }
  
  if(verbose){
    print("Closest Reference Population for Each Component:")
    print(closest_population)
  }
  
  
  res$closest_population <- closest_population
  
  return(res)
}
# Function that plots admixture proportions with annotated labels
plotAdmix <- function(q, pop=NULL, ord=NULL, inds=NULL,
                      colorpal=c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3", "#FF7F00", "#FFFF33", "#A65628", "#F781BF", "#999999"),
                      main="Admixture proportions",
                      cex.main=1.5, cex.lab=1, rotatelab=0, padj=0, cex.inds=1,
                      drawindslines=TRUE) {
  # Simple function to plot admixture proportions with optional component labels
  
  k <- ncol(q)
  
  if (k > length(colorpal))
    warning("Not enough colors for all Ks in palette.")
  
  if (is.null(ord) & !is.null(pop)) ord <- order(pop)
  if (is.null(ord) & is.null(pop)) ord <- 1:nrow(q)
  
  layout(matrix(c(1, 2), nrow = 1), widths = c(4, 1))
  
  par(mar = c(8, 4, 4, 2))  # Adjust margins for the main plot
  
  barplot(t(q)[,ord], col=colorpal, space=0, border=NA, cex.axis=1.2, cex.lab=1.8,
          ylab="Admixture proportions", xlab="", main=main, cex.main=cex.main, xpd=NA)
  
  if (!is.null(inds)) {
    # text(x = seq_along(labels), y = -0.1, srt = 45, adj = 1, xpd = TRUE, cex = 0.8)
    text(x = 1:nrow(q) - 0.5, -0.1, inds[ord], xpd=NA, srt=45, adj = 1, 
         xpd = TRUE, cex=cex.inds)
  }
  
  if (!is.null(pop)) {
    text(sort(tapply(1:length(pop), pop[ord], mean)), -0.05 - padj, unique(pop[ord]), 
         srt=rotatelab, adj = 1, xpd=NA, cex=cex.inds)
    
    if (drawindslines) abline(v = 1:nrow(q), col = "white", lwd = 0.2)
    abline(v = cumsum(sapply(unique(pop[ord]), function(x) { sum(pop[ord] == x) })), col = 1, lwd = 1.2)
  }
  
}
# Getter function for the reference cohort
getReference <- function(qfolder, verbose){
  ref.admxs <- list()
  ref.admxs$Qvalues <- readQFiles(qfolder)
  ref.admxs$Population <- names(ref.admxs$Qvalues)
  
  # Calculate average admixture proportions for each reference population
  ref.admxs$colMeans <- lapply(ref.admxs$Qvalues, colMeans)

  # Construct a reference averages data frame
  ref.admxs$ref.avg <- construct.df(ref.admxs$colMeans)
  
  if(verbose){
    print("Reference Population Averages:")
    print(ref.admxs$ref.avg)
  }
  
  return(ref.admxs)
}

# Getter function for the research cohort
getResearch <- function(qfolder, idx.folder){
  res.admxs <- list()
  res.admxs$Qvalues <- readQFiles(qfolder)
  
  fname <- basename(qfolder)
  
  res.admxs$id <- read.table(here(idx.folder, paste0(fname, ".fam")))[1]
  
  return(res.admxs)
}

#---- Header ----
"Autosomal Pipeline - Geolocational Computing

Usage: geomap.R [options]

Options:
  -h --help                     Show this screen.
  -k --k_pops=<INT>             Value selected for number of populations.
  -f --ref_qolder=<PATH>        Path to the folder with all reference .Q files.
  -r --res_qfolder=<PATH>       Path to the research cohort .Q file.
  -i --famfile=<FILE>           Path to the research cohort .fam file.
  -o --outfolder=<PATH>         Path to the folder into which results are saved.
  -v --verbose=<BOOLEAN>        If set to 1, prints messages verbously.
  -V --version
"-> doc

#---- Arguments ----
arguments <- docopt(doc, quoted_args = TRUE, help = TRUE)
print(arguments)

K           <- as.integer(arguments$k_pops)
ref.qfolder <- normalizePath(arguments$ref_qolder)
res.qfolder <- normalizePath(arguments$res_qfolder)
idx.folder  <- normalizePath(arguments$famfile)
outfolder   <- normalizePath(arguments$outfolder)
verbose     <- as.integer(arguments$verbose)

if(as.integer(arguments$verbose) == 1){
  verbose <- T
} else{
  verbose <- F
}

#---- Main ----
# Read in the research and reference Q files
ref.admxs <- getReference(ref.qfolder, verbose)
res.admxs <- getResearch(res.qfolder, idx.folder)

# Annotate with geographical information based on E. distances
research_cohort <- res.admxs$Qvalues[[1]]
reference_averages <- ref.admxs$ref.avg

geoannots <- getMappings(research_cohort, reference_averages, verbose)
geoannots$distances <- data.frame("SampleID" = res.admxs$id$V1, geoannots$distances)
geoannots$closest_population <- data.frame("SampleID" = res.admxs$id$V1, geoannots$closest_population)

# Graph the annotations
component_labels <- geoannots$closest_population

l.labels <- ref.admxs$Population
png(here(outfolder, 'admrxs_mapped.png'), width = 800, height = 600)
par(mar = c(8, 4, 4, 2))  # Bottom, Left, Top, Right
plotAdmix(q = res.admxs$Qvalues[[1]], pop = res.admxs$id[[1]], rotatelab = 45)
colorpal <-c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3", "#FF7F00", "#FFFF33", "#A65628", "#F781BF", "#999999")
par(mar = c(5, 0.5, 4, 2))  # Adjust margins for the legend
plot.new()
legend("center", legend = l.labels, fill = colorpal[1:K], cex = 1, bty = "n")
dev.off()

# Write out geomaps
write.csv(geoannots$closest_population, here(outfolder, 'closest_population.csv'), row.names = F)
write.csv(geoannots$distances, here(outfolder, 'distances.csv'), row.names = F)


