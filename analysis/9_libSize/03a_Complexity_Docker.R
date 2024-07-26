# getFilePath <- function(v_files) {
  # # Extracts the dirname of the first element of x.
  # #
  # # Args:
  # #   v_files: Variable name (as character) of vector with file paths.
  # #
  # # Returns:
  # #   Directory path as a string.
  # if(missing(v_files) || !exists(v_files)) return(file.path(getwd(), "."))
  # x <- get(v_files)
  # if(length(x) == 0) return(file.path(getwd(), "."))
  # path <- ifelse(nchar(dirname(x[1])) > 3, file.path(dirname(x[1]), "."), paste0(dirname(x[1]), "*.*"))
  # return(path)
# }

calc_evenness <- function(f) {
  # x = df with columns "Sequence", "Reads" and "Distance"
  #f <- read.table(paste(x), header = TRUE, stringsAsFactors = FALSE)
  if(is.vector(f)) {
    
  } else {
    f$Percentage <- f$Reads/sum(f$Reads)
    f$PercLog <- f$Percentage*log(f$Percentage)
    return(list("Shannon" = -sum(f$PercLog), 
                "Rows" = nrow(f),
                "Complexity" = exp(-sum(f$PercLog)),
                "Equitability" = (-sum(f$PercLog))/log(nrow(f)))
    )
  }
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

extract_name <- function(x) { #x = path as string
  return(regmatches(x,regexpr("(preTX_)?SF-(3T|T|3)#?[1-5]?",x)))
}

estim_chao_var <- function(x, y) {
  # Estimates the pool size with the Chao Estimator. Requires dplyr.
  #
  # Args: x, y: data.frames with headers Sequence, Reads, Distance
  #
  # Returns:
  #   A vector with mean and SD.
  library(dplyr)
  if(missing(x) & missing(y)) stop("You need at two data.frames for the pool size estimation!")
  
  df <- data.frame(matrix(NA, nrow = 10, ncol = 1, 
                          dimnames = list(c("x", "y", "f10", "f01", "f11", "f1", "f2", "n", "size", "sd"), 1)))
  
  i <- 1
  shared <- intersect(x$Sequence, y$Sequence)
  df["f10", i] <- length(setdiff(x$Sequence, shared))
  df["f01", i] <- length(setdiff(y$Sequence, shared))
  df["f11", i] <- length(shared)
  df["f1", i] <- df["f10", i] + df["f01", i]
  df["f2", i] <- df["f11", i]
  df["n", i] <- df["f1", i] + df["f2", i]
  df["size", i] <- round(df["n", i] + ((df["f1", i]^2)/(4*df["f2", i])),0)
  df["sd", i] <- round(sqrt(((df["f1", i]^2)/(4*df["f2", i]))*((df["f1", i]/(2*df["f2", i]))+1)^2),0)
  
  return(c("Size" = as.numeric(df["size", ]), "SD" = as.numeric(df["sd", ])))
}

###

# usr_files <- choose.files(default = getFilePath("usr_files"), caption = "Select merged, CSR-treated files", multi = TRUE)

args <- commandArgs(trailingOnly = TRUE)
usr_dir <- args[1]

# List all files in the directory with a specific extension and exclude subdirectories
temp_files <- list.files(path = usr_dir, pattern = "^Merged__.*\\.fna$", full.names = TRUE, recursive = FALSE)

# Separate preTX files and other files
preTX_files <- temp_files[grepl("preTX", temp_files)]
other_files <- temp_files[!grepl("preTX", temp_files)]

# Sort the files
preTX_files <- sort(preTX_files)
other_files <- sort(other_files)

# Combine preTX files at the beginning
usr_files <- c(preTX_files, other_files)

# Print the ordered files
print(usr_files)


usr_cohort <- regmatches(dirname(usr_files[1]),regexpr("(?i)(Human|Mouse)",dirname(usr_files[1])))



df <- data.frame(matrix(NA, ncol=4, nrow=length(usr_files), dimnames = list(extract_name(basename(usr_files)), 
                                                                            c("Rows", "Shannon", "Complexity", "Chao"))),
                 stringsAsFactors = FALSE)

for(i in seq(length(usr_files))) {
  cat("\rFile", i, "of", length(usr_files))
  if(i == 1) {
    file <- read.table(usr_files[i], header = TRUE, stringsAsFactors = FALSE)
    file$Reads <- 1
    df$Chao[i] <- nrow(file)
  } else {
    fileTemp <- read.table(usr_files[i], header = TRUE, stringsAsFactors = FALSE)
    fileTemp$Reads <- 1
    df$Chao[i] <- estim_chao_var(file, fileTemp)["Size"]
    file <- file_merge(file, fileTemp)
  }
  df$Rows[i] <- calc_evenness(file)$Rows
  df$Shannon[i] <- calc_evenness(file)$Shannon
  df$Complexity[i] <- calc_evenness(file)$Complexity
  
}
rm(i, file)

# df[nrow(df)+1,] <- apply(df, 2, mean)
# df[nrow(df)+1,] <- apply(df, 2, sd)
# df[nrow(df)+1,] <- nrow(df)-2
# rownames(df)[(nrow(df)-2):nrow(df)] <- c("Mean", "SD", "N")

plot(x = 1:nrow(df), y = df$Chao, col = "red")
lines(x = 1:nrow(df), y = df$Complexity, col = "blue")
lines(x = 1:nrow(df), y = df$Rows, col = "green")

# fname <- paste0("Complexitiy_", format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".csv")
# write.csv(df, file=fname)


outputFileName <- paste0(usr_cohort, "_Complexity_", format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".csv")
outputDir <- "/JD/docker/export"
outputFilePath <- file.path(outputDir, outputFileName)

# Check if the output directory exists; if not, create it
if (!dir.exists(outputDir)) {
dir.create(outputDir, recursive = TRUE)
}

write.csv2(df, file=outputFilePath)
