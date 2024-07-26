usr_thresh <- 1000

###

library(ggplot2)
library(dplyr)
library(reshape2)

# getFilePath <- function(x) {
  # # Extracts the dirname of the first element of x.
  # #
  # # Args:
  # #   x: Vector with file paths.
  # #
  # # Returns:
  # #   Directory path as a string.
  # if (missing(x) || length(x) == 0) return(paste0(getwd(), "/*"))
  # path <- dirname(x[1])
  # if (nchar(path) > 3) path <- paste0(path, "/")
  # return(paste0(path, "*"))
# }

file_merge <- function(x, y) { #x and y as data.frames with columns "Sequence", "Reads, "Distance"
  z <- merge(x, y, by = "Sequence", all = TRUE)
  z$Reads <- apply(z[, grepl("Reads", colnames(z))], 1, function(x) sum(x, na.rm = TRUE))
  z$Distance <- apply(z[, grepl("Distance", colnames(z))], 1, function(x) 
    if(length(unique(x)) == 1) { x[1] } else {
      if(any(is.na(x))) { x[!is.na(x)] } else { warning("Some distances of identical sequences differed and were set to NA"); return(NA) }
    })
  z <- z[, c("Sequence", "Reads", "Distance")]
  return(z)
}

xlab_indiv <- function(start, end, interval) { # vector from start to end with markins only at interval
  x <- seq(start, end)
  for(y in seq(length(x))) x[y] <- ifelse(y %% interval == 0, y, "")
  return(x)
}

####

# 1. User file selection
# usr_files_raw <- choose.files(default = getFilePath(if(exists("usr_files_raw")) usr_files_raw), caption = "Select raw, merged files", multi = TRUE)
# usr_files_csr <- choose.files(default = getFilePath(if(exists("usr_files_csr")) usr_files_csr), caption = "Select CSR-treated, merged files", multi = TRUE)


# Docker edit ---
	get_relevant_files <- function(directory_path) {
		# List all .fna files in the directory
		all_files <- list.files(path = directory_path, pattern = "\\.fna$", full.names = TRUE, recursive = FALSE)

		# Extract just the filenames from the full paths
		filenames <- basename(all_files)

		# Filter files where filenames start with 'Merged__'
		filtered_files <- all_files[grepl("^Merged__", filenames)]

		return(filtered_files)
}
	args <- commandArgs(trailingOnly = TRUE)
	usr_files_raw <- get_relevant_files(args[1])
	usr_files_csr <- get_relevant_files(args[2])
	
	
# ---------------






# 2. Read in sequences, sampling the number of sequences imported
df_raw <- data.frame("Sequence" = character(), "Reads" = integer(), "Distance" = integer(), stringsAsFactors = FALSE)
for (x in seq(length(usr_files_raw))) {
  df_tmp <- read.table(usr_files_raw[x], header=TRUE, stringsAsFactors = FALSE)
  if (nrow(df_tmp) > usr_thresh) df_tmp <- df_tmp[sample(nrow(df_tmp), usr_thresh),]
  df_raw <- file_merge(df_raw, df_tmp)
}

df_csr <- data.frame("Sequence" = character(), "Reads" = integer(), "Distance" = integer(), stringsAsFactors = FALSE)
for (x in seq(length(usr_files_csr))) {
  df_tmp <- read.table(usr_files_csr[x], header=TRUE, stringsAsFactors = FALSE)
  if (nrow(df_tmp) > usr_thresh) df_tmp <- df_tmp[sample(nrow(df_tmp), usr_thresh),]
  df_csr <- file_merge(df_csr, df_tmp)
}

rm(x, df_tmp)

# 3. Calculated distance tables
if (nrow(df_raw) > usr_thresh) df_raw <- df_raw[sample(nrow(df_raw), usr_thresh),]
tmp_raw <- adist(df_raw$Sequence)
tmp_raw_tbl <- table(tmp_raw)/2
tmp_raw_df <- as.data.frame(tmp_raw_tbl[2:length(tmp_raw_tbl)])
colnames(tmp_raw_df) <- c("x", "raw")
tmp_raw_df$raw <- tmp_raw_df$raw/sum(tmp_raw_df$raw)
tmp_raw_df$x <- as.numeric(as.character(tmp_raw_df$x))

if (nrow(df_csr) > usr_thresh) df_csr <- df_csr[sample(nrow(df_csr), usr_thresh),]
tmp_csr <- adist(df_csr$Sequence)
tmp_csr_tbl <- table(tmp_csr)/2
tmp_csr_df <- as.data.frame(tmp_csr_tbl[2:length(tmp_csr_tbl)])
colnames(tmp_csr_df) <- c("x", "csr")
tmp_csr_df$csr <- tmp_csr_df$csr/sum(tmp_csr_df$csr)
tmp_csr_df$x <- as.numeric(as.character(tmp_csr_df$x))

# 4. Create final data.frame
df_data <- full_join(tmp_raw_df, tmp_csr_df, by ="x")
df_data$dbinom <- dbinom(df_data$x, 16, 3/4)
df_data[is.na(df_data)] <- 0

rm(tmp_raw, tmp_raw_tbl, tmp_raw_df, tmp_csr, tmp_csr_tbl, tmp_csr_df)

# 5. Smooth graph
for(i in 1:3) {
  plot.new()
  if(i == 1) {
    df_data_smooth <- data.frame(xspline(select(df_data, x, colnames(df_data)[i+1]), shape=-0.75, lwd=2, draw=F))
  } else {
    df_data_smooth <- full_join(df_data_smooth,
                                data.frame(xspline(select(df_data, x, colnames(df_data)[i+1]), shape=-0.75, lwd=2, draw=F)),
                                by = "x")
  }
  colnames(df_data_smooth)[i+1] <- colnames(df_data)[i+1]
}

df_data_smooth <- melt(df_data_smooth , id.var = "x")
df_data_smooth <- df_data_smooth[order(df_data_smooth$variable, df_data_smooth$x),]
df_data_smooth <- df_data_smooth %>% filter(!is.na(df_data_smooth$value))
df_data_smooth$value[df_data_smooth$value < 0] <- 0
dbinom_smooth <- df_data_smooth %>% filter(df_data_smooth$variable == "dbinom")
#df_data_smooth <- df_data_smooth %>% filter(!df_data_smooth$variable == "dbinom")
df_data_smooth$variable <- factor(df_data_smooth$variable, levels = c("csr", "raw"))
#df_data_smooth <- df_data_smooth %>% filter(df_data_smooth$variable == "raw")
#df_data_smooth <- df_data_smooth %>% filter(df_data_smooth$variable == "csr")

# 6. Plot graph
g <- ggplot(data = dbinom_smooth, aes(x = x, y = value)) +
  geom_area(aes(fill = variable), alpha = 0.75, color = NA, linetype = 0) +
  scale_fill_manual(values=c("#B09C85")) +
  geom_path(data = df_data_smooth, aes(x = x, y = value, color = variable), size = 1.5) +
  #scale_color_manual(values=c("#3C5488", "#DC0000")) +
  scale_color_manual(values=c("#00A087", "#8491B4")) +
  #scale_color_manual(values=c("#3C5488")) + #blue
  #scale_color_manual(values=c("#DC0000")) + #red
  theme(panel.background = element_rect(fill = "white"),
        legend.position = "none",
        axis.line = element_line(size = 1, linetype ="solid", color = "black"),
        axis.text = element_text(size = 10),
        axis.title = element_text(size = 10),
        plot.margin = margin(0.1,0.25,0,0.1, unit = "cm")) +
  labs(x = "Nucleotide difference (k)", y = "P(X = k)") +
  scale_x_continuous(limits = c(1, 24), breaks = seq(24), labels = xlab_indiv(1,24,4), expand=c(0,0)) +
  scale_y_continuous(limits = c(0, 0.25), breaks = seq(0,0.25,0.05), labels = c("0","","0.1","","0.2",""), expand=c(0,0))
# print(g)
  
# fname <- paste0("Dist-Distribution_", format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".tiff")
# ggsave(file=fname, height=5, width=6, units="cm", compression="lzw", dpi = 300)

outputFileName <- paste0("Dist-Distribution_", format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".tiff")
outputDir <- "/JD/docker/export"
outputFilePath <- file.path(outputDir, outputFileName)

# Check if the output directory exists; if not, create it
if (!dir.exists(outputDir)) {
dir.create(outputDir, recursive = TRUE)
}

tiff(outputFilePath, compression = "lzw", type="cairo", width = 708, height = 590, units = "px", res = 300)
	print(g)
dev.off()
