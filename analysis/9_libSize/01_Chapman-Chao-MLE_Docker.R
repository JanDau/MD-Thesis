###############
### Functions #
###############
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

estim_chao <- function(v) {
  # Estimates the pool size with the Chao Estimator. Requires dplyr.
  #
  # Args:
  #   v: Vector with file paths of two [or three] replicates.
  #
  # Returns:
  #   A vector with mean and SD.
  library(dplyr)
  if (length(v) < 2) stop("You need at least two replicates for the pool size estimation!")
  
  # Combinations
  combs <- combn(seq(length(v)), 2)
  df <- data.frame(matrix(NA, nrow = 10, ncol = ncol(combs), 
                          dimnames = list(c("x", "y", "f10", "f01", "f11", "f1", "f2", "n", "size", "sd"), seq(ncol(combs)))))
  df[1:2, seq(ncol(combs))] <- combs
  
  for (i in seq(ncol(df))) {
    x <- read.table(v[df[1, i]], header = TRUE, stringsAsFactors = FALSE)
    y <- read.table(v[df[2, i]], header = TRUE, stringsAsFactors = FALSE)
    shared <- intersect(x$Sequence, y$Sequence)
    df["f10", i] <- length(setdiff(x$Sequence, shared))
    df["f01", i] <- length(setdiff(y$Sequence, shared))
    df["f11", i] <- length(shared)
    df["f1", i] <- df["f10", i] + df["f01", i]
    df["f2", i] <- df["f11", i]
    df["n", i] <- df["f1", i] + df["f2", i]
    df["size", i] <- round(df["n", i] + ((df["f1", i]^2)/(4*df["f2", i])),0)
    df["sd", i] <- round(sqrt(((df["f1", i]^2)/(4*df["f2", i]))*((df["f1", i]/(2*df["f2", i]))+1)^2),0)
  }
  return(c(round(comb.mean(as.numeric(df["size", ]), rep(1, ncol(df))), 0), 
           round(comb.sd(as.numeric(df["size", ]), rep(1, ncol(df)), as.numeric(df["sd", ])), 0)))
}

estim_linc_chap <- function(v) {
  # Estimates the pool size with the Lincoln or Chapman Estimator. Requires dplyr.
  #
  # Args:
  #   v: Vector with file paths of two [or three] replicates.
  #
  # Returns:
  #   A vector with mean and SD.
  library(dplyr)
  if (length(v) < 2) stop("You need at least two replicates for the pool size estimation!")
  
  # Combinations
  combs <- combn(seq(length(v)), 2)
  df <- data.frame(matrix(NA, nrow = 11, ncol = ncol(combs), 
                          dimnames = list(c("x", "y", "f10", "f01", "f11", "n1", "n2", "m2", "lincoln", "chapman", "chapman_sd"), seq(ncol(combs)))))
  df[1:2, seq(ncol(combs))] <- combs
  
  for (i in seq(ncol(df))) {
    x <- read.table(v[df[1, i]], header = TRUE, stringsAsFactors = FALSE)
    y <- read.table(v[df[2, i]], header = TRUE, stringsAsFactors = FALSE)
    shared <- intersect(x$Sequence, y$Sequence)
    df["f10", i] <- length(setdiff(x$Sequence, shared))
    df["f01", i] <- length(setdiff(y$Sequence, shared))
    df["f11", i] <- length(shared)
    df["n1", i] <- df["f10", i] + df["f11", i]
    df["n2", i] <- df["f01", i] + df["f11", i]
    df["m2", i] <- df["f11", i]
    df["lincoln", i] <- round(df["n1", i]*df["n2", i]/df["m2", i],0)
    df["chapman", i] <- round(((df["n1", i]+1)*(df["n2", i]+1))/(df["m2", i]+1)-1,0)
    df["chapman_sd", i] <- round(sqrt(((df["n1", i]+1)*(df["n2", i]+1)*(df["n1", i]-df["m2", i])*(df["n2", i]-df["m2", i]))/((df["m2", i]+1)^2*(df["m2", i]+2))),0)
  }
  return(list("Lincoln" = c(round(comb.mean(as.numeric(df["lincoln", ]), rep(1, ncol(df))), 0),
                            round(sd(as.numeric(df["lincoln", ])))),
              "Chapman" = c(round(comb.mean(as.numeric(df["chapman", ]), rep(1, ncol(df))), 0),
                            round(comb.sd(as.numeric(df["chapman", ]), rep(1, ncol(df)), as.numeric(df["chapman_sd", ])), 0))))
}

estim_mle <- function(v) {
  # Estimates the pool size with the MLE Estimator. Requires dplyr.
  #
  # Args:
  #   v: Vector with file paths of two [or three] replicates.
  #
  # Returns:
  #   A vector with mean and SD.
  library(dplyr)
  if (length(v) < 2) stop("You need at least two replicates for the pool size estimation!")
  
  # Combinations
  combs <- combn(seq(length(v)), 2)
  df <- data.frame(matrix(NA, nrow = 9, ncol = ncol(combs), 
                          dimnames = list(c("x", "y", "f10", "f01", "f11", "f1", "f2", "n", "size"), seq(ncol(combs)))))
  df[1:2, seq(ncol(combs))] <- combs
  
  for (i in seq(ncol(df))) {
    x <- read.table(v[df[1, i]], header = TRUE, stringsAsFactors = FALSE)
    y <- read.table(v[df[2, i]], header = TRUE, stringsAsFactors = FALSE)
    shared <- intersect(x$Sequence, y$Sequence)
    df["f10", i] <- length(setdiff(x$Sequence, shared))
    df["f01", i] <- length(setdiff(y$Sequence, shared))
    df["f11", i] <- length(shared)
    df["f1", i] <- df["f10", i] + df["f01", i]
    df["f2", i] <- df["f11", i]
    df["n", i] <- df["f1", i] + df["f2", i]
    df["size", i] <- round(df["n", i]/(((4*df["f2", i])/(df["f1", i]+2*df["f2", i])) - ((4*df["f2", i]^2)/((df["f1", i]+2*df["f2", i])^2))), 0)
  }
  return(c(round(comb.mean(as.numeric(df["size", ]), rep(1, ncol(df))), 0),
           round(sd(as.numeric(df["size", ])))))
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

###############
### Code     #
###############

df <- data.frame(matrix(NA, 0, 8))
colnames(df) <- c("Linc", "Linc_SD", "Chap", "Chap_SD", "Chao", "Chao_SD", "MLE", "MLE_SD")

#

# files <- choose.files(default = getFilePath("files"), caption = "Select replicates", multi = TRUE)

# Docker edit ---
args <- commandArgs(trailingOnly = TRUE)
usr_dir <- args[1]

# List all files in the directory with a specific extension and exclude subdirectories
files <- list.files(path = usr_dir, pattern = "^(ITRGB_|preTX_).*\\.fna$", full.names = TRUE, recursive = FALSE)



# cat("Lincoln =", estim_linc_chap(files)$Lincoln,
#     "\nChapman (+ SD) =", estim_linc_chap(files)$Chapman,# "SD =", estim_linc_chap(files)$Chapman_SD,
#     "\nChao (+ SD)=", estim_chao(files),
#     "\nMLE =", estim_mle(files))

df[nrow(df)+1,] <- c(estim_linc_chap(files)$Lincoln, estim_linc_chap(files)$Chapman, estim_chao(files), estim_mle(files))
rownames(df)[nrow(df)] <- paste0(paste0(nrow(df)),"_",strsplit(dirname(files[1]), "/")[[1]][length(strsplit(dirname(files[1]), "/")[[1]])])

outputFileName <- paste0(basename(usr_dir),"_Chap-Chao-MLE_",format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".csv")
outputDir <- file.path("/JD/docker/export", regmatches(usr_dir,regexpr("(?i)(Cer|mCh|Ven)",usr_dir)))
outputFilePath <- file.path(outputDir, outputFileName)

# Check if the output directory exists; if not, create it
if (!dir.exists(outputDir)) {
dir.create(outputDir, recursive = TRUE)
}

write.csv2(df, file=outputFilePath)
