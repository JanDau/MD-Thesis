# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# + Method Comparison - VAR +
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
if(!exists("usr")) usr <- list("path" = list()) # Don't Change

usr[["nseq"]] <- 6 # number of known sequences (1 or 6)
usr[["equal"]] <- FALSE # for the 6-seq-spike ins, set TRUE for the equally-distributed files
usr$path[["Raw"]] <- ""
usr$path[["Stringent"]] <- "MaxDev0"          # path to the files, beginning from the raw files that are interactively chosen
usr$path[["distance"]] <- NA #"MaxDev2"       # set NA if it should not be included
usr$path[["Reads"]] <- "MinReads2" 
usr$path[["Clustered"]] <- "Clustered_CD5"
usr$path[["SC"]] <- "MaxDev0/Clustered_CD5"
usr$path[["SCR"]] <- "MaxDev0/Clustered_CD5/MinReads2"
usr$path[["CS"]] <- "Clustered_CD5/MaxDev0"
usr$path[["CSR"]] <- "Clustered_CD5/MaxDev0/MinReads2"

# -----------------------
# 1 | Packages
# -----------------------
packages <- c("ggplot2", "reshape2", "scales", "patchwork")
if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())), dependencies = TRUE)
}
lapply(packages, library, character.only = TRUE)
rm("packages")

# -----------------------
# 2 | Functions
# -----------------------
getFilePathList <- function(f) {
  if(!f %in% names(usr) || identical(dirname(usr[[f]]), character(0))) return(file.path(getwd(), "."))
  file.path(dirname(usr[[f]]), ".")[1]
}

# -----------------------
# 3 | Main Routine
# -----------------------
user_seq <- data.frame("Index"=letters[1:6],
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

# usr[["files"]] <- choose.files(default = getFilePathList("files"), caption = "Select the raw files", multi = TRUE)

# ------- Docker edit ----- #
args <- commandArgs(trailingOnly = TRUE)

# Function to check if the file is a .fna file and exists
check_and_add_file <- function(file_path) {
  if (grepl("\\.fna$", file_path) && file.exists(file_path)) {
    return(file_path)
  } else {
    warning(sprintf("The file '%s' is not a valid .fna file or does not exist.", file_path))
    return(NULL)
  }
}

# Apply the function to each argument and store the results
usr[["files"]] <- unlist(Filter(Negate(is.null), lapply(args, check_and_add_file)))
print(usr)
# ------------------------ #

if(usr$nseq == 1) {
  df <- data.frame(matrix(NA, sum(!is.na(usr$path)), length(usr$files)+4))
  colnames(df) <- c("Strategy", basename(usr$files), "Mean", "SD", "nSeq")
  df$Strategy <- names(usr$path)[!is.na(usr$path)]
  dfSeq <- df[,1:(ncol(df)-3)]
  user_seq_single = user_seq$Sequence[6]
  
  for(i in seq(length(usr$files))) {
    for(x in names(usr$path)[!is.na(usr$path)]) {
      file <- read.table(file.path(dirname(usr$files[i]), usr$path[[x]], basename(usr$files[i])), header=TRUE, stringsAsFactors = FALSE)
      df[which(df$Strategy == x), which(colnames(df) == basename(usr$files[i]))] <- round(file$Reads[file$Sequence == user_seq_single]/sum(file$Reads),4)
      dfSeq[which(df$Strategy == x), which(colnames(dfSeq) == basename(usr$files[i]))] <- nrow(file)
    }
  }

  if(length(usr$files) > 1) {
    df$Mean <- round(apply(df[,2:(ncol(df)-3)], 1, mean),4)
    df$SD <- round(apply(df[,2:(ncol(df)-3)], 1, sd),4)
    df$nSeq <- round(apply(dfSeq[,2:ncol(dfSeq)], 1, mean),0)
  } else {
    df$Mean <- df[,2]
    df$SD <- 0
    df$nSeq <- dfSeq[,2]
  }
  
  g <- ggplot(df, aes(Strategy, Mean)) +
    geom_col(width = 0.75) + 
    geom_col(aes(y = 1), fill=NA, color = "black", size = rel(1), width = 0.75) + 
    geom_errorbar(aes(ymin=Mean-SD, ymax=Mean+SD), width=0.15, size = rel(0.5)) +
    geom_label(aes(label = Mean*100, y = Mean/2), color = "black", label.size=NA, alpha = 0.75, fill="white", size = rel(6)) +
    geom_text(aes(label = nSeq, y = 1.10), size = rel(6)) +
    labs(x = "Strategy", y = "%") +
    scale_x_discrete(limits=names(usr$path)[!is.na(usr$path)]) + 
    scale_y_continuous(labels = percent, breaks = seq(0,1,0.2)) +
    theme(legend.position = "none",
          panel.grid.minor = element_blank(),
          panel.grid.major.x = element_blank(),
          panel.grid.major.y = element_line(colour="#848484"),
          panel.background = element_blank(),
          axis.line = element_blank(),
          axis.ticks = element_blank(),
          axis.title = element_blank(),
          axis.text = element_text(size = rel(1.5)),
          plot.margin=grid::unit(c(0,0,0,0), "cm")) #t, r, b, l
  # print(g)
  
  
	usr[["filename"]] <- paste0("Method-Comp_",format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".tiff")
	outputDir <- "/JD/docker/export"
	outputFilePath <- file.path(outputDir, usr[["filename"]])

	# Check if the output directory exists; if not, create it
	if (!dir.exists(outputDir)) {
	dir.create(outputDir, recursive = TRUE)
	}

	tiff(outputFilePath, compression = "lzw", type="cairo", width = 1181, height = 708, units = "px", res = 300)
		print(g)
	dev.off()
  
  # usr[["filename"]] <- paste0("Method-Comp_",format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".tiff")
  # ggsave(file=usr$filename, path=file.path(getwd(), "."), height=10, width=10, units="cm", compression="lzw", dpi = 300)
}

############
# Routine for 6 seq
##########

if(usr$nseq == 6) {
  df <- data.frame(matrix(NA, 6, sum(!is.na(usr$path))+1))
  colnames(df) <- c("seq", names(usr$path)[!is.na(usr$path)])
  df$seq <- LETTERS[1:6]
  usr[["nseq"]] <- list()
  
  for(x in names(usr$path)[!is.na(usr$path)]) {
    df_tmp <- data.frame(matrix(NA, 6, length(usr$files)))
    rownames(df_tmp) <- letters[1:6]
    colnames(df_tmp) <- basename(usr$files)
    nseq_tmp <- c()
    for(i in seq(length(usr$files))) {
      file <- read.table(file.path(dirname(usr$files[i]), usr$path[[x]], basename(usr$files[i])), header=TRUE, stringsAsFactors = FALSE)
      file$Reads <- file$Reads/sum(file$Reads)
      tmp <- merge(file, user_seq, by = "Sequence")
      df_tmp[,i] <- tmp$Reads[order(tmp$Index)]
      nseq_tmp <- append(nseq_tmp, nrow(file))
    }
    if(length(usr$files) > 1) { df[x] <- apply(df_tmp, 1, mean) } else { df[x] <- df_tmp }
    usr$nseq[[x]] <- c(round(mean(nseq_tmp),0), round(sd(nseq_tmp),0))
  }

  # Calculate Diff from theoretic
  df["theoretic"] <- user_seq[sort(c("Equal", "Stoich"), decreasing = !usr$equal)[1]]
  for(x in names(usr$path)[!is.na(usr$path)]) {
    df[paste0("d_", x)] <- df[x]-df$theoretic
  }
  
  # Calc Precision
  for(x in names(usr$path)[!is.na(usr$path)]) {
    df[paste0("prec_", x)] <- 0
    for(y in 1:6) {
      df[y, paste0("prec_", x)] <- (df$theoretic[y]-abs(df[y,paste0("d_", x)]))/df$theoretic[y]
    }
  }
  
  df[,2:ncol(df)] <- df[,2:ncol(df)]*100
  #ymax <- ceiling(max(df[,2:ncol(df)])*1.15)
  #trans_pow10 <- trans_new(name = "pow10",
  #                         transform = function(x) x^(1/3),
  #                         inverse = function(x) x^3)
  
  
  
  for(strat in names(usr$path)[!is.na(usr$path)]) {
    #lbl <- sprintf("%+.2f", df[, paste0("d_",strat)])
    lbl <- sprintf("%+.2f", df[, paste0("d_",strat)])
    lbl_prec <- paste0(round(df[, paste0("prec_",strat)],0),"%")
    lbl_dev <- paste0(round(mean(abs(df[, paste0("d_",strat)])), 2), "% (+/- ", round(sd(abs(df[, paste0("d_",strat)])), 2), "%)")
    lbl_pos <- ifelse(df[, paste0("d_",strat)] < 0, df$pos <- 1, df$pos <- 0 )
    
    
    g <- ggplot(df, aes_(quote(seq), y = as.name(strat), fill = quote(seq))) + #value
      geom_col(width = 0.8) + 
      geom_errorbar(aes_(ymin=quote(theoretic), ymax=as.name(strat)), width=0.15, size=0.5, alpha=1, linetype="solid") +
      geom_col(aes(y = theoretic), fill=NA, color = "black", size = 1, width = 0.8) + 
      geom_label(aes_(label = quote(lbl), y = as.name(strat)), label.size=NA, alpha = 0.5, fill="white", 
                 color = "black", size=2.85, vjust=lbl_pos) +
      scale_x_discrete(limits=df$seq) + 
      scale_fill_brewer(palette="Set1") +
      theme(legend.position = "none",
            panel.grid.minor.x = element_blank(),
            panel.grid.minor.y = element_line(colour="#848484", linetype = 3), #C4C4C4
            panel.grid.major.x = element_blank(),
            panel.grid.major.y = element_line(colour="#848484", linetype = 1),
            panel.background = element_blank(),
            #axis.line.y.left = element_line(colour = "#000000", size = rel(1), linetype = "solid"),
            axis.line = element_line(colour = "#000000", size = 1, linetype = "solid"),
            plot.title = element_blank(), #element_text(hjust = 0.5, size=rel(1), face="bold"),
            #plot.subtitle = element_text(hjust = 0.5, size=12),
            axis.ticks = element_blank(),
            axis.title = element_blank(), #text(size = rel(2)),
            axis.text = element_text(size = 9, face = "bold"),
            plot.margin=grid::unit(c(0,0,0,0), "cm")) #t, r, b, l
    
    if(usr$equal) {
      g <- g +
        scale_y_continuous(limits = c(0, 35), breaks = seq(0,30,10), labels = c(0,10,20,30), expand = c(0,0))
    } else {
      g <- g +
        scale_y_continuous(limits = c(0, 65), breaks = seq(0,60,10), labels = c(0,10,20,30,40,50,60), expand = c(0,0))
    }
    # print(g)
  ann <- ggplot(df, aes_(x = quote(seq), y = as.name(strat), fill = quote(seq))) +
    ggtitle(strat) +
    annotate(geom="label", x = 0, y = 2, size = 2.85, fill="white", color="black", hjust = 0, label.padding=unit(0.2, "lines"),
             label = paste0("Ref-BCs found: 6",
                            "\nSeq. prior: ", usr$nseq[["Raw"]][1], " (+/- ", usr$nseq[["Raw"]][2], ")",
                            "\nSeq. after: ", usr$nseq[[strat]][1], " (+/- ", usr$nseq[[strat]][2], ")")) +
    annotate(geom="label", x = 3, y = 2, size = 2.85, fill="white", color="black", hjust = 0, label.padding=unit(0.2, "lines"),
             label = paste0("Sens.: 100% (=6/6) ",
                            "\nSpec.: ", round((usr$nseq[["Raw"]][1]-usr$nseq[[strat]][1])/usr$nseq[["Raw"]][1]*100,2), "%",
                            " [=(", usr$nseq[["Raw"]][1], "-", usr$nseq[[strat]][1], ")/", usr$nseq[["Raw"]][1],"]",
                            "\nPrec. (mean): ", round(mean(df[, paste0("prec_",strat)]),2), "%")) +
    geom_label(aes_(label = quote(lbl_prec), y = 1), fill=NA, label.size=NA, color = "black", size=3, vjust=0.5) +
    scale_x_discrete(limits=df$seq) +
    scale_y_continuous(limits = c(0.5, 2.75), breaks = seq(0,3,1), labels = c("","Prec.","",""), expand = c(0,0)) +
    theme_void() +
    theme(plot.title = element_blank(), #element_text(hjust = 0.5, size=rel(6), face="bold"),
          axis.text.y = element_text(size = 9, face = "bold"))
    #theme(plot.margin=grid::unit(c(5,0,5,0), "cm"))
  # print(ann)
  
  # ann + g + plot_layout(ncol = 1, nrow = 2, heights = c(1.25, 1))
    
  # usr[["filename"]] <- paste0("Method-Comp_", strat, "_", format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".tiff")
  # ggsave(file=usr$filename, path=file.path(getwd(), "."), height=6, width=10, units="cm", compression="lzw", dpi = 300)
  
  
  
	usr[["filename"]] <- paste0("Method-Comp_", strat, "_", format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".tiff")
	outputDir <- "/JD/docker/export"
	outputFilePath <- file.path(outputDir, usr[["filename"]])

	# Check if the output directory exists; if not, create it
	if (!dir.exists(outputDir)) {
	dir.create(outputDir, recursive = TRUE)
	}

	combined_plot <- ann + g + plot_layout(ncol = 1, nrow = 2, heights = c(1.25, 1))
	tiff(outputFilePath, compression = "lzw", type="cairo", width = 1181, height = 708, units = "px", res = 300)
		print(combined_plot)		
	dev.off()
  
  }
}
