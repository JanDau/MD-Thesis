##############################################################################
#     Clonal Development - Version 8.5 - 26th Nov 2020 - Jannik Daudert      #
##############################################################################
if(!exists("usr")) { # Don't change
  usr <- list()
  usr[["colors"]] <- list()
}

# -----------------------
# 0 | User Defined Values
# -----------------------
  usr[["thresh"]] <- 0.01 # Sequences below given percentage (as decimal) are summarized as 'Others' (grey bar at top) 
  usr[["thresh.label"]] <- 0.1 # Seq. higher than given perc. (as decimal) receive a label in the plot
  usr[["minimalistic"]] <- FALSE # TRUE = only stacked bars, FALSE = labels for Axis, Percentages, Seq & Read Count
  usr[["scale"]] <- 0.25 # y-scale for plot (as decimal)
  usr[["order"]] <- "overall" # sequence stack order based on "first", "last", "overall"
  usr[["bar.width"]] <- 0.75 # width of columns, values between 0.00 and 1.00
  usr[["width"]] <- 1771 # width of plot in cm, set NA for automatic
  usr[["height"]] <- 826 # height of plot in cm, set NA for automatic
  usr[["areas"]] <- FALSE # if areas between stacks should be drawn
  usr[["area.last"]] <- FALSE # set TRUE if last bar should be connected with an area, too
  usr[["areas.alpha"]] <- 0.5 # transparency of connecting areas (between 0 and 1)
  usr$colors[["use.previous"]] <- FALSE # if you run the code for the same animal with different samples (TRUE or FALSE)
  usr$colors[["set"]] <- "viridis" # possible sets: rainbow, viridis, magma, plasma, inferno
  
  # Further options if minimalistic == FALSE
  usr[["title"]] <- NA # title for plot, set NA (without quotes) to hide
  usr[["title.x"]] <- NA # x axis title, set NA (without quotes) to hide
  usr[["angle.x"]] <- 0 # angle of x axis labels
  usr$colors[["text"]] <- "white" # label color
  usr[["lab.size"]] <- 4.5 # size of label indicating % of sequence
  
###############################################################################
######################## DO NOT CHANGE BELOW THIS LINE ########################
###############################################################################

# -----------------------
# 1 | Loading Library
# -----------------------
  # ggplot2: graphical output, plyr: ddply() function, reshape2: melt() function, scales: percentage axis in graph
  packages <- c("ggplot2", "plyr", "reshape2", "scales", "viridis", "rlang")
  if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
    install.packages(setdiff(packages, rownames(installed.packages())), dependencies = c("Depends"))
  }
  lapply(packages, library, character.only = TRUE)
  rm(packages)
  
# -----------------------
# 2 | Functions
# # -----------------------
  # determineOrder <- function(files) {
    # if(interactive()) {
      # if(length(files) == 1) return(files)
      # vecOrder <- rep("", length(files))
      # vecOrder <- as.integer(vecOrder)
      # vecRemaining <- seq(length(files))
      # filesOrdered <- rep("", length(files))
      
      # for(i in seq(length(files))) {
        # strRemaining <- paste0(vecRemaining, collapse="/")
        # for(x in seq(length(files))) {
          # cat("\n" , basename(files)[x] , "[" , vecOrder[x] , "]")
        # }
        
        # user.input <- readline(prompt=paste0("Position of " , basename(files)[i] , " [" , strRemaining , "]: "))
        # if(!user.input %in% vecRemaining) {
          # message("Improper number, use one of the numbers inside [...]")
          # user.input <- readline(prompt=paste0("Position of " , basename(files)[i] , " [" , strRemaining , "]: "))
          # if(!user.input %in% vecRemaining) {
            # stop("Improper number, stopping program...")
          # }
        # }
        # user.input <- as.numeric(user.input)
        # vecOrder[i] <- user.input
        # vecRemaining <- vecRemaining[!vecRemaining %in% user.input]
        # filesOrdered[user.input] <- files[i]
      # }
      # return(filesOrdered)
    # }
  # }
  
  # getFilePathList <- function(f) {
    # if(!f %in% names(usr) || identical(dirname(usr[[f]]), character(0))) return(file.path(getwd(), "."))
    # file.path(dirname(usr[[f]]), ".")[1]
  # }
  
# -----------------------
# 3 | Initiation
# -----------------------
  # Fileload with multiple Selection
  # files_temp <- choose.files(default = getFilePathList("files"), caption = "Select files", multi = TRUE)

	# Docker edit ---
	# Parse command line arguments
	args <- commandArgs(trailingOnly = TRUE)

	# Function to construct file paths and order them based on user input
	orderFiles <- function(directory, fileIdentifiers) {
	  # Construct full paths
	  filePaths <- file.path(directory, paste0(fileIdentifiers, ".fna"))
	  
	  # Check if files exist
	  if (!all(file.exists(filePaths))) {
		stop("One or more files do not exist in the specified directory.")
	  }
	  
	  return(filePaths)
	}

	# Check if sufficient arguments are provided
	if (length(args) < 2) {
	  stop("Please provide the directory followed by at least one file identifier.")
	}

	# Extract the directory and file identifiers from the arguments
	directory <- args[1]
	fileIdentifiers <- args[-1]  # All arguments except the first

	# Order the files based on the input
	usr[["files"]] <- orderFiles(directory, fileIdentifiers)
	print(usr[["files"]])

	usr[["savedir"]] <- "/JD/docker/export"
# ---------------

  # Directory will be saved and not asked twice, if running a 2nd time
  # if("savedir" %in% names(usr) == FALSE) usr[["savedir"]] <- choose.dir(default = file.path(getwd(), "."), caption = "Choose directory where to save plots")
  
  # Files are ordered user-defined
  # usr[["files"]] <- determineOrder(files_temp)
  # rm(files_temp)
  usr[["filenames"]] <- substr(basename(usr$files), 1, nchar(basename(usr$files))-4)
  
  # Setup variables
  vec.Empty <- c()
  #df.Seq <- data.frame(Seq=character(), Freq=integer(), stringsAsFactors = FALSE)
  df.Seq <- data.frame(Sequence=character(), stringsAsFactors = FALSE)
  df.Seq.Info <- data.frame(variable=character(), data=character(), value=character(), pos=double(), stringsAsFactors = FALSE)
  
# -----------------------
# 4 | Importing file data
# -----------------------
  # Load every file successive in a loop
  for(i in seq(length(usr$files))) {
    File <- read.table(paste(usr$files[i]), header=TRUE, stringsAsFactors = FALSE)[,1:2] # Only keep Sequence and Read column (if there is a distance column)
    
  # Save read count and number of sequences for labels
    df.Seq.Info <- rbind(df.Seq.Info, data.frame(variable=usr$filenames[i], 
                                                 data=c("Sequences", "Reads"), value=c(nrow(File), sum(File$Reads)), pos=c(1.15, 1.08))) #1.12, 1.05
    
    # Save name if it's only a dummy file
    if(nrow(File)==0) {
      vec.Empty <- append(vec.Empty, usr$filenames[i])
      if(nrow(df.Seq) == 0) {
        df.Seq <- rbind(df.Seq, data.frame(Sequence="SPACER", Reads=NA))
      } else {
        df.Seq <- cbind(df.Seq, NA)
      }
      colnames(df.Seq)[ncol(df.Seq)] <- usr$filenames[i]
      next
    }
    
  # Calculate and write the frequency of each sequence
    File$Reads <- round(File$Reads/sum(File$Reads),5)
    
  # Merge with already loaded files
    if(nrow(df.Seq) == 0) { 
      df.Seq <- rbind(df.Seq, File)
    } else {
      df.Seq <- merge(df.Seq, File, all = TRUE, by = "Sequence")
    } 
    colnames(df.Seq)[ncol(df.Seq)] <- usr$filenames[i]
  }
  rm(i, File)
  if(nrow(df.Seq[df.Seq$Sequence=="SPACER", ]) > 0) df.Seq <- df.Seq[-c(which(df.Seq$Sequence=="SPACER")),]
  
  # Replace sequences by numbers as integers; in df.Seq.Lib each sequence is linked with the corresponding id
  df.Seq$Seq.ID <- seq(nrow(df.Seq))
  df.Seq.Lib <- data.frame(Seq.ID=df.Seq$Seq.ID, Sequence=df.Seq$Sequence)
  
  # Delete "Sequence" column and reorder df.Seq
  df.Seq <- df.Seq[,-1]
  df.Seq <- df.Seq[, c(ncol(df.Seq), 1:(ncol(df.Seq)-1))]
  df.Seq[is.na(df.Seq)] <- 0
  
  # drop dumb sequences
  if(length(usr$files) > 1) {
    #df.Seq <- df.Seq[apply(df.Seq[, -1], MARGIN = 1, function(x) any(x[!is.na(x)] >= usr$thresh)), ]
    df.Seq <- df.Seq[apply(df.Seq[, -1], MARGIN = 1, function(x) any(x >= usr$thresh)), ]
  } else {
    df.Seq <- df.Seq[df.Seq[-1] >= usr$thresh,]
  }
  
  # Calculation of dumb percentage
  df.Seq["Others",] <- c(max(df.Seq.Lib$Seq.ID)+1, 1-(apply(df.Seq, 2, sum)[2:ncol(df.Seq)]))
  
# -----------------------
# 5 | Transforming Table
# -----------------------
  # Transform table from wide format to long format in order to run ggplot later
  df.Seq <- melt(df.Seq, id=c("Seq.ID"))
  #df.Seq$value[is.na(df.Seq$value)] <- 0

# -----------------------
# 6 | Create Labels
# -----------------------
  # Percentage labels for columns
  #df.Seq$lbl <- paste0(sprintf("%.1f", round(df.Seq$value*100,1)),"%") # Set lbl column
  df.Seq$lbl <- paste0(round(df.Seq$value*100,0),"%") # Set lbl column
  df.Seq$lbl[df.Seq$value < usr$thresh.label] <- "" # Remove lbl if < usr$thresh.label
  df.Seq$lbl[df.Seq$Seq.ID == max(df.Seq$Seq.ID)] <- "Others" # Indicate "Others"
    
# -----------------------
# 7 | Adjust order of sequences
# -----------------------
  # ggplot orders the stacked bar plot by the aes attribute "fill" according the order they appear in the dataframe
  df.Seq <- arrange(df.Seq, variable, value)
  
  # Set stack order
  if(usr$order == "last") {
    #vec_iter <- unique(df.Seq$Seq.ID[df.Seq$variable==basename(usr$files[length(usr$files)])])
    vec_iter <- unique(df.Seq$Seq.ID[df.Seq$variable==usr$filenames[length(usr$files)]])
  } else if (usr$order == "overall") {
    vec_iter <- c()
    for(i in unique(df.Seq$Seq.ID)) {
      vec_iter <- append(vec_iter, sum(df.Seq$value[df.Seq$Seq.ID==i]))
      names(vec_iter)[which(unique(df.Seq$Seq.ID) %in% i)] <- i
    }
    vec_iter <- as.numeric(names(vec_iter[order(vec_iter)]))
  } else { # take first
    vec_iter <- unique(df.Seq$Seq.ID)
  }
  
  df.Seq$pos <- 0 # Create "pos" column for correct order
  for(i in vec_iter) {
    df.Seq$pos[df.Seq$Seq.ID == i & df.Seq$lbl != "Others"] <- which(vec_iter == i)
  }
  df.Seq <- arrange(df.Seq, variable, -pos)
  rm(vec_iter, i)
  
# -----------------------
# 8 | Modifying graph
# -----------------------
  # Get amount of colors needed, first 15 colors always same
  usr$colors[["count"]] <- length(unique(df.Seq$Seq.ID)) #c(1, 11, 4, 8, 12, 3, 7, 14, 5, 15, 10, 6, 2, 13, 9)
  #if(usr$colors$use.previous) usr$colors[["count"]] <- nrow(df.Col.Save)+1
  if(usr$colors$count <= 15) {
    usr$colors[["palette"]] <- do.call(usr$colors$set, list(15))[c(1, 11, 4, 8, 12, 3, 7, 14, 5, 15, 10, 6, 2, 13, 9)]
    usr$colors[["palette"]] <- head(usr$colors$palette, -1)
  } else {
    usr$colors[["palette"]] <- do.call(usr$colors$set, list(usr$colors$count))[c(1, 11, 4, 8, 12, 3, 7, 14, 5, 15, 10, 6, 2, 13, 9)/15*(usr$colors$count)]
    pal_add <- sample(do.call(usr$colors$set, list(usr$colors$count)))
    usr$colors[["palette"]] <- c(usr$colors$palette, head(pal_add[!pal_add %in% usr$colors$palette], -1))
    rm(pal_add)
  }
  
  if(usr$colors$use.previous) {
    if(!exists("df.Col.Save")) {
      warning("Non previous colors applied as df.Col.Save is missing in Global Environment.")
    } else {
      df.Temp <- df.Seq.Lib[head(unique(df.Seq$Seq.ID), -1), ]
      df.Temp <- merge(df.Temp, df.Col.Save, by = "Sequence", all.x = TRUE)
      for(i in unique(df.Temp$Seq.ID)) {
        usr$colors$palette[which(unique(df.Seq$pos) %in% unique(df.Seq$pos[df.Seq$Seq.ID==i]))] <- as.character(df.Temp$Color[df.Temp$Seq.ID==i])
      }
      n <- length(usr$colors$palette[is.na(usr$colors$palette)])
      m <- 0.15*n*n
      if(usr$colors$set == "inferno") {
        usr$colors$palette[is.na(usr$colors$palette)] <- rev(viridis(n*n))[seq(m, (n*n)-m, ((n*n-m)-m)/n)]
      } else {
        usr$colors$palette[is.na(usr$colors$palette)] <- rev(inferno(n*n))[seq(m, (n*n)-m, ((n*n-m)-m)/n)]
      }
      rm(df.Temp, i, col_tmp, n, m)
    }
  }

  # Save colors
  if(!exists("df.Col.Save")) {
    df.Col.Save <- data.frame("Sequence" = factor(), "Color"=factor())
    pos_temp <- head(unique(df.Seq$pos),-1)
    for(i in pos_temp) {
      df.Col.Save <- rbind(df.Col.Save, data.frame(Sequence = df.Seq.Lib$Sequence[df.Seq.Lib$Seq.ID == unique(df.Seq$Seq.ID[df.Seq$pos==i])], Color = usr$colors$palette[which(pos_temp %in% i)]))
    }
    rm(pos_temp, i)
  }
  
  # x Axis labels
  vec.x.labels <- unique(df.Seq$variable)

  # Set title
  str.Title.Temp <- strsplit(dirname(usr$files[1]), "/")[[1]]
  if(usr$minimalistic) usr$title <- str.Title.Temp[length(str.Title.Temp)-2]
  rm(str.Title.Temp)
  
  # Deleting bars and areas for empty time points
  if(length(vec.Empty) > 0) {
    for(i in vec.Empty) {
      df.Seq$value[df.Seq$variable==i] <- 0
    }
  }
  
  # Creating area fills
  df.Seq$absval <- ddply(df.Seq, .(variable), transform, absval = cumsum(value))$absval
  df.Seq$diff <- df.Seq$absval-df.Seq$value # y values of area
  
  #vec_iter <- seq(length(usr$files))[!basename(usr$files) %in% vec.Empty]
  vec_iter <- seq(length(usr$files))[!usr$filenames %in% vec.Empty]
  x <- 1
  if(length(usr$files) != 1 & usr$areas == TRUE) {
    for(i in vec_iter[1:length(vec_iter)-1]) {
      # df.Seq[df.Seq$variable == unique(df.Seq$variable)[vec_iter[i]],]   => sub-df containing one time point
      #if(sum(df.Seq[df.Seq$variable == unique(df.Seq$variable)[vec_iter[i]],]$value) != 0) { # if no space holder
      if(sum(df.Seq[df.Seq$variable == unique(df.Seq$variable)[i],]$value) != 0) { # if no space holder
      #if(sum(df.Seq[df.Seq$variable == usr$filenames[i],]$value) != 0) { # if no space holder
        area_tmp <- paste0("area", x)
        df.Seq[[area_tmp]] <- NA
    
        # x1 (start of area)
        #df.Seq[ (df.Seq$variable == unique(df.Seq$variable)[vec_iter[i]]) & (df.Seq$value != 0) & (df.Seq$lbl != "Others"), area_tmp] <- vec_iter[i] + usr$bar.width/2
        df.Seq[ (df.Seq$variable == unique(df.Seq$variable)[i]) & (df.Seq$value != 0) & (df.Seq$lbl != "Others"), area_tmp] <- i + usr$bar.width/2
        #df.Seq[ (df.Seq$variable == usr$filenames[i]) & (df.Seq$value != 0) & (df.Seq$lbl != "Others"), area_tmp] <- vec_iter[i] + usr$bar.width/2
        # x2 (end of area)
        #df.Seq[ (df.Seq$variable == unique(df.Seq$variable)[vec_iter[i+1]]) & (df.Seq$value != 0) & (df.Seq$lbl != "Others"), area_tmp] <- vec_iter[i+1] - usr$bar.width/2
        df.Seq[ (df.Seq$variable == unique(df.Seq$variable)[i+1]) & (df.Seq$value != 0) & (df.Seq$lbl != "Others"), area_tmp] <- i+1 - usr$bar.width/2
        #df.Seq[ (df.Seq$variable == usr$filenames[i+1]) & (df.Seq$value != 0) & (df.Seq$lbl != "Others"), area_tmp] <- vec_iter[i+1] - usr$bar.width/2
        x <- x+1
      }
    }
    rm(area_tmp, i, vec_iter)
  }
  
  # Delete "Others" label
  df.Seq$lbl[df.Seq$lbl=="Others"] <- ""
  rm(x)
  
# -----------------------
# 9 | Plot the graph          #606060 = gray, #000000 = black
# ----------------------- 
  # Create plot using ggplot with geom_bar, geom_area and geom_text
  g <- ggplot(data=df.Seq, aes(x=variable, y=value, label=lbl))
  
  # Add areas (connecting background)
  if(length(usr$files) != 1 & usr$areas == TRUE) {
    x <- 0
    for(i in (8:ncol(df.Seq))) {
      if(i == ncol(df.Seq) & usr$area.last == FALSE) next
      x <- x+1
      g <- g + geom_ribbon(data=df.Seq, color="#000000", alpha=usr$areas.alpha, size=0.1, na.rm=FALSE, mapping=aes_q(x=as.name(paste0("area",x)), ymin=quote(diff), ymax=quote(absval), fill=quote(factor(pos))))
    }
  }

  # Add labels for missing data time points
   #vec.Iter <- seq(usr$files)[basename(usr$files) %in% vec.Empty]
  vec.Iter <- seq(usr$files)[usr$filenames %in% vec.Empty]
   if(length(vec.Iter) > 0) g <- g + annotate(geom="text", size=rel(5), angle=90, y=0.5, x=vec.Iter, label="italic('No data available')", parse=TRUE)
  
  # Add bars and all the rest
  g <- g + 
    geom_bar(stat="identity", colour="black", width=usr$bar.width, aes(fill=factor(pos))) +
    scale_fill_manual(values = c("#606060", rev(usr$colors$palette))) +
    theme(legend.position = "none",
          panel.grid.minor = element_blank(),
          panel.grid.major.x = element_blank(),
          panel.grid.major.y = element_line(colour="#848484"),
          panel.background = element_blank(),
          axis.line = element_line(colour = "#000000", size = 1, linetype = "solid"),
          plot.title = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_text(face="bold", color="black", size = 12, angle=0)) + # size = 12 for 3
    scale_x_discrete(breaks=unique(df.Seq$variable), labels=vec.x.labels)
    
  # Add additional information if usr$minimalistic == FALSE
  if(usr$minimalistic == FALSE) {
    g <- g + 
      geom_text(size = rel(usr$lab.size), fontface="plain", position = position_stack(vjust = 0.5), color = usr$colors$text) + # Label
      geom_text(data=df.Seq.Info, size = rel(3.5), aes(x=variable, y=pos, label=value)) + # Seq & Read Count
      scale_y_continuous(expand=c(0, 0), limits=c(0, 1.18), breaks=seq(0, 1, usr$scale), labels = percent) +
      theme(plot.title = element_text(hjust = 0.5, size=14, face="bold"),
            axis.text = element_text(face="bold", color="black", size=rel(1)),
            axis.text.x = element_text(angle=0, vjust = 0.5 , hjust = 0.5),
            axis.title.x = element_blank(),
            plot.margin = margin(0.5, 0.5, 0.5, 0.5, "cm"))
    #if(!is.na(usr$title)) g <- g + ggtitle(usr$title)
    #if(!is.na(usr$title.x)) g <- g + xlab(usr$title.x) + theme(axis.title.x = element_text(color="black", size=rel(1), face="bold"))
    if(usr$angle != 0) g <- g + theme(axis.text.x = element_text(angle=usr$angle, vjust = 1, hjust = 1))
  } else {
    g <- g + 
      scale_y_continuous(expand=c(0, 0), limits=c(0, 1), breaks=seq(0, 1, usr$scale), labels = percent) +
      theme(plot.margin = margin(0.5, 0.5, 0.5, 0.5, "cm"))
  }
  
# -----------------------
# 10 | Print & Export
# -----------------------
  # Print in RStudio
  # print(g)
  
  if(is.na(usr$title)) {
    fname <- paste0("ClonalDev_",format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".tiff") 
  } else {
    fname <- paste0(usr$title , ".tiff")
  } 
  # Export: Name of the figure will be the parent folder name, saved as tiff
  # ggsave(file=fname, path=usr$savedir, height=usr$height, width=usr$width, units="cm", compression="lzw", dpi = 300)
  
  outputFilePath <- file.path(usr$savedir, fname)

# Check if the output directory exists; if not, create it
if (!dir.exists(usr$savedir)) {
dir.create(usr$savedir, recursive = TRUE)
}

tiff(outputFilePath, compression = "lzw", type="cairo", width = usr$width, height = usr$height, units = "px", res = 300)
	print(g)
dev.off()
 
 
### Docker addition statistics
filtered_df <- df.Seq[df.Seq$value >= 0.05 & df.Seq$pos != 0, ]
my.id <- unique(filtered_df$Seq.ID)
df.my <- df.Seq.Lib[my.id,]

for (col_name in usr$filenames) {
  df.my[[col_name]] <- NA
}

names(df.my)[1] <- "ID"
rownames(df.my) <- NULL

for(i in seq(length(usr$files))) {
  File <- read.table(paste(usr$files[i]), header=TRUE, stringsAsFactors = FALSE)[,1:2] # Only keep Sequence and Read column (if there is a distance column)
  
  for(x in seq(length(my.id))) {
    df.my[x, usr$filenames[i]] <- ifelse(length(File$Reads[File$Sequence == df.my$Sequence[x]]) == 0, 0, File$Reads[File$Sequence == df.my$Sequence[x]])
  }
  
}

outputFileName <- paste0(fname,".csv")
outputDir <- "/JD/docker/export"
outputFilePath <- file.path(outputDir, outputFileName)

write.csv2(df.my, file=outputFilePath)
