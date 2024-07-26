###
# User settings

usr_choice <- "83d" # preTX, 19d, 41d, 83d, 175d, BM

#############

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

if (length(args) != 1 || !dir.exists(args[1])) {
    stop("A valid and existing directory path must be provided.")
} else {
    usr_files <- get_relevant_files(args[1])
    usr_dir <- args[1]
}

# Determine species part based on the first argument
species_part <- ifelse(grepl("mouse", args[1], ignore.case = TRUE), "mouse",
                       ifelse(grepl("human", args[1], ignore.case = TRUE), "human", ""))


# Docker Edit END -------------------

df <- data.frame(matrix(NA, ncol=4, nrow=length(usr_files), dimnames = list(gsub("\\.|-", "", substr(basename(usr_files), 15, 19)), 
                                                            c("Rows", "Shannon", "Complexity", "Equitability"))),
                 stringsAsFactors = FALSE)

for(i in seq(length(usr_files))) {
  file <- read.table(usr_files[i], header = TRUE, stringsAsFactors = FALSE)
  df$Rows[i] <- calc_evenness(file)$Rows
  df$Shannon[i] <- calc_evenness(file)$Shannon
  df$Complexity[i] <- calc_evenness(file)$Complexity
  df$Equitability[i] <- calc_evenness(file)$Equitability
}
rm(i, file)

df[nrow(df)+1,] <- apply(df, 2, mean)
df[nrow(df)+1,] <- apply(df, 2, sd)
df[nrow(df)+1,] <- nrow(df)-2
rownames(df)[(nrow(df)-2):nrow(df)] <- c("Mean", "SD", "N")

fname <- paste0("Evenness_", species_part, "_preTX_", format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".csv")
outputDir <- "/JD/docker/export"
write.csv2(df, file=file.path(outputDir, fname))


###
# for user-defined files:

x <- c()
#usr_dir <- choose.dir(default = file.path(getwd(), "*"), caption = "Select directory with mice, e.g. Mouse_CSR")
# usr_dir <- choose.dir(default = dirname(usr_files)[1], caption = "Select directory with mice, e.g. Mouse_CSR")

usr_mice <- dir(usr_dir, pattern = "^(SF-|preTX)")
for(usr_mouse in usr_mice) {
  usr_path <- file.path(usr_dir, usr_mouse)
  usr_files <- setdiff(list.files(usr_path, recursive = FALSE, full.names = TRUE), list.dirs(usr_path, recursive = FALSE))
  for(i in seq(length(usr_files))) {
    if(!grepl("Spacer", usr_files[i]) & grepl(usr_choice, usr_files[i])) {
      x <- append(x, usr_files[i])
    }
  }
}

extract_name <- function(x) { #x = path as string
  return(regmatches(x,regexpr("(preTx_)?SF-(3|T|3T)#?[1-5]?",x)))
}

df <- data.frame(matrix(NA, ncol=4, nrow=length(x), dimnames = list(paste0(LETTERS[1:length(x)], "_", extract_name(x)), 
                                                                            c("Rows", "Shannon", "Complexity", "Equitability"))),
                 stringsAsFactors = FALSE)

for(i in seq(length(x))) {
  file <- read.table(x[i], header = TRUE, stringsAsFactors = FALSE)
  df$Rows[i] <- calc_evenness(file)$Rows
  df$Shannon[i] <- calc_evenness(file)$Shannon
  df$Complexity[i] <- calc_evenness(file)$Complexity
  df$Equitability[i] <- calc_evenness(file)$Equitability
}

df[nrow(df)+1,] <- apply(df, 2, mean)
df[nrow(df)+1,] <- apply(df, 2, sd)
df[nrow(df)+1,] <- nrow(df)-2
rownames(df)[(nrow(df)-2):nrow(df)] <- c("Mean", "SD", "N")

fname <- paste0("Evenness_", species_part,"_", usr_choice, "_", format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".csv")
write.csv2(df, file=file.path(outputDir, fname))





####
# Just a check, to see whether calculations are correct (comparison to Bystrykh)
####

# df <- data.frame(matrix(c(LETTERS[1:10], rep(1,10)), nrow = 10, ncol = 2, dimnames = list(seq(10), c("Sequence", "Reads"))), stringsAsFactors = FALSE)
# df <- data.frame(matrix(c(LETTERS[1:10], seq(10)), nrow = 10, ncol = 2, dimnames = list(seq(10), c("Sequence", "Reads"))), stringsAsFactors = FALSE)
# df <- data.frame(matrix(c(LETTERS[1:10], create_fibonacci(0,55)), nrow = 10, ncol = 2, dimnames = list(seq(10), c("Sequence", "Reads"))), stringsAsFactors = FALSE)
# df <- data.frame(matrix(c(LETTERS[1:10], create_exp(2,1024)), nrow = 10, ncol = 2, dimnames = list(seq(10), c("Sequence", "Reads"))), stringsAsFactors = FALSE)
# df$Reads <- as.numeric(df$Reads)
# calc_evenness(df)
# 
# 
# ##
# 
# create_fibonacci <- function(u_start, u_stop) {
#   x <- u_start
#   y <- x + 1
#   fib <- c(y)
#   while (x < u_stop & y < u_stop){
#     x <- x + y
#     y <- x + y
#     fib = c(fib, x, y)
#   }
#   return(fib[1:(length(fib)-1)])
# }
# 
# create_exp <- function(u_start, u_stop) {
#   x <- u_start
#   fib <- c(x)
#   while (x < u_stop){
#     x <- x*2
#     fib = c(fib, x)
#   }
#   return(fib)
# }
