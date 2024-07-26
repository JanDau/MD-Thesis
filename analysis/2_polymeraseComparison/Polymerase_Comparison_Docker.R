###############
## 1. Libraries
##############
library(ggplot2)
library(dplyr)
library(reshape2)
library(scales)

###############
## 2. Functions
##############
getFilePath <- function(v_files) {
  # Extracts the dirname of the first element of x.
  #
  # Args:
  #   v_files: Variable name (as character) of vector with file paths.
  #
  # Returns:
  #   Directory path as a string.
  if(missing(v_files) || !exists(v_files)) return(file.path(getwd(), "."))
  x <- get(v_files)
  if(length(x) == 0) return(file.path(getwd(), "."))
  path <- ifelse(nchar(dirname(x[1])) > 3, file.path(dirname(x[1]), "."), paste0(dirname(x[1]), "*.*"))
  return(path)
}

###############
## 3. Main Code
##############
# usr_files <- choose.files(default = getFilePath("usr_files"), caption = "Select the raw files", multi = TRUE)

# Docker edit ---
	args <- commandArgs(trailingOnly = TRUE)
	usr_dir <- args[1]

	# List all files in the directory with their full paths
	usr_files <- list.files(path = usr_dir, full.names = TRUE)

outputDir <- "/JD/data/barcode_data/analysis/2_polymeraseComparison/figures"
# Check if the output directory exists; if not, create it
if (!dir.exists(outputDir)) {
dir.create(outputDir, recursive = TRUE)
}

# ---------------


## 3.1 Descandant Stats ########################
##############
df_data <- data.frame(matrix(NA, ncol = 6, nrow = 4, dimnames = list(basename(usr_files), paste0("Dev_", seq(0,5)))))
vec_nseq <- c()
vec_nread <- c()

for(i in seq(length(usr_files))) {
  x <- read.table(usr_files[i], header = TRUE, stringsAsFactors = FALSE)
  vec_nseq <- append(vec_nseq, nrow(x))
  vec_nread <- append(vec_nread, sum(x$Reads))
  for(k in 0:5) {
    df_data[i, k+1] <- nrow(x[x$Distance==k,])/nrow(x)
  }
}

df_data$Sample <- rownames(df_data)
df_data <- melt(df_data)
#df_data$variable <- factor(df_data$variable, levels = rev(levels(df_data$variable)))
#colnames(df_data)[2] <- "Deviation"
df_data$Deviation <- "x"
for(x in seq(nrow(df_data))) df_data$Deviation[x] <- gsub("Dev_", "", df_data$variable[x])
df_data$Deviation <- factor(df_data$Deviation, levels = rev(unique(df_data$Deviation)))

df_info <- data.frame(Sample = basename(usr_files), nseq = vec_nseq, nread = vec_nread)

g <- ggplot(df_data, aes(x = Sample, y = value)) +
  geom_col(aes(fill = Deviation), width = 0.7, color = "black", size = 0.5) +
  geom_text(aes(x = Sample, label = paste0(round(value*100,0), "%")), position = position_stack(vjust = 0.5), color = "white", size = 2.75) +
  scale_fill_manual(values = rev(c("#DC0000", "#3C5488", "#00A087", "#7E6148", "#4DBBD5", "#E64B35"))) + #91D1C2
  #theme_classic() +
  scale_y_continuous(limits = c(0, 1.125)) +
  geom_text(data = df_info, aes(x = Sample, y = 1.1, label = nseq), size = 2.75) +
  geom_text(data = df_info, aes(x = Sample, y = 1.035, label = nread), size = 2.75) +
  annotate("text", x = 4.5, y = 1.1, label = "Seq.", size = 2.75, hjust = 0) +
  annotate("text", x = 4.5, y = 1.035, label = "Reads", size = 2.75, hjust = 0) +
  coord_cartesian(clip = 'off') +
  theme_void() +
  theme(#legend.position = "none",
    legend.text = element_text(size = 7),
    legend.title = element_text(size = 9),
    legend.key.size = unit(0.4, "cm"),
    #legend.spacing.x = unit(0.1, "cm"), 
    legend.box.spacing = unit(0, "cm"), 
    #axis.text.x = element_blank(), #element_text(size = 4),
    #axis.text.y = element_text(size = 6),
    axis.title = element_blank(),
    plot.margin = margin(0,0,0,0, "cm"))
# plot(g)
usr_fname <- paste0("Descending-stats_", format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".tiff")
# ggsave(file=usr_fname, height=6, width=6, units="cm", compression="lzw", dpi = 300)

outputFilePath <- file.path(outputDir, usr_fname)
tiff(outputFilePath, compression = "lzw", type="cairo", width = 708, height = 708, units = "px", res = 300)
	print(g)
dev.off()


## 3.2 Raw sequence percentages ########################
##############
usr_seq <- data.frame("Index"=letters[1:6],
                       "Sequence"=c("ATCTACGCACGTAGACCCTTCACGACCCTAACGGACGCTTATGATCT", #a (Ven3)
                                    "ATCTACACACTCAGAAACTTATCGAGGCTAGTGGAATCTTTTGATCT", #b (Ven1)
                                    "ATCTACCCTAAACAGAACTTATCGAGCCTATGCTTTCGGAACGATCT", #c (mCh3)
                                    "ATCTACGCTAGTCAGGACTTCCCGATGCTAACCTTGCGGAGAGATCT", #d (mCh2)
                                    "ATCTAGCCAGATATCCACTTTACGATCGGAGCCTATGCTTGTGATCT", #e (Cer3)
                                    "ATCTATCCAGAAATCCTCTTTGCGACGGGAGACTAACCTTTTGATCT"), #f (Cer2) # taken for single seq spikes
                       "Stoich"=c(0.557041833,
                                  0.24923572,
                                  0.111514863,
                                  0.049894793,
                                  0.022324292,
                                  0.009988498),
                       "Equal"=rep(100/6/100,6)
)

df_prec_raw <- data.frame(matrix(NA, ncol = 6, nrow = 4, dimnames = list(basename(usr_files), paste0("Prec_", LETTERS[1:6]))))
df_raw <- data.frame(matrix(NA, ncol = 6, nrow = 4, dimnames = list(basename(usr_files), LETTERS[1:6])))
for(i in seq(length(usr_files))) {
  x <- read.table(usr_files[i], header = TRUE, stringsAsFactors = FALSE)
  x$Reads <- x$Reads/sum(x$Reads)
  tmp <- merge(usr_seq, x, by = "Sequence")
  tmp <- tmp[, c(2, 1, ifelse(grepl("_08[7-8]", basename(usr_files)[i]), 4, 3), 5)]
  tmp <- tmp[order(tmp$Index),]
  
  for(k in 0:5) { # (theoretic value - deviation)/theoretic value, with deviation = abs(theoretic value - measured value)
    df_prec_raw[i, k+1] <- (tmp[k+1,3]-abs(tmp[k+1,3]-tmp[k+1,4]))/tmp[k+1,3]
    df_raw[i, k+1] <- tmp[k+1,4]
  }
}

vec_prec_raw_mean <- apply(df_prec_raw, 1, mean)
vec_prec_raw_sd <- apply(df_prec_raw, 1, sd)

df_raw$Polymerase <- c("Conventional", "Poofreading", "Conventional", "Proofreading")
df_raw_equal <- df_raw[c(1,2),]
df_raw_grad <- df_raw[c(3,4),]
df_raw_equal <- melt(df_raw_equal)
df_raw_grad <- melt(df_raw_grad)

df_theo <- data.frame(x1 = seq(0.6, 5.6, 1), x2 = seq(1.4, 6.4, 1),
                      y = usr_seq$Equal*100)

g <- ggplot(data = df_raw_equal, aes(x = variable, y = value*100)) +
  geom_bar(aes(fill = Polymerase), stat = "identity", position = "dodge", size = 0.5, color = "black") +
  scale_fill_manual(values = c("#DC0000", "#3C5488")) +
  scale_y_continuous(expand = c(0,0), breaks = seq(0,20,5), labels = paste0(seq(0,20,5), "%"), limits = c(0, 24)) +
  geom_segment(data = df_theo, aes(x = x1, xend = x2, y = y, yend = y), size = 1, color = "#00A087") +
  theme_classic() +
  theme(legend.position = "none",
    #aspect.ratio=5/4, #h/w
    legend.text = element_text(size = 8),
    legend.title = element_text(size = 10),
    legend.key.size = unit(0.4, "cm"),
    #legend.spacing.x = unit(0.1, "cm"), 
    legend.box.spacing = unit(0, "cm"), 
    panel.grid.major.y = element_line(),
    panel.grid.minor.y = element_line(),
    axis.text.x = element_text(size = 8),
    axis.text.y = element_text(size = 8),
    axis.title = element_blank(),
    plot.margin = margin(0,0,0,0, "cm"))
# plot(g)
usr_fname <- paste0("Equal_", format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".tiff")
# ggsave(file=usr_fname, height=6, width=4, units="cm", compression="lzw", dpi = 300)

outputFilePath <- file.path(outputDir, usr_fname)
tiff(outputFilePath, compression = "lzw", type="cairo", width = 472, height = 708, units = "px", res = 300)
	print(g)
dev.off()


trans_pow10 <- trans_new(name = "pow10",
                         transform = function(x) x^(1/3),
                         inverse = function(x) x^3)
df_theo <- data.frame(x1 = seq(0.6, 5.6, 1), x2 = seq(1.4, 6.4, 1),
                      y = usr_seq$Stoich*100)

g <- ggplot(data = df_raw_grad, aes(x = variable, y = value*100)) +
  geom_bar(aes(fill = Polymerase), stat = "identity", position = "dodge", size = 0.5, color = "black") +
  scale_fill_manual(values = c("#DC0000", "#3C5488")) +
  scale_y_continuous(trans = trans_pow10, limits = c(0, 60), breaks = c(1,10,25,50),
                     labels = c("1%", "10%", "25%", "50%"), minor_breaks = seq(0,60,1),
                     expand = c(0,0)) +
  geom_segment(data = df_theo, aes(x = x1, xend = x2, y = y, yend = y), size = 1, color = "#00A087") +
  theme_classic() +
  theme(#legend.position = "none",
        #aspect.ratio=5/4, #h/w
        legend.text = element_text(size = 7),
        legend.title = element_text(size = 9),
        panel.grid.major.y = element_line(),
        panel.grid.minor.y = element_line(),
        legend.key.size = unit(0.4, "cm"),
        #legend.spacing.x = unit(0.1, "cm"), 
        legend.box.spacing = unit(0, "cm"), 
        axis.text.x = element_text(size = 8),
        axis.text.y = element_text(size = 8),
        axis.title = element_blank(),
        plot.margin = margin(0,0,0,0, "cm"))
# plot(g)
usr_fname <- paste0("Grad_", format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".tiff")
# ggsave(file=usr_fname, height=6, width=7, units="cm", compression="lzw", dpi = 300)

outputFilePath <- file.path(outputDir, usr_fname)
tiff(outputFilePath, compression = "lzw", type="cairo", width = 826, height = 708, units = "px", res = 300)
	print(g)
dev.off()

# cat("Precision\nRaw Data:\n", paste0(names(vec_prec_raw_mean),": ", round(vec_prec_raw_mean,5), " +/- ", round(vec_prec_raw_sd,5),"\n"),
#     "CSR Data:\n", paste0(names(vec_prec_csr_mean),": ", round(vec_prec_csr_mean,5), " +/- ", round(vec_prec_csr_sd,5), "\n"))

# 
# #theoretics
# #df_theo <- data.frame(x1 = rep(0.75,6), x2 = rep(2.25,6),
# #                      y = seq(0.1667, 1, 0.166))
# 
# ## Raw
# df_raw$Sample <- rownames(df_raw)
# df_raw <- melt(df_raw)
# df_raw$variable <- factor(df_raw$variable, levels = rev(levels(df_raw$variable)))
# 
# g <- ggplot(df_raw, aes(x = Sample, y = value)) +
#   geom_col(aes(fill = variable), width = 0.7) +
#   geom_segment(data = df_theo, aes(x = x1, y = y, xend = x2, yend = y))
# plot(g)
# 
# cat("Raw Data:\n", paste0(names(vec_prec_raw_mean),": ", round(vec_prec_raw_mean,5), " +/- ", round(vec_prec_raw_sd,5), "\n"))
# 
# 
# 
# #########################################
# df_prec_csr <- data.frame(matrix(NA, ncol = 6, nrow = 4, dimnames = list(basename(usr_files), paste0("Prec_", LETTERS[1:6]))))
# df_csr <- data.frame(matrix(NA, ncol = 6, nrow = 4, dimnames = list(basename(usr_files), paste0("Perc_", LETTERS[1:6]))))
# for(i in seq(length(usr_files))) {
#   f_path <- file.path(dirname(usr_files)[i], "Clustered_CD5", "MaxDev0", "MinReads2", basename(usr_files)[i])
#   x <- read.table(f_path, header = TRUE, stringsAsFactors = FALSE)
#   x$Reads <- x$Reads/sum(x$Reads)
#   tmp <- merge(usr_seq, x, by = "Sequence")
#   tmp <- tmp[, c(2, 1, ifelse(grepl("_08[7-8]", basename(usr_files)[i]), 4, 3), 5)]
#   tmp <- tmp[order(tmp$Index),]
#   
#   for(k in 0:5) { # (theoretic value - deviation)/theoretic value, with deviation = abs(theoretic value - measured value)
#     df_prec_csr[i, k+1] <- (tmp[k+1,3]-abs(tmp[k+1,3]-tmp[k+1,4]))/tmp[k+1,3]
#     df_csr[i, k+1] <- tmp[k+1,4]
#   }
# }
# 
# vec_prec_csr_mean <- apply(df_prec_csr, 1, mean)
# vec_prec_csr_sd <- apply(df_prec_csr, 1, sd)
# 
# 
# 
# 
# 
# ## Prec Raw
# df_prec_raw$Sample <- rownames(df_prec_raw)
# df_prec_raw <- melt(df_prec_raw)
# 
# g <- ggplot(df_prec_raw, aes(x = Sample, y = value)) +
#   geom_col(aes(fill = variable), width = 0.7)
# plot(g)
# 
# cat("Raw Data:\n", paste0(names(vec_prec_raw_mean),": ", round(vec_prec_raw_mean,5), " +/- ", round(vec_prec_raw_sd,5), "\n"))
# 
# # CSR Perc
# df_csr$Sample <- rownames(df_csr)
# df_csr <- melt(df_csr)
# df_csr$variable <- factor(df_csr$variable, levels = rev(levels(df_csr$variable)))
# 
# g <- ggplot(df_csr, aes(x = Sample, y = value)) +
#   geom_col(aes(fill = variable), width = 0.7) +
#   geom_segment(data = df_theo, aes(x = x1, y = y, xend = x2, yend = y))
# plot(g)
# 
# 
# ## Prec CSR
# df_prec_csr$Sample <- rownames(df_prec_csr)
# df_prec_csr <- melt(df_prec_csr)
# 
# g <- ggplot(df_prec_csr, aes(x = Sample, y = value)) +
#   geom_col(aes(fill = variable), width = 0.7)
# plot(g)
# 
# cat("CSR Data:\n", paste0(names(vec_prec_csr_mean),": ", round(vec_prec_csr_mean,5), " +/- ", round(vec_prec_csr_sd,5), "\n"))
