# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# + Run indices  - Version 1.1 - 23. June 2016 - Jannik Daudert +
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#Total Reads in the Run Statistics
TotalReads <- 3792322

#Percentage of Sequences that moved to dumb in Perl preprocessing in %
PercDumb <- 70.96

#Used Index Barcodes
UsedBarcodes <- 100


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# +                    DON'T CHANGE BELOW                      +
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  Perc <- 1-(PercDumb/100)

  ReadsPerFile <- TotalReads*Perc/UsedBarcodes

  # Create Summary Table
  SummaryTable <- data.frame("File" = factor(), "Reads" = numeric(), "ReadsOfRun" = numeric(), "IndexRun"= numeric(), "ReadsOfDir" = numeric(), "IndexDir" = numeric())

  # File Selection -----------------------------------------------
  #FilePath <- choose.dir(default = getwd(), caption = "Choose directory with files")
  
  args <- commandArgs(trailingOnly = TRUE)
  FilePath <- args[1]
  
  Files <- list.files(FilePath, pattern=".fna")
  
  # Loop for all selected Files ----------------------------------
  for(a in seq(length(Files))) {
    FileName = basename(Files[a])

    # Read File
    File <- read.table(paste(FilePath,FileName, sep="/"), header=TRUE)
    
    SummaryTable <- rbind(SummaryTable, data.frame(File=FileName, Reads=sum(File$Reads), ReadsOfRun=(sum(File$Reads)/(TotalReads*Perc)), IndexRun=round(sum(File$Reads)/ReadsPerFile,2), ReadsOfDir=0, IndexDir=0))

  }

  IndexDirTemp <- sum(SummaryTable$Reads)/length(Files)
  
  # Calculate Reads of Directory
  for(a in seq(nrow(SummaryTable))) {
    SummaryTable$ReadsOfDir[a] <- SummaryTable$Reads[a]/sum(SummaryTable$Reads)
    
    SummaryTable$IndexDir[a] <- round(SummaryTable$Reads[a]/IndexDirTemp,2)
  }
  write.csv(SummaryTable, file=paste(dirname(FilePath),"Reads-Distribution_en.csv",sep="/"), row.names = FALSE)
  write.csv2(SummaryTable, file=paste(dirname(FilePath),"Reads-Distribution_de.csv",sep="/"), row.names = FALSE)
  