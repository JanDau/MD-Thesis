library("ggplot2")
#library("ggsci")

if(!exists("usr")) usr <- list()

# usr[["files"]] <- choose.files(default = "", caption = "Select all csv files", multi = TRUE)

# Docker edit ---
	args <- commandArgs(trailingOnly = TRUE)
	usr_dir <- args[1]

	# List all files in the directory with their full paths
	all_files <- list.files(path = usr_dir, full.names = TRUE)

	# Extract just the filenames from the full paths
	filenames <- basename(all_files)
	
	# Filter files and save either with full path or filename only
	filtered_files <- all_files[grepl("^ITRGB_", filenames)]
	filtered_filenames <- basename(filtered_files)

	# Initialize an empty vector to store the files that meet the criteria
	fileLoad <- c()

	# Loop through each filename
	for (filename in filtered_filenames) {
		fileLoad <- c(fileLoad, filtered_files[filename == filtered_filenames])
	}
	
	usr[["files"]] <- fileLoad
	print(usr$files)
# ---------------


df_sens <- setNames(data.frame(matrix(NA, ncol = length(usr$files), nrow = 8), stringsAsFactors = F), basename(usr$files))
df_spec <- setNames(data.frame(matrix(NA, ncol = length(usr$files), nrow = 8), stringsAsFactors = F), basename(usr$files))
df_prec <- setNames(data.frame(matrix(NA, ncol = length(usr$files), nrow = 8), stringsAsFactors = F), basename(usr$files))

for (i in seq(length(usr$files))) {
  file <- read.csv2(usr$files[i], row.names = 1)
  if(i == 1) {
    rownames(df_sens) <- rownames(file)
    rownames(df_spec) <- rownames(file)
    rownames(df_prec) <- rownames(file)
  }
  if(all(rownames(file) == rownames(df_sens))) df_sens[, i] <- file$sensitivity
  if(all(rownames(file) == rownames(df_spec))) df_spec[, i] <- file$specificity
  if(all(rownames(file) == rownames(df_prec))) df_prec[, i] <- file$precision
}

usr_ranks <- c(0, 0.582428628, 0.459359434, 0.721047292, 0.629061469, 0.630832998, 0.734258196, 0.736296863)
usr_cols <- factor(terrain.colors(9)[c(8,6,7,3,5,4,2,1)], levels = terrain.colors(9)[c(8,6,7,3,5,4,2,1)])
l_data <- list(Sensitivity = data.frame("Method" = factor(rownames(df_sens), levels = rev(rownames(df_sens))),
                                        "Value" = apply(df_sens, 1, mean), "Err" = apply(df_sens, 1, sd),
                                        "Rank" = usr_ranks),
               Specificity = data.frame("Method" = factor(rownames(df_spec), levels = rev(rownames(df_spec))),
                                        "Value" = apply(df_spec, 1, mean), "Err" = apply(df_spec, 1, sd),
                                        "Rank" = usr_ranks),
               Precision = data.frame("Method" = factor(rownames(df_prec), levels = rev(rownames(df_prec))),
                                      "Value" = apply(df_prec, 1, mean), "Err" = apply(df_prec, 1, sd),
                                      "Rank" = usr_ranks))
l_data$Sensitivity$Lbl <- NA
l_data$Specificity$Lbl <- NA
l_data$Precision$Lbl <- NA

for (i in 1:8) {
  l_data$Sensitivity$Lbl[i] <- ifelse(l_data$Sensitivity$Value[i] < 0.1, 0.5, 0.5*l_data$Sensitivity$Value[i])
  l_data$Specificity$Lbl[i] <- ifelse(l_data$Specificity$Value[i] < 0.1, 0.5, 0.5*l_data$Specificity$Value[i])
  l_data$Precision$Lbl[i] <- ifelse(l_data$Precision$Value[i] < 0.1, 0.5, 0.5*l_data$Precision$Value[i])
}


for (i in 1:3) {
  l_data[i][[names(l_data[i])]]$Method <- factor(l_data[i][[names(l_data[i])]]$Method, levels = rev(levels(l_data[i][[names(l_data[i])]]$Method)))
  g <- ggplot(data = l_data[[i]], aes(x = Method, y = Value)) +
    geom_errorbar(aes(ymin=Value-Err, ymax=Value+Err), width=0.3, size=0.75, alpha=1, linetype="solid", color="black") + # #7F7F7F
    #geom_col(fill = factor(usr_cols), linetype = 0) +
    geom_col(aes(fill = Value), linetype = "solid", color="black", width=0.7) +
    scale_fill_gradient2(low = "#C00000", mid = "#FFD966", high = "#70AD47", midpoint = 0.5, limits = c(0,1)) +
    #scale_fill_gradient(low = "red", high = muted("green"), limits = c(0,1)) +
    #geom_col(aes(y = 1), color = "black", fill = NA, linetype = 1, size = 1) +
    #geom_text(aes(label = paste0(round(Value*100,0), "%"), y = Lbl), angle=90, size=4, color="black") +
    geom_text(aes(label = round(Value,2), y = Lbl), angle=90, size=3.25, vjust=0.5, hjust=0.5, color="black") +
    #coord_flip() +
    #scale_y_continuous(limits=c(0,1), breaks=seq(0,1,0.25), labels=paste0(seq(0,100,25),"%"), expand=c(0,0)) +
    #scale_y_continuous(limits=c(0,1), breaks=seq(0,1,0.25), expand=c(0,0)) +
    scale_y_continuous(limits=c(0,1), breaks=seq(0,1,0.25), labels=c("0","","0.5","","1"), expand=c(0,0)) +
    #scale_y_discrete(expand=c(1,1)) +
    theme(legend.position = "none",
          panel.grid.minor.x = element_blank(),
          panel.grid.minor.y = element_blank(),
          panel.grid.major.x = element_blank(),
          panel.grid.major.y = element_blank(),
          panel.background = element_blank(),
          axis.ticks.x = element_blank(),
          axis.title = element_blank(),
          axis.text.x = element_blank(),
          axis.line.y = element_line(color = "black", size = 1, linetype = "solid"),
          axis.text.y = element_text(size=9, color = "black"),
          #plot.margin = margin(0, 0.8, 0.5, 0.5, "cm"))
          plot.margin = margin(0.25, 0, 0.25, 0, "cm"))
          #axis.text.x = element_blank())
  # print(g)
  # fname <- paste0(names(l_data)[i], "_",format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".tiff")
  # ggsave(file=fname, height=3, width=6, units="cm", compression="lzw", dpi = 300)
  
  
	outputFileName <- paste0(names(l_data)[i], "_",format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".tiff")
	outputDir <- "/JD/docker/export"
	outputFilePath <- file.path(outputDir, outputFileName)

	# Check if the output directory exists; if not, create it
	if (!dir.exists(outputDir)) {
	dir.create(outputDir, recursive = TRUE)
	}

	tiff(outputFilePath, compression = "lzw", type="cairo", width = 708, height = 354, units = "px", res = 300)
		print(g)
	dev.off()

}
