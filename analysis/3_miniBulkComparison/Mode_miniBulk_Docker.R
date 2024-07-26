usr_seq <- c("ATCTACGCACGTAGACCCTTCACGACCCTAACGGACGCTTATGATCT",
             "ATCTACACACTCAGAAACTTATCGAGGCTAGTGGAATCTTTTGATCT",
             "ATCTACCCTAAACAGAACTTATCGAGCCTATGCTTTCGGAACGATCT",
             "ATCTACGCTAGTCAGGACTTCCCGATGCTAACCTTGCGGAGAGATCT",
             "ATCTAGCCAGATATCCACTTTACGATCGGAGCCTATGCTTGTGATCT",
             "ATCTATCCAGAAATCCTCTTTGCGACGGGAGACTAACCTTTTGATCT")

fun_mode <- function(x, null.rm) { # Return the mode (most frequent value)
  null.rm <- ifelse(missing(null.rm), FALSE, null.rm)
  if(is.data.frame(x)) x <- unlist(x, use.names = FALSE)
  if(null.rm) x <- x[x>0]
  return(as.integer(names(sort(table(x), decreasing = TRUE))[1]))
}


# files <- choose.files(default = "", caption = "Select .fna files", multi = TRUE)

args <- commandArgs(trailingOnly = TRUE)
usr_dir <- args[1]

# List all files in the directory with a specific extension and exclude subdirectories
files <- list.files(path = usr_dir, pattern = "\\.fna$", full.names = TRUE, recursive = FALSE)
print(files)
	
vec_out <- c()

for (i in seq(length(files))) {
  df <- read.table(files[i], header = TRUE, stringsAsFactors = FALSE)
  df2 <- subset(df, !df$Sequence %in% usr_seq)
  vec_out <- append(vec_out, fun_mode(df2$Reads, null.rm = TRUE))
  names(vec_out)[i] <- basename(files[i])
}

print(vec_out)