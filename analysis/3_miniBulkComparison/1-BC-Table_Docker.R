if(!exists("usr")) usr <- list()

usr[["strategy"]] <- list("Stringent" = "MaxDev0", # name = Label, value = Path
                          "Reads" = "MinReads2",
                          "Clustered" = "Clustered_CD5",
                          "SC" = "MaxDev0/Clustered_CD5",
                          "SCR" = "MaxDev0/Clustered_CD5/MinReads2",
                          "CS" = "Clustered_CD5/MaxDev0",
                          "CSR" = "Clustered_CD5/MaxDev0/MinReads2")
usr[["seq"]] <- "ATCTATCCAGAAATCCTCTTTGCGACGGGAGACTAACCTTTTGATCT"

# ------- Docker edit ----- #
# usr[["files"]] <- choose.files(default = "", caption = "Select the raw files of the 1-BC sample", multi = TRUE)
args <- commandArgs(trailingOnly = TRUE)

# Function to check if the file is a .fna file and exists
check_and_add_file <- function(file_path) {
  if (grepl("\\.fna$", file_path) && file.exists(file_path)) {
    return(file_path)
  } else {
    warning(sprintf("The file '%s' is not a valid .fna file or does not exist.", file_path))
    return(NULL)
  }
}

# Apply the function to each argument and store the results
usr[["files"]] <- unlist(Filter(Negate(is.null), lapply(args, check_and_add_file)))
print(usr)
# ------------------------ #

df_data <- data.frame(matrix(NA, nrow=length(names(usr$strategy))+1, ncol=4, 
                             dimnames = list(c("Raw", names(usr$strategy)), c("Seq", "Seq_SD", "Reads", "Reads_SD"))))

for (x in c("Raw", names(usr$strategy))) {
  nseq <- c()
  nread <- c()
  for(i in seq(length(usr$files))) {
    if (x == "Raw") {
      fpath <- usr$files[i]
    } else {
      fpath <- file.path(dirname(usr$files[i]), usr$strategy[[x]], basename(usr$files[i])) 
    }
    file <- read.table(fpath, header=TRUE, stringsAsFactors = FALSE)
    file$Reads <- file$Reads/sum(file$Reads)
    nseq <- append(nseq, nrow(file))
    nread <- append(nread, file$Reads[file$Sequence == usr$seq])
  }
  df_data[x, "Seq"] <- mean(nseq)
  df_data[x, "Seq_SD"] <- sd(nseq)
  df_data[x, "Reads"] <- mean(nread)
  df_data[x, "Reads_SD"] <- sd(nread)
}

outputFileName <- "1-BC-Table.csv"
outputDir <- "/JD/docker/export"
outputFilePath <- file.path(outputDir, outputFileName)

write.csv2(df_data, file = outputFilePath, row.names = TRUE)
