# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# + Shannon Multiple - Version 1.0 - 22th Dec 2020 - Jannik Daudert +
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# -----------------------
# 1 | Functions
# -----------------------
calc_shannon <- function(x) {
  File <- read.table(paste(x), header = TRUE, stringsAsFactors = FALSE)
  File$Percentage <- File$Reads/sum(File$Reads)
  File$PercLog <- File$Percentage*log(File$Percentage)
  return(list("Shannon" = -sum(File$PercLog), "Rows" = nrow(File)))
}

getFileName <- function(f) {
  x <- list()
  x[["dirname"]] <- unlist(strsplit(dirname(f), "/"))
  x[["basename"]] <- unlist(strsplit(basename(f), "_"))
  x[["mouse"]] <- x$dirname[grepl("SF-", x$dirname)]
  
  # Method
  if(any(c("UsedLibrary", "Merged") %in% x$dirname)) {
    x[["method"]]  <- paste(c("Lib", "Merged")[c("UsedLibrary", "Merged") %in% x$dirname], collapse = "+")
    if(length(x$method) > 1) {
      if(which(x$dirname %in% "UsedLibrary") > which(x$dirname %in% "Merged")) x$method <- paste(rev(tmp_method), collapse = "+")
    }
  } else {
    x[["method"]] <- "Raw"
  }
  
  # Sample
  if(any(grepl("Merged", x$basename))) {
    x[["replicate"]] <- 4
    x[["sample"]] <- paste(x$basename[1:(grep("Merged", x$basename)-1)], collapse = "-")
  } else {
    x[["replicate"]] <- as.integer(x$basename[x$basename %in% c(1,2,3)])
    x[["sample"]] <- paste(x$basename[1:(which(x$basename %in% x$replicate)-1)], collapse = "-")
  }
  
  # Output
  return(list("Mouse" = x$mouse, "Method" = x$method, "Sample" = x$sample, "Replicate" = x$replicate))
}

# -----------------------
# 2 | Main Routine
# -----------------------
# usr_dir <- choose.dir(default = file.path(getwd(), "*"), caption = "Select directory with mice, e.g. Mouse_CSR")
# if(!exists("usr_savedir")) usr_savedir <- choose.dir(default = getwd(), caption = "Choose directory where to save csv file")

args <- commandArgs(trailingOnly = TRUE)
usr_dir <- args[1]
usr_savedir <- args[2]


usr_mice <- dir(usr_dir, pattern = "^(SF-|preTX)")

for(usr_mouse in usr_mice) {
  if(!exists("list_data")) list_data <- list()
  
  usr_path <- file.path(usr_dir, usr_mouse)
  usr_files <- list.files(usr_path, recursive = TRUE)
  for(i in seq(length(usr_files))) {
    if(grepl("Dummy", usr_files[i])) next
    tmp_name <- getFileName(file.path(usr_path, usr_files[i]))
    tmp_shannon <- calc_shannon(file.path(usr_path, usr_files[i]))
    if(!tmp_name$Mouse %in% names(list_data)) list_data[[tmp_name$Mouse]] <- list()
    if(!tmp_name$Sample %in% names(list_data[[tmp_name$Mouse]])) list_data[[tmp_name$Mouse]][[tmp_name$Sample]] <- list("Shannon" = rep(NA, 4),
                                                                                                                        "Sequences" = rep(NA, 4))
    list_data[[tmp_name$Mouse]][[tmp_name$Sample]]$Shannon[tmp_name$Replicate] <- as.numeric(tmp_shannon$Shannon)
    list_data[[tmp_name$Mouse]][[tmp_name$Sample]]$Sequences[tmp_name$Replicate] <- as.numeric(tmp_shannon$Rows)
  }
}


df_shannon <- data.frame("Mouse" = character(), "Sample" = character(), "Rep1" = numeric(),
                                                   "Rep2" = numeric(), "Rep3" = numeric(), "Merged" = numeric(), stringsAsFactors = FALSE)
df_seq <- df_shannon
for(m in names(list_data)) {
  for(s in names(list_data[[m]])) {
    df_shannon <- rbind(df_shannon, data.frame(Mouse = m, Sample = s,
                                               Rep1 = as.numeric(list_data[[m]][[s]]$Shannon[1]),
                                               Rep2 = as.numeric(list_data[[m]][[s]]$Shannon[2]),
                                               Rep3 = as.numeric(list_data[[m]][[s]]$Shannon[3]),
                                               Merged = as.numeric(list_data[[m]][[s]]$Shannon[4])))
    df_seq <- rbind(df_seq, data.frame(Mouse = m, Sample = s,
                                       Rep1 = as.numeric(list_data[[m]][[s]]$Sequences[1]),
                                       Rep2 = as.numeric(list_data[[m]][[s]]$Sequences[2]),
                                       Rep3 = as.numeric(list_data[[m]][[s]]$Sequences[3]),
                                       Merged = as.numeric(list_data[[m]][[s]]$Sequences[4])))
  }
}

usr_title <- list("Shannon" = paste0("Shannon_", format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".csv"),
                  "Sequences" = paste0("Sequences_", format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".csv"))
# write.table(df_shannon, file = file.path(usr_savedir, usr_title$Shannon), row.names = FALSE, quote = FALSE, sep = ",")
# write.table(df_seq, file = file.path(usr_savedir, usr_title$Sequences), row.names = FALSE, quote = FALSE, sep = ",")

write.csv2(df_shannon, file = file.path(usr_savedir, usr_title$Shannon), row.names = FALSE, quote = FALSE)
write.csv2(df_seq, file = file.path(usr_savedir, usr_title$Sequences), row.names = FALSE, quote = FALSE)
