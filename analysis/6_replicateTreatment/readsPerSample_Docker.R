#####
# 0. User settings
#####
usr_dev <- 2      # define the maximum deviation allowed
usr_run <- "1505"   # which run should be analyzed? "1505", "1507", "1509", "1602"
usr_comp <- "all" # which samples should be analyzed? "19d", "41d", "83d", "175d", "BM" or "all"

#####
# 1. Get/Ask for relevant file paths
#####
# usr_data_path <- choose.dir(caption = "Choose directory called Preprocessed")
# usr_file_path <- choose.files(caption = "Choose sample allocation csv")

# Docker edit ---
args <- commandArgs(trailingOnly = TRUE)
usr_data_path <- args[1]
usr_file_path <- args[2]

# ---------------



#####
# 2. Determine the mean read count for all runs
#####
l_run <- list("1505" = list("Mean"=0, "SD"=0, "N"=0), 
              "1507" = list("Mean"=0, "SD"=0, "N"=0), 
              "1509" = list("Mean"=0, "SD"=0, "N"=0), 
              "1602" = list("Mean"=0, "SD"=0, "N"=0))

for(run_id in c("1505", "1507", "1509", "1602")) {
  vec_tmp <- c()
  for(file in list.files(file.path(usr_data_path, run_id, "Reads"), pattern="(.fna)")) {
    f <- read.table(file.path(usr_data_path, run_id, "Reads", file), header = TRUE, stringsAsFactors = FALSE)
    f <- f[f$Distance <= usr_dev,]
    vec_tmp <- append(vec_tmp, sum(f$Reads))
  }
  l_run[[run_id]]$Mean <- round(mean(vec_tmp))
  l_run[[run_id]]$SD <- round(sd(vec_tmp))
  l_run[[run_id]]$N <- length(vec_tmp)
  cat("Run", run_id, ": Mean =",l_run[[run_id]]$Mean, ", SD =", l_run[[run_id]]$SD, ", N =", l_run[[run_id]]$N, "\n")
}

rm(run_id, vec_tmp, file, f)

#####
# 3. Determine the mean read count in the run
#####
usr_file <- read.csv(usr_file_path, stringsAsFactors = FALSE)
if(usr_comp == "all") usr_comp <- "19d|41d|83d|175d|BM"

vec_preTX <- c()
vec_var <- c()
vec_all <- c()

for (i in seq(nrow(usr_file))) {
  if(usr_file$Run[i] != usr_run) next
  fpath <- file.path(usr_data_path, usr_file$Run[i], "Reads", sprintf("ITRGB_%03d.fna", usr_file$Primer[i]))
  if(!file.exists(fpath)) next
  f <- read.table(fpath, header=TRUE, stringsAsFactors = FALSE)
  f <- f[f$Distance <= usr_dev,]
  
  if(grepl('preTX', usr_file$Name[i], ignore.case = TRUE)) {
    vec_preTX <- append(vec_preTX, sum(f$Reads))
    names(vec_preTX)[length(vec_preTX)] <- usr_file$ID[i]
  } else if(grepl(usr_comp, usr_file$Name[i], ignore.case = TRUE)) {
    vec_var <- append(vec_var, sum(f$Reads))
    names(vec_var)[length(vec_var)] <- usr_file$ID[i]
  }
  vec_all <- append(vec_all, sum(f$Reads))
  names(vec_all)[length(vec_all)] <- usr_file$ID[i]
  
}


#####
# 4. Graphical output
#####

library(ggplot2)

lab_indiv <- function(ymin, ymax, tick_interval, label_interval, type) { # vector from start to end with markins only at interval
  # type = "dec" for comma (like 100,000), "sci" for 1e+05, "int" for 100000 (also taken if nothing supplied)
  if(missing(type)) type <- "int"
  x <- seq(ymin, ymax, tick_interval)
  for(y in seq(length(x))) x[y] <- ifelse(as.numeric(x[y]) %% label_interval == 0, x[y], NA)
  if(type == "int") {
    x <- sprintf("%.0f", x)
  } else if(type == "dec") {
    x <- format(x, scientific = FALSE, big.mark=",")
  } else if(type == "sci") {
    x <- sprintf("%.4g", x)
  }
  for(y in seq(length(x))) x[y] <- ifelse(!grepl("NA", x[y]), trimws(x[y]), "")
  return(x)
}

df_data <- data.frame(Variable = rep("All", length(vec_all)), Reads = vec_all)
df_data <- rbind(df_data, data.frame(Variable = rep("preTX", length(vec_preTX)), Reads = vec_preTX))
df_data <- rbind(df_data, data.frame(Variable = rep("comp", length(vec_var)), Reads = vec_var))

g <- ggplot(data = df_data, aes(x = Variable, y = Reads)) +
  #geom_boxplot(aes(color = Variable), size = 1) +
  geom_hline(yintercept = 42932, linetype = "dotted", color ="#3B3838", size = 0.5) +
  geom_boxplot(size = 1) +
  scale_color_manual(values = c("#DC0000", "#3C5488", "#00A087")) +
  scale_y_continuous(expand = c(0,0), limits = c(0, max(df_data$Reads) + 0.05*max(df_data$Reads)),
                     breaks = seq(0, 100000, 10000), labels = lab_indiv(0, 100000, 10000, 20000, "dec")) +
  theme (panel.background = element_rect(fill = "white"),
         panel.grid.major = element_blank(),
         axis.line = element_line(size = 1, linetype ="solid", color = "black"),
         axis.text = element_text(size = 9),
         #axis.ticks.length = unit(0.25, "cm"),
         axis.title = element_blank(), #element_text(size = 10),
         legend.position = "none",
         plot.margin = margin(0,0,0,0, unit = "cm"))
# plot(g)
# fname <- paste0("ReadsPerSample_",format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".tiff")
# ggsave(file=fname, height=6, width=6, units="cm", compression="lzw", dpi = 300)

outputFileName <- paste0("ReadsPerSample_",format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".tiff")
outputDir <- "/JD/docker/export"
outputFilePath <- file.path(outputDir, outputFileName)

# Check if the output directory exists; if not, create it
if (!dir.exists(outputDir)) {
	dir.create(outputDir, recursive = TRUE)
}

tiff(outputFilePath, compression = "lzw", type="cairo", width = 708, height = 708, units = "px", res = 300)
	print(g)
dev.off()


cat(" Average (mean) reads per Sample for run", usr_run, ":", l_run[[usr_run]]$Mean,
    "\n All : Median =", round(median(vec_all)), ", 25% =", round(quantile(vec_all, 0.25)), ", 75% =", round(quantile(vec_all, 0.75)), ", N =", length(vec_all),
    "\n PreTX : Median =", round(median(vec_preTX)), ", 25% =", round(quantile(vec_preTX, 0.25)), ", 75% =", round(quantile(vec_preTX, 0.75)), ", N =", length(vec_preTX),
    "\n", usr_comp, ": Median =", round(median(vec_var)), ", 25% =", round(quantile(vec_var, 0.25)), ", 75% =", round(quantile(vec_var, 0.75)), ", N =", length(vec_var))
