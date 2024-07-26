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

fun_mode <- function(x) { # Return the mode (most frequent value)
  return(as.integer(names(sort(table(x), decreasing = TRUE))[1]))
}

comb.mean <- function(m, n) {
  # m = vector of means
  # n = weight, e.g. population sizes (same length as m)
  x <- 0
  for(i in seq(length(m))) {
    x <- x + m[i]*n[i]
  }
  x <- x/sum(n)
  return(x)
}

comb.sd <- function(m, n, s) {
  # m = vector of means
  # n = weight, e.g. population sizes (same length as m)
  # s = vector of SDs (same length as m)
  #d <- c()
  m_all <- comb.mean(m, n)
  x <- 0
  for(i in seq(length(m))) {
    #d <- append(d, m[i]-m_all)
    x <- x + n[i]*(s[i]^2+(m[i]-m_all)^2)
  }
  x <- sqrt(x/sum(n))
  return(x)
}


# usr_files <- choose.files(default = getFilePath("usr_files"), caption = "Select merged, CSR-treated preTX files", multi = TRUE)

# Docker Edit START -----------------

get_relevant_files <- function(directory_path) {
    # List all .fna files in the directory
    all_files <- list.files(path = directory_path, pattern = "\\.fna$", full.names = TRUE, recursive = FALSE)

    # Extract just the filenames from the full paths
    filenames <- basename(all_files)

    # Filter files where filenames start with 'Merged__'
    filtered_files <- all_files[grepl("^Merged__preTX_", filenames)]

    return(filtered_files)
}

# Assuming 'args' contains paths to directories
args <- commandArgs(trailingOnly = TRUE)
usr_files <- get_relevant_files(args[1])

# Docker Edit END -------------------



df <- data.frame(matrix(NA, ncol=6, nrow=length(usr_files), dimnames = list(gsub("\\.|-", "", substr(basename(usr_files), 15, 19)), 
                                                                            c("Barcodes", "Reads", "Reads_SD", "Mode", "BC_10", "BC_highest"))),
                 stringsAsFactors = FALSE)


for(i in seq(length(usr_files))) {
  file <- read.table(usr_files[i], header = TRUE, stringsAsFactors = FALSE)
  df[i, ] <- data.frame(Barcodes = nrow(file), Reads = mean(file$Reads),
                             Reads_SD = sd(file$Reads), Mode = fun_mode(file$Reads),
                             BC_10 = nrow(file[file$Reads <= 10,])/nrow(file),
                             BC_highest = max(file$Reads)/sum(file$Reads))
	# print(paste("max:",max(file$Reads),"of",sum(file$Reads)))
}

df <- rbind(df, data.frame(Barcodes = mean(df$Barcodes), Reads = comb.mean(df$Reads, rep(1,3)),
                           Reads_SD = comb.sd(df$Reads, rep(1,3), df$Reads_SD), Mode = mean(df$Mode),
                           BC_10 = mean(df$BC_10), BC_highest = mean(df$BC_highest)))
rownames(df)[nrow(df)] <- "Mean"

cat("\n\n\nGeneral library statistics:",
    "\nTotal unique barcodes in merged preTX ( SD ):", round(df["Mean", "Barcodes"], 0), "(", round(sd(df[1:3, "Barcodes"]), 0), ")",
    "\nMean ( SD ) reads:", round(df["Mean", "Reads"], 2), "(", round(df["Mean", "Reads_SD"], 2), ")",
    "\nMode value of reads ( Range ):", round(df["Mean", "Mode"],0),
    "\n% of barcodes with <= 10 reads:", round(df["Mean", "BC_10"], 5)*100, "%",
    "\n% constitution of the barcode with the highest reads:", round(df["Mean", "BC_highest"], 6)*100, "%\n\n\n")

