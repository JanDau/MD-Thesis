usr_dev <- 0 # estim. based on stringent seq. only

# Docker edit ---
  args <- commandArgs(trailingOnly = TRUE)
  usr_dir <- args[1]
  
# List all files in the directory
all_files <- list.files(path = usr_dir, full.names = TRUE)
# print(all_files)

# Filter files that start with "Merged_CS_preTX_"
filenames <- basename(all_files)
files <- all_files[grepl("^Merged_CS_preTX_", filenames)]
# print(files)
# ---------------


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

# files <- choose.files(default = "", caption = "Select merged-CS preTX files", multi = TRUE)
#if(!exists("df_out")) {
  df_out <- data.frame(matrix(NA, ncol=2, nrow=0))
  colnames(df_out) <- c("Size", "SD")
#}

tmp <- estPoolSize(files, usr_dev)
df_out <- rbind(df_out, data.frame(Size = tmp[1], SD = tmp[2]))
rownames(df_out)[nrow(df_out)] <- basename(files)[1]

#write.csv(df_out, file = paste0("Chapman_", regmatches(files[1],regexpr("(Human|Mouse)",files[1])), "-CS.csv"), row.names = TRUE, quote = FALSE)

print(paste0("Library size: ", df_out$Size, " (+/- ", df_out$SD, ")"))
