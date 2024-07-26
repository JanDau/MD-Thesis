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

###
library(reshape2)
library(ggplot2)
###

# usr_file <- choose.files(default = getwd(), caption = "Select .csv file", multi = FALSE)


args <- commandArgs(trailingOnly = TRUE)
if (grepl("\\.csv$", args[1]) && file.exists(args[1])) {
	usr_file <- args[1]
} else {
	stop(sprintf("The file '%s' is not a valid .csv file or does not exist.", args[1]))
}


df <- read.csv2(usr_file, header = TRUE, row.names = 1, stringsAsFactors = FALSE)
df <- data.frame(x = c(0, seq(nrow(df))), rbind(rep(0, ncol(df)), df), stringsAsFactors = F)

# Regression b(t) = s-(s-b0)*exp(-k*t), b = value, b0 = initial value, s = limit, k = growth constant
b <- 0
for(i in colnames(df)[c(2,4)]) {
  v <- unlist(df[i], use.names = F)
  m <- nls(v ~ I(s-(s-b)*exp(-k*x)), data=df, start=list(s=max(v), k=0.1), trace=T)
  assign(paste0("m_", i), m)
}
myfun <- function(x, m) coef(m)[1]-(coef(m)[1]-0)*exp(-coef(m)[2]*x)
mylab <- paste0("y(x) = s-(s-b0)*exp(-k*x)\ns = ", round(coef(m)[1],0), "\nb0 = 0\nk = ", 
                round(coef(m)[2],4))

df$Chao[5:19] <- NA

g <- ggplot(data = df) +
  
  #geom_point(aes(x = x[nrow(df)], y = Chao[nrow(df)]), size=2, shape = 21, color = "#DC0000", fill = "#DC0000", alpha = 0.5) +
  #geom_text(aes(x = x[nrow(df)], y = Chao[nrow(df)], label = Chao[nrow(df)]), size = 3, hjust = 1, nudge_x = -0.5, nudge_y = 0.05*max(df$Chao), color = "#DC0000") +
  #stat_function(fun = "myfun", args = list(m = m_Chao), colour = "#DC0000", size = rel(1)) +
  geom_point(aes(x = x, y = Chao), size=2, shape = 21, colour = "#DC0000", fill = NA)

g <- g +
  
  #geom_point(aes(x = x[nrow(df)], y = Rows[nrow(df)]), size=2, shape = 21, color = "#3C5488", fill = "#3C5488", alpha = 0.5) +
  #geom_text(aes(x = x[nrow(df)], y = Rows[nrow(df)], label = Rows[nrow(df)]), size = 3, hjust = 1, nudge_x = -0.5, nudge_y = 0.05*max(df$Rows), color = "#3C5488") +
  stat_function(fun = myfun, args = list(m = m_Rows), colour = "#3C5488", linewidth = rel(1)) +
  geom_point(aes(x = x, y = Rows), size=2, shape = 21, colour = "#3C5488", fill = NA)

g <- g +
  
  #geom_point(aes(x = x[nrow(df)], y = Complexity[nrow(df)]), size=2, shape = 21, color = "#00A087", fill = "#00A087", alpha = 0.5) +
  #geom_text(aes(x = x[nrow(df)], y = Complexity[nrow(df)], label = round(Complexity[nrow(df)],0)), size = 3, hjust = 1, nudge_x = -0.5, nudge_y = 0.05*max(df$Complexity), color = "#00A087") +
  stat_function(fun = myfun, args = list(m = m_Complexity), colour = "#00A087", linewidth = rel(1)) +
  geom_point(aes(x = x, y = Complexity), size=2, shape = 21, colour = "#00A087", fill = NA)

g <- g + ylab("Unique sequences") +
  xlab("Data of ... mice included") +
  #labs(title = paste0("Loss of Clonal Diversity (", strsplit(basename(file), ".csv")[[1]], ")")) +
  #annotate("text", x = 18, y = 0.75*max(df2$y), label = max(df2$y), hjust = 1) +
  scale_y_continuous(limits = c(0, 100000), breaks = seq(0,100000,10000), labels = lab_indiv(0,100000,10000,20000, "dec")) +
  scale_x_continuous(breaks = seq(0,18,1), labels = lab_indiv(0,18,1,5)) +
  theme(plot.title = element_text(hjust = 0.5, size=4.5, face="bold"),
        #plot.background = element_blank(),
        #panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.y = element_blank(),
        #panel.border = element_rect(fill = NA),
        panel.background = element_blank(), #element_rect(fill =""),
        panel.grid.major.y = element_blank(), #element_line(color = "grey", linetype = 1, size = rel(0.1)),
        axis.title.x = element_text(size = 6.5, face = "bold"),
        axis.title.y = element_text(size = 6.5, face = "bold"),
        axis.text.x = element_text(size = 6.5, face = "bold"),
        axis.text.y = element_text(size = 6.5, face = "bold"),
        #axis.ticks.x=element_blank(),
        axis.line = element_line(),
        plot.margin = margin(0,0,0,0, unit = "cm"))
# plot(g)  



# ggsave(file="Human-Regression.tiff", height=6, width=6, units="cm", compression="lzw", dpi = 300)


outputFileName <- paste0("Human-Regression.tiff")
outputDir <- "/JD/docker/export"
outputFilePath <- file.path(outputDir, outputFileName)

# Check if the output directory exists; if not, create it
if (!dir.exists(outputDir)) {
dir.create(outputDir, recursive = TRUE)
}

tiff(outputFilePath, compression = "lzw", type="cairo", width = 708, height = 708, units = "px", res = 300)
	print(g)
dev.off()


cat("Unique BCs found: ", max(df$Rows), "\n\nLimit values:",
    #"\nChao = ", round(coef(m_Chao)[1],0),
    "\nNominal = ", round(coef(m_Rows)[1],0),
    "\nSh_Count = ", round(coef(m_Complexity)[1],0)
)