usr_dev <- 0 # estim. based on stringent seq. only

# Docker edit ---
  args <- commandArgs(trailingOnly = TRUE)
  csv_file <- args[1]
  file_dir <- args[2]

	outputFileName <- ifelse(grepl("human", basename(csv_file)), "Human-Regression.tiff", "Mouse-Regression.tiff")
	outputDir <- "/JD/docker/export"
	outputFilePath <- file.path(outputDir, outputFileName)

	# Check if the output directory exists; if not, create it
	if (!dir.exists(outputDir)) {
	dir.create(outputDir, recursive = TRUE)
	}
# ---

# Choose the same csv file as for sample allocation
#csv_file <- choose.files(default = "", caption = "Select csv sample alloc file", multi = FALSE)
csv_all <- read.csv(csv_file, header = TRUE, fileEncoding="UTF-8-BOM", stringsAsFactors = FALSE)
#file_dir <- choose.dir(default = "", caption = "Choose Preprocessing Directory")

seqs <- c()
seq2 <- c()
df <- data.frame("File"=character(), "New"=numeric(), "Total"=numeric(), stringsAsFactors = FALSE)


for (i in seq(nrow(csv_all))) {
  fpath <- file.path(file_dir, csv_all$Run[i], "Reads", sprintf("ITRGB_%03d.fna", csv_all$Primer[i])) 
  if(!file.exists(fpath)) next
  f <- read.table(fpath, header=TRUE, stringsAsFactors = FALSE)
  f <- f[f$Distance == usr_dev,]
  seq2 <- append(seq2, nrow(f))
  #if (!grepl("preTx",basename(Files)[i])) f <- f[f$Reads>2,] # Readfilter
  seqdiff <- f$Sequence[!f$Sequence %in% seqs]
  seqs <- append(seqs, seqdiff)
  df <- rbind(df, data.frame(File=paste0(csv_all$ID[i], "_", csv_all$Name[i]),
                             New=length(seqdiff),
                             Total=length(seqs)))
}

df <- df[order(-df$New),]
#plot(x=1:nrow(df), y=df$New, ylim=c(0, max(df$New)))

df$Total2 <- NA
for (i in seq(nrow(df))) {
  df$Total2[i] <- sum(df$New[1:i])
}
#plot(x=1:nrow(df), y=df$Total2, ylim=c(0, max(df$Total2)))


#####
# Regression curve
###

library(reshape2)
library(ggplot2)
library(Cairo)

#file <- choose.files(default = "", caption = "Select file", multi = FALSE)
#f <- read.csv(file, header = TRUE)
x <- seq(nrow(df))
y <- df$Total2

# Regression # b(t) = s-(s-b0)*exp(-k*t), b = value, b0 = initial value, s = limit, k = growth constant
df2 <- data.frame(x, y)
b <- 0
m <- nls(y ~ I(s-(s-b)*exp(-k*x)), data=df2, start=list(s=max(y), k=0.1), trace=T) #I(a*(x/(b+x)))
#y_est<-predict(m,df2$x)
#plot(x,y)
#lines(x,y_est, col = "red")
#summary(m)
#rm(df)

# Plotting
myfun <- function(x) coef(m)[1]-(coef(m)[1]-0)*exp(-coef(m)[2]*x)
mylab <- paste0("y(x) = s-(s-b0)*exp(-k*x)\ns = ", round(coef(m)[1],0), "\nb0 = 0\nk = ", 
                round(coef(m)[2],4))

g <- ggplot(data=df2) +
  geom_point(aes(x=x, y=y), size=rel(2), shape = 21, colour = "black", fill = "white") +
  stat_function(fun = myfun, colour = "red", size = rel(1)) +
  annotate(geom = "label", size=rel(4.5), x = max(df2$x)*3/5, y = max(df2$y)/2, label = mylab, bg = "white") +
  ylab("Unique sequences") +
  xlab("Samples included") +
  #labs(title = paste0("Loss of Clonal Diversity (", strsplit(basename(file), ".csv")[[1]], ")")) +
  #scale_y_continuous(limits = c(0, 10.5)) +
  theme(plot.title = element_text(hjust = 0.5, size=rel(1.25), face="bold"),
        #plot.background = element_blank(),
        #panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.y = element_blank(),
        #panel.border = element_rect(fill = NA),
        panel.background = element_blank(), #element_rect(fill =""),
        panel.grid.major.y = element_line(color = "grey", linetype = 1, size = rel(0.1)),
        axis.title.x = element_text(size = rel(1.25), face = "bold"),
        axis.title.y = element_text(size = rel(1.25), face = "bold"),
        axis.text.x = element_text(size = rel(1.25), face = "bold"),
        axis.text.y = element_text(size = rel(1.25), face = "bold"),
        #axis.ticks.x=element_blank(),
        axis.line = element_line())
#plot(g)
# ggsave(file=outputFilePath,
       # height=10, width=10, units="cm", compression="lzw", dpi = 300)
# ggsave(file=outputFilePath, plot=g, device="cairo_tiff", height=10, width=10, units="cm", compression="lzw", dpi = 300)


cat("Output will be saved at:", outputFilePath, "\n")

tiff(outputFilePath, compression = "lzw", type="cairo", width = 1181, height = 1181, units = "px", res = 300)
	print(g)
dev.off()

# compression = 5 = LZW
# Cairo(file = outputFilePath, type="tiff", width = 10, height = 10, dpi = 300, units = "px", compression = 5)
	# plot(g) # Print your plot to the Cairo device
# dev.off() # Close the Cairo device to save the file

