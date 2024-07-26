##########################################################################################
#          BC Distribution for Groups - V2.2 - 3rd July 2020 - Jannik Daudert            #
##########################################################################################

usr_limit <- 0.005 # % as decimal, e. g. 0.5% = 0.005

#####

# -----------------------
# 1 | Loading Library
# -----------------------
packages <- c("ggplot2", "reshape2", "scales", "dplyr", "parallel", "foreach", "doParallel", "doSNOW")
if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())), dependencies = TRUE)
}
lapply(packages, library, character.only = TRUE)
rm(packages)

# -----------------------
# 2 | Functions
# -----------------------
calcQuantiles <- function(x) {
  quants <- c()
  for(i in seq(ncol(x))) {
    #quants <- append(quants, quantile(x[, i])[4]) #75%
    quants <- append(quants, quantile(x[, i], na.rm = TRUE)[4]+IQR(x[, i], na.rm = TRUE)*1.5) #75% + 1.5x IQR
    names(quants)[i] <- colnames(x)[i]
  }
  return(quants)
}

set_color <- function(i, q) {
  sub <- na.omit(df[df$col == i, ])
  
  # color only if found at least in two files higher than ...
  for(k in seq(nrow(sub))) {
    #if(sub$value[k] <= q[names(q) == sub$variable[k]]) sub$col[k] <- NA # 75th percentile + 1.5x IQR
    #if(sub$value[k] <= 50) sub$col[k] <- NA # readcount 50
    if(sub$value[k] < usr_limit) sub$col[k] <- NA # percentual reads <= usr_limit
  }
  if(nrow(sub[!is.na(sub$col),]) <= 1) sub$col <- NA
  
  return(sub)
  # for(k in rownames(sub)) {
  #   df$col[as.integer(k)] <<- sub$col[rownames(sub) == k]
  # }
}

# getFilePath <- function(v_files) {
  # # Extracts the dirname of the first element of x.
  # #
  # # Args:
  # #   v_files: Variable name (as character) of vector with file paths.
  # #
  # # Returns:
  # #   Directory path as a string.
  # if(missing(v_files) || !exists(v_files)) return(file.path(getwd(), "."))
  # x <- get(v_files)
  # if(length(x) == 0) return(file.path(getwd(), "."))
  # path <- ifelse(nchar(dirname(x[1])) > 3, file.path(dirname(x[1]), "."), paste0(dirname(x[1]), "*.*"))
  # return(path)
# }

# -----------------------
# 3 | Main Routine
# -----------------------
# usr_files <- choose.files(default = getFilePath("usr_files"), caption = "Select csv files after python script", multi = TRUE)

# Docker edit ---
args <- commandArgs(trailingOnly = TRUE)
usr_dir <- args[1]

# List all files in the directory with a specific extension and exclude subdirectories
usr_files <- list.files(path = usr_dir, pattern = "^BC-Distr_Group_.*\\.csv$", full.names = TRUE, recursive = FALSE)
usr_cohort <- regmatches(usr_files[1],regexpr("(?i)(Human|Mouse)",usr_files[1]))


for(file in usr_files) {
  csv_file <- read.csv(file)
  csv_sub <- csv_file[, 2:ncol(csv_file)]
  csv_sub[csv_sub == 0] <- NA
  #group <- length(csv_sub[1,][!is.na(csv_sub[1,])])
  group <- unlist(strsplit(basename(file), "_"))[3]
  print(paste0("Group ", group, " (file ", which(usr_files %in% file), " of ", length(usr_files), ")"))
  
  # Rename & Reorder columns
  #colnames(csv_sub)
  for(i in seq(ncol(csv_sub))) if(grepl("preTX", colnames(csv_sub)[i])) colnames(csv_sub)[i] <- paste0(colnames(csv_sub)[i], ".p")
  colnames(csv_sub) <- substring(regmatches(colnames(csv_sub), regexpr("\\.(3|T|3T)(\\.?[1-6|p])?", colnames(csv_sub))),2)
  csv_sub <- csv_sub %>% select(order(colnames(csv_sub)))
  
  df <- csv_sub
  df$col <- 1:nrow(df)
  df$shape <- apply(df, 1, function(x) sample(21:25,1))
  df$ID <- 1:nrow(df)
  
  q <- calcQuantiles(csv_sub)
  df <- melt(df, id.vars=c("ID", "col", "shape"))
  
  # for(i in unique(df$col)) { # filter out those sequences that would not be plotted anyway
  #   if(nrow(na.omit(df[df$col == i,])) == 0) df <- df %>% filter(col != i)
  # }
  
  pb <- txtProgressBar(max = length(unique(df$col)), style = 3)
  progress <- function(n) setTxtProgressBar(pb, n)
  opts <- list(progress = progress)
  
  numCores <- detectCores()
  cl <- makeCluster(numCores)
  registerDoSNOW(cl)
  
  df <- foreach(i=unique(df$col), .combine=rbind, .options.snow = opts) %dopar% {
    if(!is.na(i)) set_color(i, q)
  }
  
  close(pb)
  stopCluster(cl)
  
  #mark outlier for jitter
  df$outlier <- apply(df, 1, function(x) if(as.numeric(getElement(x, "value")) > as.numeric(q[names(q) == getElement(x, "variable")])) { 1 } else { NA } )
  
  vec_colors <- sample(rainbow(length(unique(df$col))-1))
  # vec_colors <- sample(rainbow(length(unique(df$col))))
  jitter <- position_jitter(width = 0.15, height = 0)
  df <- subset(df, value!=0) # remove empty rows
  
  df$value = df$value*100
#  df$value[df$value < 0.01] <- 0.01
  
  g <- ggplot()
  for(v in unique(df$variable)) {
    if(nrow(df[df$variable == v,]) > 25) {
      g <- g + geom_boxplot(data=df[df$variable == v,], aes(x = variable, y = value), show.legend=FALSE, outlier.shape = NA, size=0.5) +
        geom_point(data=df[!is.na(df$outlier), ], aes(x = variable, y = value), size=rel(0.5), shape=16, position = jitter)
    } else {
      g <- g + geom_point(data=df[df$variable == v,], aes(x = variable, y = value), size=rel(0.5), position = jitter)
    }
  }
  g <- g +  
    geom_point(data=df[!is.na(df$col), ], aes(x = variable, y = value, fill = factor(col), shape = factor(shape)), size=1.5, show.legend=FALSE, position = jitter) + #shape = factor(shape))
    scale_shape_manual(values = rep(21:25, ceiling((length(unique(df$shape))-1)/5))) +
    scale_fill_manual(values = vec_colors) +
    coord_trans(y = "log10") +
    #scale_y_continuous(breaks = c(1 %o% 10^(0:4))/100, limits = c(0.01, 150), labels = paste0(c("\u2264 0.01", 0.1, 1, 10, 100), "%"), expand = c(0,0)) +
    scale_y_continuous(breaks = c(1 %o% 10^(0:6))/10000, limits = c(0.0001, 150), labels = paste0(c("\u2264 0.0001", 0.001, 0.01, 0.1, 1, 10, 100), "%"), expand = c(0,0)) +
    annotation_logticks(sides = "l", scaled = FALSE, size = 0.5, 
                        short = unit(0.05, "cm"), mid = unit(0.1, "cm"), long = unit(0.15, "cm")) +
    scale_x_discrete(breaks = levels(df$variable), limits = levels(df$variable)) +
    geom_hline(yintercept=0.5, linetype="dashed", color = "red") +
    xlab("Mouse") +
    ylab("Reads of a Certain Barcode") +
    labs(title = paste0("Barcodes occuring in ", group , " animals"),
         subtitle = paste0("Total sequences: ", nrow(csv_file),
                           #"\n Sequences that are at least one time outliers: ", length(unique(df$ID[!is.na(df$outlier)])),
                           #" (", round(length(unique(df$ID[!is.na(df$outlier)]))/nrow(csv_file)*100,0), "%)",
                           "\n Sequences with biol. relevance in \u2265 2 animals: ", length(unique(df$col))-1)) +
    theme(plot.title = element_text(hjust = 0.5, size=10.5, face="bold"),
          plot.subtitle = element_text(hjust = 0.5, size=rel(0.65), face="italic"),
          plot.tag = element_text(hjust = 0.5, size=rel(0.9)),
          #plot.background = element_blank(),
          #panel.grid.minor = element_blank(),
          panel.grid.major.x = element_blank(),
          panel.grid.minor.y = element_blank(),
          #panel.border = element_rect(fill = NA),
          panel.background = element_blank(), #element_rect(fill =""),
          panel.grid.major.y = element_line(color = "grey", linetype = 1, size = rel(0.1)),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(), #element_text(),
		  axis.text = element_text(size = 8),
          axis.text.x = element_text(angle = 45, hjust=1, vjust=1),
          #axis.ticks.x=element_blank(),
          axis.line = element_line())
  
  # -----------------------
  # 10 | Print & Export
  # -----------------------
  # Print in RStudio
  # print(g)
  
  # fname <- paste0("Group",group,"_",format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".tiff") 
  
#  dir_save <- file.path(getwd(), 
#                        ifelse(grepl("[hH]uman", usr_files[1]), "Fig_human", "Fig_mouse"),
#                        tail(unlist(strsplit(dirname(usr_files[1]), "/")), 1))
#  if(!dir.exists(dir_save)) dir.create(dir_save)
  
  # Export: Name of the figure will be the parent folder name, saved as tiff
  # ggsave(file=fname, path=getwd(), height=7, width=10, units="cm", compression="lzw", dpi = 300)
  
  
outputFileName <- paste0(usr_cohort,"_Group-",group,"_",format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".tiff")
outputDir <- file.path("/JD/docker/export", usr_cohort)
outputFilePath <- file.path(outputDir, outputFileName)

# Check if the output directory exists; if not, create it
if (!dir.exists(outputDir)) {
dir.create(outputDir, recursive = TRUE)
}

tiff(outputFilePath, compression = "lzw", type="cairo", width = 1181, height = 826, units = "px", res = 300)
	print(g)
dev.off()
  
}