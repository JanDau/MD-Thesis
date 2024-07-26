usr_data <- "Sequences"
usr_width <- if(usr_data == "Shannon") 354 else 413
usr_height <- 330
usr_delim <- "de" # "de" vs. "en"

# -----------------------
# 1 | Loading Library
# -----------------------
packages <- c("ggplot2")
if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())), dependencies = TRUE)
}
lapply(packages, library, character.only = TRUE)
rm(packages)

# -----------------------
# 2 | Main Code
# -----------------------
# usr_file <- choose.files(default = file.path(getwd(), "*"), caption = "Select csv file", multi = FALSE)

# Docker edit START ---------------
# Function to identify and return the most recent "Shannon" CSV file
get_most_recent_file <- function(directory_path, file_prefix) {
  # List all CSV files in the directory that start with "Shannon"
  pattern <- sprintf("^%s_\\d{8}_\\d{2}-\\d{2}-\\d{2}\\.csv$", file_prefix)
  all_files <- list.files(directory_path, pattern = pattern, full.names = TRUE)

  # Early exit if no files are found
  if (length(all_files) == 0) {
    warning(sprintf("No '%s' CSV files found.", file_prefix))
    return(NULL)
  }

  # Extract timestamps from filenames using the prefix in the regular expression
  timestamps <- sapply(all_files, function(x) {
    sub(sprintf("%s_(\\d{8}_\\d{2}-\\d{2}-\\d{2})\\.csv", file_prefix), "\\1", basename(x))
  })
  
  # Convert timestamps to POSIXct objects
  date_times <- as.POSIXct(timestamps, format = "%Y%m%d_%H-%M-%S", tz = "UTC")
  
  # Identify the index of the most recent file
  most_recent_index <- which.max(date_times)
  
  # Return the most recent file
  return(all_files[most_recent_index])
}

args <- commandArgs(trailingOnly = TRUE)
directory_path <- args[1]
file_prefix <- args[2]

# Get the most recent Shannon file
usr_file <- get_most_recent_file(directory_path, file_prefix)

print(usr_file)

# Docker edit END ---------------

usr_type <- head(unlist(strsplit(basename(usr_file), "_")),1)
df <- if(usr_delim == "de") read.csv2(usr_file, header = TRUE) else read.csv(usr_file, header = TRUE)
vals_samples <- c()
vals_preTX <- c()

for(i in seq(nrow(df))) {
  if(sum(!is.na(df[i, 3:5])) > 1) {
    for(k in seq(sum(!is.na(df[i, 3:5])))) {
      val_tmp <- df$Merged[i] - df[i, 2+k]
      if(grepl("preTX", df$Sample[i], ignore.case = FALSE)) {
        vals_preTX <- append(vals_preTX, val_tmp)
      } else {
        vals_samples <- append(vals_samples, val_tmp)
      }
    }
  }
}

d <- data.frame("Type" = "High", "Value" = mean(vals_preTX), "SD" = sd(vals_preTX))
d <- rbind(d, data.frame("Type" = "Low", "Value" = mean(vals_samples), "SD" = sd(vals_samples)))

d$SDfix <- ifelse(d$Value-d$SD < 1, d$Value-1, d$SD)

g <- ggplot(data=d) + 
  xlab("Diversity of Sample") +
  theme(plot.title = element_blank(), #element_text(hjust = 0.5, size=rel(1.25), face="bold"),
        #plot.background = element_blank(),
        #panel.grid.minor = element_blank(),
        aspect.ratio=1/0.8, #h/w
        panel.grid.major.x = element_blank(),
        panel.grid.minor.y = element_blank(),
        panel.border = element_rect(fill = NA),
        panel.background = element_blank(), #element_rect(fill =""),
        panel.grid.major.y = element_line(color = "grey", linetype = 1, size = rel(0.1)),
        axis.title.x = element_blank(), #element_text(size = rel(1.25), face = "bold"),
        axis.title.y = element_blank(), #element_text(size = rel(1.25), face = "bold"),
        axis.text.x = element_text(size = 6.5, face = "bold"),
        axis.text.y = element_text(size = 6.5, face = "bold"),
        #axis.ticks.x=element_blank(),
        axis.line = element_line())

if(usr_type == "Shannon") {
  g <- g +
    geom_pointrange(aes(x=Type, y=Value, ymin=Value-SD, ymax=Value+SD), size = rel(0.5), fatten = rel(1.5)) +
    scale_y_continuous(limits = c(-0.25, 1), breaks = seq(-0.25, 1, 0.25), labels = sprintf("%+0.2f", seq(-0.25, 1, 0.25))) +
    ylab("Change (Shannon-Index)") +
    labs(title = "Effect on the\nShannon-Index")
} else {
  g <-  g +
    geom_pointrange(aes(x=Type, y=Value, ymin=Value-SDfix, ymax=Value+SD), size = rel(0.5), fatten = rel(1.5)) +
    ylab("Change (Sequences)") +
    coord_trans(y = "log10") +
    scale_y_continuous(breaks = c(1 %o% 10^(0:5)), expand = c(0,0), limits = c(1, 10^5), labels = c("+1", "+10", "+100", "+1,000", "+10,000", "+100,000")) + #labels = c(1, 10, 100, sprintf("%+0.2e", c(1 %o% 10^(3:5))))
    annotation_logticks(sides = "l", scaled = FALSE, size = 0.3) +
    labs(title = "Effect on the\nNumber of Sequences")
}

# -----------------------
# 3 | Print & Export
# -----------------------
# Print in RStudio
# print(g)

# fname <- paste0("Effect_", usr_type, "_", format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".tiff")

# Export: Name of the figure will be the parent folder name, saved as tiff
#ggsave(file=fname, path=getwd(), width = ifelse(usr_type == "Shannon", 3, 4), height = 2.8, units="cm", compression="lzw", dpi = 300)
# ggsave(file=fname, path=getwd(), width = ifelse(usr_type == "Shannon", 3, 3.5), height = 2.8, units="cm", compression="lzw", dpi = 300)



outputFileName <- paste0("Effect_", usr_type, "_", format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".tiff")
outputDir <- "/JD/docker/export"
outputFilePath <- file.path(outputDir, outputFileName)

# Check if the output directory exists; if not, create it
if (!dir.exists(outputDir)) {
dir.create(outputDir, recursive = TRUE)
}

tiff(outputFilePath, compression = "lzw", type="cairo", width = usr_width, height = usr_height, units = "px", res = 300)
	print(g)
dev.off()

# 

t.test(vals_preTX)
t.test(vals_samples)
