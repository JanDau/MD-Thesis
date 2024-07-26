library(dplyr)
if(!exists("usr")) usr <- list()

###

usr[["strategy"]] <- list("Stringent" = "MaxDev0", # name = Label, value = Path
                          "Reads" = "MinReads2",
                          "Clustered" = "Clustered_CD5",
                          "SC" = "MaxDev0/Clustered_CD5",
                          "SCR" = "MaxDev0/Clustered_CD5/MinReads2",
                          "CS" = "Clustered_CD5/MaxDev0",
                          "CSR" = "Clustered_CD5/MaxDev0/MinReads2") # cave: Raw always included
usr[["nseq"]] <- 6 # number of known sequences (1 or 6)
usr[["equal"]] <- FALSE # for the 6-seq-spike ins, set TRUE for the equally-distributed files
usr[["lib"]] <- list("A" = list(Sequence = "ATCTACGCACGTAGACCCTTCACGACCCTAACGGACGCTTATGATCT", #Ven3
                              Perc = 0.557041833),
                     "B" = list(Sequence = "ATCTACACACTCAGAAACTTATCGAGGCTAGTGGAATCTTTTGATCT", #Ven1
                              Perc = 0.24923572),
                     "C" = list(Sequence = "ATCTACCCTAAACAGAACTTATCGAGCCTATGCTTTCGGAACGATCT", #mCh3
                              Perc = 0.111514863),
                     "D" = list(Sequence = "ATCTACGCTAGTCAGGACTTCCCGATGCTAACCTTGCGGAGAGATCT", #mCh2
                              Perc = 0.049894793),
                     "E" = list(Sequence = "ATCTAGCCAGATATCCACTTTACGATCGGAGCCTATGCTTGTGATCT", #Cer3
                              Perc = 0.022324292),
                     "F" = list(Sequence = "ATCTATCCAGAAATCCTCTTTGCGACGGGAGACTAACCTTTTGATCT", #Cer2, 1-BC
                              Perc = 0.009988498))
  
###

# usr[["files"]] <- choose.files(default = "", caption = "Select the raw files", multi = TRUE)


# ------- Docker edit ----- #
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


if (usr$nseq == 1) {
  for(i in seq(length(usr$files))) {
    l_data <- list()
    for (x in c("Raw", names(usr$strategy))) {
      if (x == "Raw") {
        fpath <- usr$files[i]
      } else {
        fpath <- file.path(dirname(usr$files[i]), usr$strategy[[x]], basename(usr$files[i])) 
      }
      file <- read.table(fpath, header=TRUE, stringsAsFactors = FALSE)
      l_data[[x]] <- list("nseq" = nrow(file),
                          "perc" = file$Reads[file$Sequence == usr$lib$F$Sequence]/sum(file$Reads),
                          "sensitivity" = nrow(file[file$Sequence == usr$lib$F$Sequence,])/usr$nseq)
      l_data[[x]][["specificity"]] <- 1-(nrow(file)-usr$nseq)/(l_data$Raw$nseq-usr$nseq)
      l_data[[x]][["precision"]] <- file$Reads[file$Sequence == usr$lib$F$Sequence]/sum(file$Reads)
    }
    # csv export
    df <- data.frame(matrix(NA, length(names(l_data)), 5))
    colnames(df) <- names(l_data$Raw)
    rownames(df) <- names(l_data)
    for (x in seq(length(names(l_data)))) df[x, ] <- unlist(l_data[[x]], use.names = FALSE)
    # write.csv(df, file=paste0(strsplit(basename(usr$files)[i], ".fna")[[1]], ".csv"))
	
	
	outputFileName <- paste0(strsplit(basename(usr$files)[i], ".fna")[[1]], ".csv")
	outputDir <- "/JD/docker/export"
	outputFilePath <- file.path(outputDir, outputFileName)

	write.csv2(df, file = outputFilePath, row.names = TRUE)
	
  }
} else {
  for(i in seq(length(usr$files))) {
    l_data <- list()
    for (x in c("Raw", names(usr$strategy))) {
      if (x == "Raw") {
        fpath <- usr$files[i]
      } else {
        fpath <- file.path(dirname(usr$files[i]), usr$strategy[[x]], basename(usr$files[i])) 
      }
      file <- read.table(fpath, header=TRUE, stringsAsFactors = FALSE)
      l_data[[x]] <- list("nseq" = nrow(file))
      file$Reads <- file$Reads/sum(file$Reads)
      
      seq_tmp <- sapply(usr$lib, "[[", 1)
      file <- filter(file, Sequence %in% seq_tmp)
      l_data[[x]][["pseq"]] <- nrow(file)
      for (y in 1:6) file$Sequence <- gsub(seq_tmp[y], names(seq_tmp)[y], file$Sequence)
      file <- file[order(file$Sequence),]
      
      file$Diff <- NA
      file$Prec <- NA
      if(usr$equal == TRUE) {
        perc_tmp <- rep(100/6/100,6)
      } else {
        perc_tmp <- sapply(usr$lib, "[[", 2)
      }
      for (y in 1:6) file$Diff[y] <- file$Reads[y]-perc_tmp[y]
      for (y in 1:6) file$Prec[y] <- (perc_tmp[y]-abs(file$Reads[y]-perc_tmp[y]))/perc_tmp[y]
      
      file <- select(file, -Distance)

      l_data[[x]][["Data"]] <- file
      l_data[[x]][["sensitivity"]] <- nrow(file)/usr$nseq
      l_data[[x]][["specificity"]] <- 1-(l_data[[x]]$nseq-usr$nseq)/(l_data$Raw$nseq-usr$nseq)
      l_data[[x]][["precision"]] <- c("Mean" = mean(file$Prec), "SD" = sd(file$Prec))
      
    }
    # csv export
    df <- data.frame(matrix(NA, length(names(l_data)), 7))
    colnames(df) <- c("nseq", "Diff_Mean", "Diff_SD", "sensitivity", "specificity", "precision", "precision_SD")
    rownames(df) <- names(l_data)
    
    for (x in seq(length(names(l_data)))) {
      df[x, ] <- c(l_data[[x]]$nseq,
                   round(mean(abs(l_data[[x]]$Data$Diff)),6),
                   round(sd(abs(l_data[[x]]$Data$Diff)),6),
                   l_data[[x]]$sensitivity,
                   l_data[[x]]$specificity,
                   l_data[[x]]$precision[1],
                   l_data[[x]]$precision[2])
    }
    # write.csv(df, file=paste0(strsplit(basename(usr$files)[i], ".fna")[[1]], ".csv"))
	
	
	outputFileName <- paste0(strsplit(basename(usr$files)[i], ".fna")[[1]], ".csv")
	outputDir <- "/JD/docker/export"
	outputFilePath <- file.path(outputDir, outputFileName)

	write.csv2(df, file = outputFilePath, row.names = TRUE)

  }
}