#########################################################################################
### Pool Size Estimation by Hypergeometric Function | v1.1 | J. Daudert | 05/29/2020  ###
#########################################################################################

# User Variables
sizeMin <- 1
sizeMax <- 200000

# -------------
# 1. Functions
# -----------------------------------------------------------------------------
calcHyper <- function(p, m, k, sMin, sMax, sBy) {
  df <- data.frame("Poolsize" = numeric(), "Value" = numeric())
  for (iterSize in seq(sMin, sMax, by = sBy)) {
    x <- 1:k
    n <- iterSize-m
    if(n < k-m || n < 0) next
    f <- dhyper(x,m,n,k)
    df <- rbind(df, data.frame(Poolsize = iterSize, Value = match(max(f), f)/k))
  }
  return(df[which.min(abs(df$Value-p)),]$Poolsize)
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

getFilePath <- function(v_files) {
  # Extracts the dirname of the first element of x.
  #
  # Args:
  #   v_files: Variable name (as character) of vector with file paths.
  #
  # Returns:
  #   Directory path as a string.
  if(missing(v_files) || !exists(v_files)) return(file.path(getwd(), "."))
  x <- get(v_files)
  if(length(x) == 0) return(file.path(getwd(), "."))
  path <- ifelse(nchar(dirname(x[1])) > 3, file.path(dirname(x[1]), "."), paste0(dirname(x[1]), "*.*"))
  return(path)
}

# -------------
# 2. Main Routine
# -----------------------------------------------------------------------------
# Files <- choose.files(default = getFilePath("Files"), caption = "Select files", multi = TRUE)

args <- commandArgs(trailingOnly = TRUE)
usr_dir <- args[1]

# List all files in the directory with a specific extension and exclude subdirectories
Files <- list.files(path = usr_dir, pattern = "^ITRGB_.*\\.fna$", full.names = TRUE, recursive = FALSE)





combs <- combn(seq(length(Files)), 2)
num_combs <- ncol(combs)

dfOut <- data.frame(matrix(NA, num_combs*2, 3))
colnames(dfOut) <- c("File", "CompTo", "Poolsize")

for (i in seq(num_combs)) {
  cat(paste("\rComparison", i, "of", num_combs))
  x <- read.table(paste(Files[combs[1,i]]), header=TRUE, stringsAsFactors = FALSE)
  y <- read.table(paste(Files[combs[2,i]]), header=TRUE, stringsAsFactors = FALSE)
  x_y <- nrow(merge(x, y, by = "Sequence", all = FALSE))
  perc <- c(x_y/nrow(x), x_y/nrow(y))
  m <- c(nrow(x), nrow(y))
  k <- rev(m)
  
  for (h in 1:2) {
    sizeTemp <- calcHyper(perc[h], m[h], k[h], sizeMin, sizeMax, 1000)
    sizeTemp <- calcHyper(perc[h], m[h], k[h], sizeTemp-1000, sizeTemp+1000, 100)
    sizeTemp <- calcHyper(perc[h], m[h], k[h], sizeTemp-100, sizeTemp+100, 1)
    
    if (h == 1) {
      dfOut[i,] <- c(basename(Files[combs[1,i]]), basename(Files[combs[2,i]]), sizeTemp)
    } else {
      dfOut[num_combs+i,] <- c(basename(Files[combs[2,i]]), basename(Files[combs[1,i]]), sizeTemp)
    }
  }
}

dfOut$Poolsize <- as.integer(dfOut$Poolsize)
print(paste("Mean Poolsize (+/- SD):", round(mean(dfOut$Poolsize),0), "+/-", round(sd(dfOut$Poolsize),0)))
fname <- paste0("Hypergeom_",format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".csv")
#write.table(dfOut, file = fname, row.names = FALSE, quote = FALSE, sep = ",")

cat("Mean =", round(comb.mean(dfOut$Poolsize, rep(1, nrow(dfOut))),0), "SD =", round(sd(dfOut$Poolsize),0))
