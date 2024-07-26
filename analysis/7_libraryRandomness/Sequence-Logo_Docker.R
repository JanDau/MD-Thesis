#install.packages("ggseqlogo")
require(ggplot2)
require(ggseqlogo)

usr_width <- 1889
usr_height <- 118


#Cer
Cer <- "ATCTANNCAGNNATCNNCTTNNCGANNGGANNCTANNCTTNNGATCT"
vec_Cer <- c()
for(i in c("A","T","C","G")) {
  vec_Cer <- append(vec_Cer, gsub("N", i, Cer))
}

#mCH
mCh <- "ATCTA..CTA..CAG..CTT..CGA..CTA..CTT..GGA..GATCT"
vec_mCh <- c()
for(i in c("A","T","C","G")) {
  vec_mCh <- append(vec_mCh, gsub("\\.", i, mCh))
}

# cs1 <- make_col_scheme(chars=c('A', 'T', 'C', 'G'), groups=c('gr1', 'gr2', 'gr3', 'gr4'), 
#                      cols=c('#DC0000', '#3C5488', '#00A087', '#7E6148'))

g <- ggplot() + 
#  geom_logo(vec_Cer, method = "probability", col_scheme = cs1) +
  geom_logo(vec_mCh, method = "probability") +
  theme_void() +
  theme(legend.position = "none")
# plot(g)

# fname <- paste0("mCh-Logo_",format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".tiff")
# ggsave(file=fname, height=1, width=16, units="cm", compression="lzw", dpi = 300)


outputFileName <- paste0("mCh-Logo_",format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".tiff")
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


g <- ggplot() + 
  geom_logo(vec_Cer, method = "probability") +
  theme_void() +
  theme(legend.position = "none")
# plot(g)

# fname <- paste0("Cer-Logo_",format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".tiff")
# ggsave(file=fname, height=1, width=16, units="cm", compression="lzw", dpi = 300)

outputFileName <- paste0("Cer-Logo_",format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".tiff")
outputFilePath <- file.path(outputDir, outputFileName)

tiff(outputFilePath, compression = "lzw", type="cairo", width = usr_width, height = usr_height, units = "px", res = 300)
	print(g)
dev.off()