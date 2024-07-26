######
# Don't Change Below
######

# 1. Functions
lab_indiv <- function(ymin, ymax, tick_interval, label_interval) { # vector from start to end with markins only at interval
  x <- seq(ymin, ymax, tick_interval)
  for(y in seq(length(x))) x[y] <- ifelse(as.numeric(x[y]) %% label_interval == 0, x[y], "")
  return(x)
}

# 2. Imports
library("ggplot2")
#library("ggsci") # for colors

#3 Loading Data
# csv_file <- choose.files(default = "", caption = "Select BC-Distr_Stats file", multi = FALSE)

# Docker edit ---
args <- commandArgs(trailingOnly = TRUE)
usr_dir <- args[1]

# List all files in the directory with a specific extension and exclude subdirectories
csv_file <- list.files(path = usr_dir, pattern = "^BC-Distr_Stats_.*\\.csv$", full.names = TRUE, recursive = FALSE)
print(csv_file)
# ---------------
usr_cohort <- regmatches(csv_file,regexpr("(?i)(Human|Mouse)",csv_file))

usr_csv <- read.csv(csv_file, header = FALSE)
colnames(usr_csv) <- c("x", "real")
usr_csv <- usr_csv[order(usr_csv$x),]
usr_size <- sum(usr_csv$real) # the number of unique CSR-treated sequences

if(max(usr_csv$x) < 18) usr_csv <- rbind(usr_csv, data.frame(matrix(c(seq(nrow(usr_csv)+1, 18), rep(0, 18-nrow(usr_csv))), 
                                                                     byrow = FALSE, ncol = 2, nrow = (18-nrow(usr_csv)), 
                                                                     dimnames = list(seq(nrow(usr_csv)+1, 18), c("x", "real")))))

no_of_mice <- usr_csv$real[1] # Number of mice that share 0, 1, 2, ... BCs (iterative variable)
BCs_per_mouse <- no_of_mice # maximum different Barcodes per mouse
v_seq <- c(no_of_mice) # saves the number of mice that share 0, 1, ... BCs as a vector
print(no_of_mice)
# no_of_mice serves as the respective subpopulation. If a barcode is shared between three
# animals, it must be also shared between two animals. Thus, when starting at "no BC shared"
# the subpopulation (reference) becomes smaller and smaller although the BC pool size (usr_sizes)
# remains identical
while(no_of_mice > 0) {
  f <- dbinom(0:BCs_per_mouse, BCs_per_mouse, no_of_mice/usr_size) # probability
  no_of_mice <- which.max(f)-1 #-1 because count starts with 1 but i include the 0 also
  v_seq <- append(v_seq, no_of_mice)
}

usr_csv <- cbind(usr_csv, v_seq[1:nrow(usr_csv)])
colnames(usr_csv)[ncol(usr_csv)] <- "theoretic"
usr_csv[is.na(usr_csv)] <- 0
#plot(v_seq)
#points(x=usr_csv$V1, y=usr_csv$V2, col="blue")

### ---------- Stats Output START ---------
print(paste("Size:", usr_size,", BCs/mouse:",BCs_per_mouse))

x <- BCs_per_mouse
v_seq <- c(BCs_per_mouse)

while(x > 0) {
  f <- dbinom(0:BCs_per_mouse, BCs_per_mouse, x/usr_size)
  x <- which.max(f)-1 #-1 because count starts with 1 but i include the 0 also
  v_seq <- append(v_seq, x)
}

df_stats <- data.frame(
  `shared.by.x.mice` = 1:length(v_seq),
  `theoretic.prob` = round(v_seq/BCs_per_mouse,4)*100
)

print(df_stats)
### ---------- Stats Output END ---------

plot.new()
df <- data.frame(xspline(usr_csv[,c(1,2)], shape=-0.75, lwd=2, draw=F))
plot.new()
#df <- cbind(df, theo = data.frame(xspline(usr_csv[,c(1,3)], shape=-0.75, lwd=2, draw=F))$y)
df2 <- data.frame(xspline(usr_csv[,c(1,3)], shape=-0.75, lwd=2, draw=F))

df$y[df$y < 1] <- 0
df2$y[df2$y < 1] <- 0

usr_intersect <- NA
for(i in seq(nrow(df))) {
  df2_closest <- which.min(abs(df2$x-df$x[i]))
  if(df2$y[df2_closest] < df$y[i]) {
    usr_intersect <- df$x[i]
    break
  }
}

g <- ggplot()
if(!is.na(usr_intersect)) {
  x <- c()
  y_min <- c()
  y_max <- c()
  for(i in seq(which(df$x == usr_intersect), nrow(df))) {
    df2_closest <- which.min(abs(df2$x-df$x[i]))
    x <- c(x, df$x[i])
    y_min <- c(y_min, df2$y[df2_closest])
    y_max <- c(y_max, df$y[i])
  }
  df_rib <- data.frame(x, y_min, y_max)
  
  g <- g +
    #geom_vline(xintercept=floor(usr_intersect)) +
    #annotate("text", x = floor(usr_intersect)+0.5, y = 0.9*max(df$y), hjust = 0, label = paste0("Intersection at: ", floor(usr_intersect)), size = 6) +
    geom_ribbon(data = df_rib, aes(x = x, ymin = y_min, ymax = y_max), fill = "#DC0000", alpha = 0.25)
}

if(usr_cohort == "Mouse" || usr_cohort == "mouse") {
  g <- g +
    geom_path(data = df, aes(x = x, y = y), color = "#DC0000", linetype = "solid", size = 1.5) + # Measured mouse
    scale_y_continuous(breaks = seq(0,50000,5000), expand = c(0,0), labels = lab_indiv(0, 50000, 5000, 10000)) #for mCh
} else {
  g <- g +
    geom_path(data = df, aes(x = x, y = y), color = "#3C5488", linetype = "solid", size = 1.5) + # Measured human
    scale_y_continuous(breaks = seq(0,50000,2500), expand = c(0,0), labels = lab_indiv(0, 50000, 2500, 10000)) #for Cer
}

g <- g +
  geom_path(data = df2, aes(x=x, y = y), color = "#7E6148", linetype = "solid", size = 1) + # Expected line
  scale_x_continuous(breaks = seq(1,18,1), labels = lab_indiv(1, 18, 1, 5)) +
  labs(x = "Occurance in ... animals", y = "Unique Barcodes") +
  #annotate("segment", x = 3/4*max(df$x)-0.4, xend = 3/4*max(df$x)-0.1 , y = 3/4*max(df$y), yend = 3/4*max(df$y), size = 2, color = "#E64B35FF") +
  #annotate("text", x = 3/4*max(df$x), y = 3/4*max(df$y), color = "#E64B35FF", size = 5, label = "Expected", hjust = 0) +
  #annotate("segment", x = 3/4*max(df$x)-0.4, xend = 3/4*max(df$x)-0.1 , y = 3/4*max(df$y)-1/15*max(df$y), yend = 3/4*max(df$y)-1/15*max(df$y), size = 2, color = "#3C5488FF") +
  #annotate("text", x = 3/4*max(df$x), y = 3/4*max(df$y)-1/15*max(df$y), color = "#3C5488FF", size = 5, label = "Measured", hjust = 0) +
  theme (panel.background = element_rect(fill = "white"),
         panel.grid.major = element_blank(),
         axis.line = element_line(size = 1, linetype ="solid", color = "black"),
         axis.text = element_text(size = 9),
         axis.title = element_blank(), #element_text(size = 10),
         plot.margin = margin(0.5,0.5,0.5,0.5, unit = "cm"))

# plot(g)
# ggsave(file=paste0("Overlap_",regmatches(csv_file,regexpr("(Human|Mouse)",csv_file)),".tiff"), height=4.5, width=8, units="cm", compression="lzw", dpi = 300)


outputFileName <- paste0("Overlap_",usr_cohort,".tiff")
outputDir <- "/JD/docker/export"
outputFilePath <- file.path(outputDir, outputFileName)

# Check if the output directory exists; if not, create it
if (!dir.exists(outputDir)) {
dir.create(outputDir, recursive = TRUE)
}

tiff(outputFilePath, compression = "lzw", type="cairo", width = 944, height = 531, units = "px", res = 300)
	print(g)
dev.off()