usr_dev <- 0 # estim. based on stringent seq. only

### Functions

estPoolSize <- function(v, dev, use_variables) {
  # Estimates the pool size with the Chapman Estimator.
  #
  # Args:
  #   v: Vector with file paths of two [or three] replicates.
  # dev: highest dev allowed
  # use_variables: optional, default = FALSE, if TRUE: variable names passed in v instead of paths
  #
  # Returns:
  #   A vector with mean [and SD, if three replicates passed].
  num_reps <- length(v)
  if (num_reps < 2) stop("You need at least two replicates for the pool size
                         estimation!")
  if (missing(use_variables)) { use_variables <- FALSE }
  
  # Combinations
  combs <- combn(seq(num_reps), 2)
  num_combs <- ncol(combs)
  df <- data.frame(rbind(combs, matrix(NA, 4, num_combs)))
  colnames(df) <- seq(num_combs)
  rownames(df) <- c("x", "y", "seq_x", "seq_y", "seq_x-y", "Chapman")
  
  for (i in seq(ncol(df))) {
    if(!use_variables) {
      x <- read.table(v[df[1, i]], header = TRUE, stringsAsFactors = FALSE)
      y <- read.table(v[df[2, i]], header = TRUE, stringsAsFactors = FALSE)
    } else {
      x <- get(v[df[1, i]])
      y <- get(v[df[2, i]])
    }
    x <- x[x$Distance <= dev,]
    y <- y[y$Distance <= dev,]
    
    df["seq_x", i] <- nrow(x)
    df["seq_y", i] <- nrow(y)
    df["seq_x-y", i] <- nrow(merge(x, y, by = "Sequence"))
    df["Chapman", i] <- (((df["seq_x", i] + 1) * (df["seq_y", i] + 1)) / (df["seq_x-y", i] + 1)) - 1
  }
  vec <- as.numeric(df["Chapman", ])
  return(c(round(mean(vec), 0), round(sd(vec), 0)))
}

file_merge <- function(x, y) { #x and y as data.frames with columns "Sequence", "Reads, "Distance"
  z <- merge(x, y, by = "Sequence", all = TRUE)
  z$Reads <- apply(z[, grepl("Reads", colnames(z))], 1, function(x) sum(x, na.rm = TRUE))
  z$Distance <- apply(z[, grepl("Distance", colnames(z))], 1, function(x) 
    if(length(unique(x)) == 1) { x[1] } else {
      if(any(is.na(x))) { x[!is.na(x)] } else { warning("Some distances of identical sequences differed and were set to NA"); return(NA) }
    })
  z <- z[, c("Sequence", "Reads", "Distance")]
  return(z)
}

##

  args <- commandArgs(trailingOnly = TRUE)
  csv_file <- args[1]
  file_dir <- args[2]

#csv_file <- choose.files(default = "", caption = "Select csv sample alloc file", multi = FALSE)
csv_all <- read.csv(csv_file, header = TRUE, fileEncoding="UTF-8-BOM", stringsAsFactors = FALSE)
#file_dir <- choose.dir(default = "", caption = "Choose Preprocessing Directory")


df_out <- data.frame(matrix(NA, ncol=2, nrow=0))
colnames(df_out) <- c("Size", "SD")

# 1. Plasmids
csv_plasmids <- csv_all[!grepl("preTX", csv_all$Sample),]
for (i in seq(nrow(csv_plasmids))) {
  fpath <- file.path(file_dir, csv_plasmids$Run[i], "Reads", sprintf("ITRGB_%03d.fna", csv_plasmids$ID[i])) 
  if (csv_plasmids$Replicate[i] == 1) v_path <- fpath else v_path <- append(v_path, fpath)
  if (csv_plasmids$Replicate[i] == 3) {
    tmp <- estPoolSize(v_path, usr_dev)
    df_out <- rbind(df_out, data.frame(Size = tmp[1], SD = tmp[2]))
    rownames(df_out)[nrow(df_out)] <- csv_plasmids$Sample[i]
  }
}

# preTX internal (compare technical replicates)
csv_preTX <- csv_all[grepl("preTX", csv_all$Sample),]
for (i in seq(nrow(csv_preTX))) {
  fpath <- file.path(file_dir, csv_preTX$Run[i], "Reads", sprintf("ITRGB_%03d.fna", csv_preTX$ID[i])) 
  if (csv_preTX$Replicate[i] == 1) {
    v_path <- fpath
    df_merge <- read.table(fpath, header = TRUE, stringsAsFactors = FALSE)
  } else {
    v_path <- append(v_path, fpath)
    df_merge <- file_merge(df_merge, read.table(fpath, header = TRUE, stringsAsFactors = FALSE))
  }
  if (csv_preTX$Replicate[i] == 3) {
    tmp <- estPoolSize(v_path, usr_dev)
    df_out <- rbind(df_out, data.frame(Size = tmp[1], SD = tmp[2]))
    rownames(df_out)[nrow(df_out)] <- paste(csv_preTX[i, 1:2], collapse = "_")
    assign(paste(csv_preTX[i, 1:2], collapse = "_"), df_merge)
  }
}

# preTX external (compare merged replicates against each other)
for (i in unique(csv_preTX$Plasmid)) {
  tmp <- estPoolSize(paste0(unique(csv_preTX$Sample), "_", i), usr_dev, TRUE)
  df_out <- rbind(df_out, data.frame(Size = tmp[1], SD = tmp[2]))
  rownames(df_out)[nrow(df_out)] <- paste0(i, "_preTX")
}

outputFileName <- "Chapman-Estimation_Results.csv"
outputDir <- "/JD/docker/export"
outputFilePath <- file.path(outputDir, outputFileName)

# Check if the output directory exists; if not, create it
if (!dir.exists(outputDir)) {
  dir.create(outputDir, recursive = TRUE)
}

write.csv(df_out, file = outputFilePath, row.names = TRUE, quote = FALSE)
