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


# Assuming 'args' contains paths to directories
args <- commandArgs(trailingOnly = TRUE)
usr_files <- c()

# List all files recursively within the base directory
all_files <- list.files(args[1], recursive = TRUE, full.names = TRUE)

# Iterate over all files and save the ones that match the pattern "PB_83d_"
for (file in all_files) {
  if (grepl("PB_83d_Merged-.*\\.fna$", basename(file))) {
    usr_files <- c(usr_files, file)
  }
}

# Print the result
print(usr_files)

# Docker Edit END -------------------

row_names <- sapply(strsplit(usr_files, "/"), function(x) x[7])

df <- data.frame(matrix(NA, ncol = 6, nrow = length(usr_files),
                        dimnames = list(row_names, 
                                        c("Barcodes", "Reads", "Reads_SD", "Mode", "BC_10", "BC_highest"))),
                 stringsAsFactors = FALSE)


for(i in seq(length(usr_files))) {
  file <- read.table(usr_files[i], header = TRUE, stringsAsFactors = FALSE)
  df[i, ] <- data.frame(Barcodes = nrow(file), Reads = mean(file$Reads),
                             Reads_SD = sd(file$Reads), Mode = fun_mode(file$Reads),
                             BC_10 = nrow(file[file$Reads <= 10,])/nrow(file),
                             BC_highest = max(file$Reads)/sum(file$Reads))
}

# print(df)

df <- rbind(df, data.frame(Barcodes = mean(df$Barcodes), Reads = comb.mean(df$Reads, rep(1,nrow(df))),
                           Reads_SD = comb.sd(df$Reads, rep(1,nrow(df)), df$Reads_SD), Mode = mean(df$Mode),
                           BC_10 = mean(df$BC_10), BC_highest = mean(df$BC_highest)))
rownames(df)[nrow(df)] <- "Mean"

# print(df)

cat("\n\n\nGeneral library statistics:",
    "\nTotal unique barcodes in merged 83d files ( SD ):", round(df["Mean", "Barcodes"], 0), "(", round(sd(df[1:3, "Barcodes"]), 0), ")",
    "\nMean ( SD ) reads:", round(df["Mean", "Reads"], 2), "(", round(df["Mean", "Reads_SD"], 2), ")",
    "\nMode value of reads ( Range ):", round(df["Mean", "Mode"],0),
    "\n% of barcodes with <= 10 reads:", round(df["Mean", "BC_10"], 5)*100, "%",
    "\n% constitution of the barcode with the highest reads:", round(df["Mean", "BC_highest"], 6)*100, "%\n\n\n")

