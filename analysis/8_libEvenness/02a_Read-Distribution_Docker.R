###
# 0. User Settings

usr_high <- "preTX"
usr_low <- "83d" #c("BM") # single or as vector; possible values: 19d, 41d, 83d, 175d, BM, all (cave: all without preTX)

###
library(ggplot2)

if(length(usr_low) > 1) usr_low <- paste(usr_low, collapse = "|")
if(usr_low == "all") usr_low <- "19d|41d|83d|175d|BM"

# usr_dir_mouse <- choose.dir(default = getwd(), caption = "Select directory with CSR-treated mouse data, e.g. Mouse_CSR")
# usr_dir_xeno <- choose.dir(default = usr_dir_mouse, caption = "Select directory with CSR-treated xenograft data, e.g. Human_CSR")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 2 || !dir.exists(args[1]) || !dir.exists(args[2])) {
    stop("Two valid directory paths must be provided and both must exist.")
} else {
    usr_dir_mouse <- args[1]
    usr_dir_xeno <- args[2]
}

###

df_data <- data.frame(matrix(NA, 0, 107))
colnames(df_data) <- c("Cohort", "Sample", "Cat", "Sequences", "Reads1", "Reads5", "Reads10", paste0("R", 1:100))

for(cohort in c("Mouse", "Human")) {
  if(cohort == "Mouse") {
    usr_dir <- usr_dir_mouse
  } else {
    usr_dir <- usr_dir_xeno
  }
  usr_mice <- dir(usr_dir, pattern = "^(SF-|preTX)")
  l_reads <- list("High" = c(), "High_SD" =c(), "Low" = c(), "Low_SD" = c())
  
  for(usr_mouse in usr_mice) {
    usr_path <- file.path(usr_dir, usr_mouse)
    #usr_files <- list.files(usr_path, recursive = FALSE, full.names = TRUE)
    usr_files <- setdiff(list.files(usr_path, recursive = FALSE, full.names = TRUE), list.dirs(usr_path, recursive = FALSE))
    for(i in seq(length(usr_files))) {
      if(!grepl("Spacer", usr_files[i]) & grepl(paste0(usr_high, "|", usr_low), usr_files[i])) {
        #x <- read.table(file.path(usr_path, usr_files[i]), header = TRUE, stringsAsFactors = FALSE)
        x <- read.table(usr_files[i], header = TRUE, stringsAsFactors = FALSE)
        x <- x[order(x$Reads, decreasing = TRUE),]
        x$Perc <- cumsum(x$Reads)/sum(x$Reads) # cumulative reads as %
        x$ID <- 1:nrow(x)/nrow(x)
        
        r_tmp <- c()
        for(r in seq(0.01,1,0.01)) {
          #r_test <- which(abs(x$Perc-r)==min(abs(x$Perc-r)))
          r_test <- which(abs(x$ID-r)==min(abs(x$ID-r)))
          if(length(r_test) > 1) r_test <- r_test[1]
          r_tmp <- c(r_tmp, x$Perc[r_test])
        }
        names(r_tmp) <- paste0("R", 1:100)
        cat_tmp <- ifelse(grepl(usr_high, usr_files[i]), "high", "low")
        fname_tmp <- paste(head(unlist(strsplit(basename(usr_files[i]), "_")),3), collapse = "-")
        fname <- ifelse(grepl(usr_high, dirname(usr_files[i])), fname_tmp, paste0(usr_mouse, "_", fname_tmp))
        df_data <- rbind(df_data, data.frame(Cohort = cohort,
                                             Sample = fname,
                                             Cat = cat_tmp,
                                             Sequences = nrow(x),
                                             Reads1 = x$Reads[1]/sum(x$Reads),
                                             Reads5 = sum(x$Reads[1:5])/sum(x$Reads),
                                             Reads10 = sum(x$Reads[1:10])/sum(x$Reads),
                                             as.list(r_tmp)))
        if(grepl(usr_high, usr_files[i])) {
          l_reads$High <- append(l_reads$High, mean(x$Reads))
          names(l_reads$High)[length(l_reads$High)] <- fname
          l_reads$High_SD <- append(l_reads$High_SD, sd(x$Reads))
          names(l_reads$High_SD)[length(l_reads$High_SD)] <- fname
        } else {
          l_reads$Low <- append(l_reads$Low, mean(x$Reads))
          names(l_reads$Low)[length(l_reads$Low)] <- fname
          l_reads$Low_SD <- append(l_reads$Low_SD, sd(x$Reads))
          names(l_reads$Low_SD)[length(l_reads$Low_SD)] <- fname
        }
      }
    }
  }
}

df_high_mouse <- data.frame(matrix(0, 1, 3, dimnames = list(c(),c("x","y","err"))))
x <- 1:100
y <- c()
err <- c()
d <- subset(df_data, Cat == "high" & Cohort == "Mouse")
for(i in x) {
  y <- c(y, mean(d[,paste0("R",i)]))
  err <- c(err, sd(d[,paste0("R",i)]))
}
df_high_mouse <- rbind(df_high_mouse, data.frame(x,y,err))

df_high_xeno <- data.frame(matrix(0, 1, 3, dimnames = list(c(),c("x","y","err"))))
x <- 1:100
y <- c()
err <- c()
d <- subset(df_data, Cat == "high" & Cohort == "Human")
for(i in x) {
  y <- c(y, mean(d[,paste0("R",i)]))
  err <- c(err, sd(d[,paste0("R",i)]))
}
df_high_xeno <- rbind(df_high_xeno, data.frame(x,y,err))

df_low_mouse <- data.frame(matrix(0, 1, 3, dimnames = list(c(),c("x","y","err"))))
y <- c()
err <- c()
d <- subset(df_data, Cat == "low" & Cohort == "Mouse")
for(i in x) {
  y <- c(y, mean(d[,paste0("R",i)]))
  err <- c(err, sd(d[,paste0("R",i)]))
}
df_low_mouse <- rbind(df_low_mouse, data.frame(x,y,err))

p <- ggplot(data = df_high_mouse, aes(x = x)) +
  geom_line(aes(y = x/100), color = "grey", linetype = "dashed", size = 1) + # dashed grey line indicating 100% equal distribution
  geom_ribbon(aes(x=x, ymin = y-err, ymax = y+err), fill = "#DC0000", linetype = "solid", alpha = 0.5, color = "#DC0000") + # red error area for mCherry preTX samples
  geom_line(aes(y = y), color = "#DC0000", alpha = 1, linetype = "solid", size = 1.25) + # red mean line for mCherry preTX samples
  geom_ribbon(data = df_low_mouse, aes(x = x, ymin = y-err, ymax = y+err), linetype = "solid", fill = "#00A087", alpha = 0.5, color = "#00A087") + # green error area for low diverse murine samples
  geom_line(data = df_low_mouse, aes(y = y), color = "#00A087", alpha = 1, linetype = "solid", size = 1.25) + # green mean line for low diverse murine samples
  geom_ribbon(data = df_high_xeno, aes(x = x, ymin = y-err, ymax = y+err), linetype = "solid", fill = "#3C5488", alpha = 0.5, color = "#3C5488") + # blue error area for Cerulean preTX samples
  geom_line(data = df_high_xeno, aes(y = y), color = "#3C5488", alpha = 1, linetype = "solid", size = 1.25) + # blue mean line for Cerulean preTX samples

  theme (panel.background = element_rect(fill = "white"),
         panel.grid.major = element_line(color = "black", linetype = "dotted"), #element_blank()
         axis.line = element_line(size = 1, linetype ="solid", color = "black"),
         axis.text = element_text(size = rel(1.75)),
         axis.title = element_blank(), #element_text(size = rel(3.5)),
         plot.margin = margin(1,1,1,1, unit = "cm")) +
  scale_x_continuous(limits = c(0,105), breaks = seq(0,100,25), labels = paste0(seq(0,100,25), "%"), expand=c(0,0)) + 
  scale_y_continuous(labels = scales::percent, limits = c(0,1.05), breaks = seq(0,1,0.25), expand=c(0,0)) +
  labs(x = "Barcodes (cumulative)", y = "Reads (cumulative)")

# plot(p)

# fname <- paste0("Read-Distr_", format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".tiff")
# ggsave(file=fname, height=15, width=15, units="cm", compression="lzw", dpi = 300)

outputFileName <- paste0("Read-Distr_", format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".tiff")
outputDir <- "/JD/docker/export"
outputFilePath <- file.path(outputDir, outputFileName)

# Check if the output directory exists; if not, create it
if (!dir.exists(outputDir)) {
dir.create(outputDir, recursive = TRUE)
}

tiff(outputFilePath, compression = "lzw", type="cairo", width = 1771, height = 1771, units = "px", res = 300)
	print(p)
dev.off()