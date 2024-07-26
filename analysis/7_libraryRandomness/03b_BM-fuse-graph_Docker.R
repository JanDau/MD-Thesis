library(dplyr)

#df_BM_s$variable <- "S"
df_data_smooth$variable <- "CSR"

#df <- rbind(df_BM_s, df_BM_raw, df_data_smooth)
#df$variable <- factor(df$variable, levels = c("S", "raw", "CSR"))
df <- rbind(df_BM_raw, df_data_smooth)
df$variable <- factor(df$variable, levels = c("raw", "CSR"))
#df$variable <- droplevels(df$variable)

#df <- bind_rows_(df_BM_raw) %>% bind_rows(df_BM_s) %>% df_data_smooth
#df$variable <- factor(x = df$variable, levels = c("raw", "S", "CSR"))

g <- ggplot(data = dbinom_smooth, aes(x = x, y = value)) +
  geom_area(aes(fill = variable), alpha = 0.75, color = NA, linetype = 0) +
  scale_fill_manual(values=c("#B09C85")) +
  #geom_path(data = df, aes(x = x, y = value, color = variable, linetype = variable), size = 1) +
  geom_path(data = df, aes(x = x, y = value, color = variable), size = 1.5) +
  #scale_color_manual(values=c("#8491B4", "#DC0000", "#00A087")) +
  #scale_color_manual(values=c("#8491B4", "#DC0000")) +
  scale_color_manual(values=c("#8491B4", "#00A087")) +
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
