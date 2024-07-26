df_equal <- df_final
df_biased <- df_AT70 #input the name of the df you saved the biased

###

library(ggplot2)
library(dplyr)
library(reshape2)

###

xlab_indiv <- function(start, end, interval) { # vector from start to end with markins only at interval
  x <- seq(start, end)
  for(y in seq(length(x))) x[y] <- ifelse(y %% interval == 0, y, "")
  return(x)
}

####

# 3. Calculated distance tables
tmp_raw <- adist(df_equal$Sequence)
tmp_raw_tbl <- table(tmp_raw)/2
tmp_raw_df <- as.data.frame(tmp_raw_tbl[2:length(tmp_raw_tbl)])
colnames(tmp_raw_df) <- c("x", "AT50% CG50%")
tmp_raw_df[,2] <- tmp_raw_df[,2]/sum(tmp_raw_df[,2])
tmp_raw_df$x <- as.numeric(as.character(tmp_raw_df$x))

tmp_csr <- adist(df_biased$Sequence)
tmp_csr_tbl <- table(tmp_csr)/2
tmp_csr_df <- as.data.frame(tmp_csr_tbl[2:length(tmp_csr_tbl)])
colnames(tmp_csr_df) <- c("x", "AT70% CG30%")
tmp_csr_df[,2] <- tmp_csr_df[,2]/sum(tmp_csr_df[,2])
tmp_csr_df$x <- as.numeric(as.character(tmp_csr_df$x))

# 4. Create final data.frame
df_data <- data.frame(matrix(1:16, ncol=1, nrow=16, dimnames = list(1:16, c("x"))), stringsAsFactors = FALSE)
df_data <- df_data %>% left_join(tmp_raw_df, by ="x") %>% left_join(tmp_csr_df, by ="x")
df_data$dbinom <- dbinom(df_data$x, 16, 3/4)
df_data[is.na(df_data)] <- 0

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
df_data_smooth <- df_data_smooth %>% filter(!df_data_smooth$variable == "dbinom")
#df_data_smooth$variable <- factor(df_data_smooth$variable, levels = c("csr", "raw"))
#df_data_smooth <- df_data_smooth %>% filter(df_data_smooth$variable == "raw")
#df_data_smooth <- df_data_smooth %>% filter(df_data_smooth$variable == "csr")

# 6. Plot graph
g <- ggplot(data = dbinom_smooth, aes(x = x, y = value)) +
  geom_area(aes(fill = variable), alpha = 0.75, color = NA, linetype = 0) +
  scale_fill_manual(values=c("#B09C85")) +
  geom_path(data = df_data_smooth, aes(x = x, y = value, color = variable), size = 1.5) +
  #scale_color_manual(values=c("#3C5488", "#DC0000")) +
  scale_color_manual(values=c("#3C5488", "#DC0000")) + #blue
  #scale_color_manual(values=c("#DC0000")) + #red
  theme(panel.background = element_rect(fill = "white"),
        legend.position = "none",
        axis.line = element_line(size = 1, linetype ="solid", color = "black"),
        axis.text = element_text(size = 10),
        axis.title = element_text(size = 10),
        plot.margin = margin(0.1,0.25,0,0.1, unit = "cm")) +
  labs(x = "Nucleotide difference (k)", y = "P(X = k)") +
  #scale_x_continuous(limits = c(1, 24), breaks = seq(24), labels = xlab_indiv(1,24,4), expand=c(0,0)) +
  scale_x_continuous(limits = c(1, 16), breaks = seq(16), labels = xlab_indiv(1,16,4), expand=c(0,0)) +
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

# 