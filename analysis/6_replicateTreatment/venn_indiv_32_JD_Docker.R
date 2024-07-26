##################################
## Venn indiv. v3.2 JD 7/06/2020 #
##################################
if(!exists("usr")) usr <- list() # Don't change
usr[["own"]] <- list()

### 1. User Input
usr[["weight"]] <- "Seq" # "Seq" vs. "Reads"
usr[["print"]] <- "raw" # (only if usr$weight == Seq; if labels printed in "percent" vs. "raw"
usr[["scaled"]] <- FALSE # if weight should be applied (TRUE or FALSE)
usr[["names"]] <- FALSE # if filenames should appear (TRUE or FALSE)
usr[["lwd"]] <- 5 # line width (in px)
usr[["col"]] <- "viridis" # color scheme ("main", "viridis", "mid-red", "mid-blue", Gr-Tc")

usr$own[["use"]] <- FALSE
usr$own[["values"]] <- c("mid" = 0.07,
                         "in_top" = 1.43,
                         "in_left" = 1.37,
                         "in_right" = 1.60,
                         "ou_left" = 28.99,
                         "ou_right" = 34.08,
                         "ou_bottom" = 32.46)

### 2. Color Schemes
# fill order: x (bottom), y (left), z (right), x_y, x_z, y_z, x_y_z
# if 2-circle Venn colors y, z and y_z are taken 
l_cols <- list(
  "main" = list("fill" = c("red", "green", "blue", "yellow", "magenta", "cyan", "white"),
                "text" = c("black", "black", "white", "black", "black", "black", "black")),
  "viridis" = list("fill" = c("#FDE825", "#21968B", "#440C53", "#A17A3C", "#8FBF58", "#33516F", "#D9D9D9"),
                   "text" = c("black", "black", "white", "black", "black", "white", "black")),
  "mid-red" = list("fill" = c("white", "white", "white", "red", "red", "red", "red"),
                   "text" = c("black", "black", "black", "white", "white", "white", "white")),
  "mid-blue" = list("fill" = c("white", "white", "white", "#1E90FF", "#1E90FF", "#1E90FF", "#1E90FF"),
                   "text" = c("black", "black", "black", "white", "white", "white", "white")),
  "Gr-Tc" = list("fill" = c("#33516F", "#76EAEA", "#FF7C7C", "#559EAD", "#996776", "#BBB3B3", "#000000"),
                 "text" = c("white", "black", "black", "black", "black", "black", "white"))
)

### 3. Load Packages
packages <- c("dplyr", "VennDiagram", "polyclip", "purrr")
if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())), dependencies = TRUE)
}
lapply(packages, library, character.only = TRUE)
rm("packages")

### 4. Initiliaze Functions
# getFilePathList <- function(f) {
  # if(!f %in% names(usr) || identical(dirname(usr[[f]]), character(0))) return(file.path(getwd(), "."))
  # file.path(dirname(usr[[f]]), ".")[1]
# }

# determineOrder <- function(files) {
  # if(interactive()) {
    # vecOrder <- rep(NA, length(files))
    # vecRemaining <- seq(length(files))
    
    # for(i in seq(length(files)-1)) {
      # if(i == 1) {
        # if(length(files) == 2) cat("\nWhich File at left position?") else cat("\nWhich File at top left position?")
      # } else {
        # cat("\nWhich File at top right position?")
      # }
      # for(x in seq(length(files))) {
        # cat("\n[", x , "]" , basename(files)[x])
      # }
      # user.input <- readline(prompt=paste0("Enter file number [ ", paste(vecRemaining, collapse=" / "), " ]: "))
      # if(!user.input %in% vecRemaining) stop("Improper number, stopping program...")
      # vecOrder[i] <- as.numeric(user.input)
      # vecRemaining <- vecRemaining[!vecRemaining %in% user.input]
    # }
    # vecOrder[length(files)] <- vecRemaining[!vecRemaining %in% vecOrder]
    # return(files[vecOrder])
  # }
# }

### 5. Main Routine
# Load Files
if(!usr$own$use) {
  # usr_files_tmp <- choose.files(default = getFilePathList("files"), caption = "Select files", multi = TRUE)
  # usr[["files"]] <- determineOrder(usr_files_tmp)
  
  # Docker edit ---
	# Parse command line arguments
	args <- commandArgs(trailingOnly = TRUE)

	# Function to construct file paths and order them based on user input
	orderFiles <- function(directory, fileIdentifiers) {
	  # Construct full paths
	  usr_files_tmp <- file.path(directory, paste0(fileIdentifiers, ".fna"))
	  
	  # Check if files exist
	  if (!all(file.exists(usr_files_tmp))) {
		stop("One or more files do not exist in the specified directory.")
	  }
	  
	  return(usr_files_tmp)
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
	# print(usr[["files"]])

# ---------------
  
}

# Color & Text Adjustment
if(length(usr$files) == 2) {
  l_cols[["text"]] <- l_cols[[usr$col]]$text[c(2, 6, 3)]
  l_cols[["fill"]] <- l_cols[[usr$col]]$fill[c(2, 3, 6)]
} else {
  l_cols[["text"]] <- l_cols[[usr$col]]$text[c(2, 6, 3, 4, 7, 5, 1)] # original text order: y, y_z, z, x_y, x_y_z, x_z, x
  l_cols[["fill"]] <- l_cols[[usr$col]]$fill
}

grid.newpage()
if(exists("overrideTriple")) rm(overrideTriple)
if(usr$scaled == TRUE) overrideTriple=TRUE

if(!usr$own$use) {
  # Output Filename
  fname_mouse <- head(tail(unlist(strsplit(dirname(usr$files[1]), "/")), 2), 1)
  fname_probe <- paste(head(unlist(strsplit(basename(usr$files[1]), "_")),2), collapse = "-")
  fname <- paste(fname_mouse, fname_probe, usr$weight, sep = "_")
  if(usr$scaled == TRUE) fname <- paste(fname, "scaled", sep = "_")
  if(usr$names == TRUE) fname <- paste(fname, "labeled", sep = "_")
  usr[["filename"]] <- paste0(fname, ".tiff")
  rm(fname_mouse, fname_probe, fname)
  
  d <- list()
  for(i in seq(length(usr$files))) {
    d[[letters[23+i]]] <- read.table(usr$files[i], header = TRUE, stringsAsFactors = FALSE)
  }
  usr$files_comb <- combn(seq(length(usr$files)), 2)
  
  for(i in seq(ncol(usr$files_comb))) {
    name_tmp <- paste(letters[23+usr$files_comb[1,i]], letters[23+usr$files_comb[2,i]], sep = "_")
    d_tmp <- merge(d[[letters[23+usr$files_comb[1,i]]]][,1:2], d[[letters[23+usr$files_comb[2,i]]]][,1:2], by="Sequence", all = FALSE)
    colnames(d_tmp)[2:3] <- c(letters[23+usr$files_comb[1,i]], letters[23+usr$files_comb[2,i]])
    d_tmp$add <- 0
    colnames(d_tmp)[4] <- letters[24:26][!letters[24:26] %in% colnames(d_tmp)[2:3]]
    d_tmp$Reads <- apply(d_tmp[, 2:4], 1, sum)
    d[[name_tmp]] <- d_tmp
  }
  
  if(length(usr$files) == 3) {
    name_tmp <- paste(letters[24:26], collapse = "_")
    d_tmp <- merge(d[["x_y"]][,1:3], d[["z"]][,1:2], by="Sequence", all = FALSE)
    colnames(d_tmp)[4] <- "z"
    d_tmp$Reads <- apply(d_tmp[, 2:4], 1, sum)
    d[[name_tmp]] <- d_tmp
  }
  rm(name_tmp, d_tmp, i)
  
  d_unique <- list()
  for(i in seq(length(d))) {
    if(nchar(names(d)[i]) == 1) { #x, y (, z)
      d_excl <- names(d)[nchar(names(d))>1]
      d_tmp <- d[[names(d)[i]]]
      for(k in d_excl) {
        d_tmp <- d_tmp %>% anti_join(d[[k]], by="Sequence")
      }
      d_unique[[names(d)[i]]] <- d_tmp
    } else if(nchar(names(d)[i]) == 3) {  #x_y (, x_z, y_z) #&& length(usr$files) == 3
      d_excl <- names(d)[nchar(names(d))>3]
      d_tmp <- d[[names(d)[i]]]
      for(k in d_excl) {
        d_tmp <- d_tmp %>% anti_join(d[[k]], by="Sequence")
      }
      d_unique[[names(d)[i]]] <- d_tmp
    } else {
      next
    }
  }
  rm(d_excl, d_tmp, i, k)
  reads_total <- sum(d$x$Reads, d$y$Reads, d$z$Reads)
  
  n_reads <- c()
  for(i in names(d)) {
    if(i == "x_y_z") {
      n_reads <- append(n_reads, round(sum(d[[i]]$Reads)/reads_total, 4))
    } else {
      n_reads <- append(n_reads, round(sum(d_unique[[i]]$Reads)/reads_total, 4))
    }
  }
  n_reads <- n_reads*100
  
  if(length(usr$files) == 2) {
    if(usr$weight == "Seq") { # inverted statement necessary, as draw.pairwise.venn function default places larger set on the left 
      vp <- draw.pairwise.venn(area1 = nrow(d$x), area2 = nrow(d$y), cross.area = nrow(d$x_y), 
                               scaled = usr$scaled, category = basename(usr$files), inverted = !nrow(d$x)>nrow(d$y))
    } else {
      vp <- draw.pairwise.venn(area1 = n_reads[1]+n_reads[3], area2 = n_reads[2]+n_reads[3], cross.area = n_reads[3], 
                               scaled = usr$scaled, category = basename(usr$files), 
                               inverted = !(n_reads[1]+n_reads[3])>(n_reads[2]+n_reads[3]))
    }
  } else {
    # Venn for Number of Sequences, not scaled
    if(usr$weight == "Seq") {
      vp <- draw.triple.venn(area1 = nrow(d$x), area2 = nrow(d$y), area3 = nrow(d$z), 
                             n12 = nrow(d$x_y), 
                             n13 = nrow(d$x_z), 
                             n23 = nrow(d$y_z),
                             n123 = nrow(d$x_y_z), print.mode = usr$print,
                             alpha = c(0.9, 0.9, 0.9),
                             category = basename(usr$files),
                             col = "black",
                             scaled = usr$scaled)
    } else {
      vp <- draw.triple.venn(area1 = round(sum(n_reads[c(1,4,5,7)]), 2), # ou_left + in_top + in_left + mid
                             area2 = round(sum(n_reads[c(2,4,6,7)]), 2), # ou_right + in_top + in_right + mid
                             area3 = round(sum(n_reads[c(3,5,6,7)]), 2), # ou_bottom + in_left + in_right + mid
                             n12 = n_reads[4] + n_reads[7], # in_top + mid
                             n13 = n_reads[5] + n_reads[7], # in_left + mid
                             n23 = n_reads[6] + n_reads[7], # in_right + mid
                             n123 = n_reads[7], print.mode = "raw",
                             alpha = c(0.9, 0.9, 0.9),
                             category = basename(usr$files),
                             col = "black",
                             scaled = usr$scaled,
                             ind = FALSE)
    }
  }
} else { 
  usr[["filename"]] <- paste0("Venn_",format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".tiff")
  vp <- draw.triple.venn(area1 = round(sum(usr$own$values[c("ou_left", "in_top", "in_left", "mid")]), 2), 
                         area2 = round(sum(usr$own$values[c("ou_right", "in_top", "in_right", "mid")]), 2), 
                         area3 = round(sum(usr$own$values[c("ou_bottom", "in_left", "in_right", "mid")]), 2), 
                         n12 = round(sum(usr$own$values[c("in_top", "mid")]), 2), 
                         n13 = round(sum(usr$own$values[c("in_left", "mid")]), 2), 
                         n23 = round(sum(usr$own$values[c("in_right", "mid")]), 2), 
                         n123 = usr$own$values["mid"], print.mode = "raw",
                         alpha = c(0.9, 0.9, 0.9),
                         col = "black",
                         scaled = usr$scaled,
                         ind = FALSE)
  d <- list("x"=0, "y"=0, "z"=0, "x_y"=0, "x_z"=0, "y_z"=0, "x_y_z"=0)
}

vp_new <- list()
for(i in seq(length(names(d)))) {
  if(nchar(names(d)[i]) == 1) { #x, y (, z)
    vp_new[[names(d)[i]]] <- list(list(x = as.vector(vp[[2+i]][[1]]), y = as.vector(vp[[2+i]][[2]])))
  } else if(nchar(names(d)[i]) == 3) {  #x_y (, x_z, y_z))
    vp_tmp <- strsplit(names(d)[i], "_")[[1]]
    vp_new[[names(d)[i]]] <- polyclip(vp_new[[vp_tmp[1]]], vp_new[[vp_tmp[2]]])
    rm(vp_tmp)
  } else {
    vp_new[[names(d)[i]]] <- polyclip(vp_new[["x_y"]], vp_new[["z"]])
  }
}
rm(i)

ix <- sapply(vp, function(x) grepl("text", x$name, fixed = TRUE))
labs <- do.call(rbind.data.frame, lapply(vp[ix], `[`, c("x", "y", "label")))

outputDir <- "/JD/docker/export"
outputFilePath <- file.path(outputDir, usr$filename)


# tiff(usr$filename, units="px", width=3000, height=3000, res=300, compression = "lzw")
tiff(outputFilePath, compression = "lzw", type="cairo", width = 3000, height = 3000, units = "px", res = 300)
  par(oma=c(0,0,0,0), mar=c(0,0,0,0))
  if(usr$names == TRUE && usr$own$use == FALSE) {
    cat_lim <- max(sapply(basename(usr$files), nchar))*0.02
  } else {
    cat_lim <- 0
  }
  plot(c(0-cat_lim, 1+cat_lim), c(0-cat_lim, 1+cat_lim), mar = 0, type = "n", axes = FALSE, xlab = "", ylab = "")
  for(i in seq(length(vp_new))) {
    if(length(vp_new[[names(vp_new)[i]]]) != 0) polygon(vp_new[[names(vp_new)[i]]][[1]], lwd=usr$lwd, col = l_cols$fill[i])
  }

  if(usr$own$use == TRUE) {
    # text(x = labs$x[1:7], y = labs$y[1:7], labels = paste0(labs$label, "%")[1:7], font = 2, cex=2.5, col = l_cols$text)
	text(x = labs$x[1:7], y = labs$y[1:7], labels = paste0(labs$label, "%")[1:7], font = 2, cex=2.5, col = l_cols$text)
  } else {
    l_tmp <- length(labs$label)-length(usr$files)
    if(usr$print == "percent") {
      usr_labs <- head(labs$label, l_tmp)
    } else {
      usr_labs <- round(as.numeric(as.character(head(labs$label, l_tmp))), 2)
    }
    usr_cats <- droplevels(tail(labs$label, length(usr$files)))
    usr_labs2 <- usr_labs
    
    if(usr$names == TRUE) t_size <- 3*cat_lim else t_size <- 2.5
    
    if(usr$weight == "Seq") {
      text(x = head(labs$x, l_tmp), y = head(labs$y, l_tmp), labels = usr_labs, font = 2, cex=t_size, col = l_cols$text)
    } else {
      usr_labs <- paste0(usr_labs, "%")
      if(any(usr_labs2 >75, na.rm = TRUE) && usr$scaled == TRUE) {
        # x-y correction, B, B_C, C, A_B, intAll, A_C, A
        if(length(usr$files) == 2) {
          labs_x <- sapply(list(vp_new$y[[1]]$x, vp_new$x_y[[1]]$x, vp_new$x[[1]]$x), mean)
          labs_y <- sapply(list(vp_new$y[[1]]$y, vp_new$x_y[[1]]$y, vp_new$x[[1]]$y), mean)
        } else {
          labs_x <- sapply(list(vp_new$y[[1]]$x, vp_new$y_z[[1]]$x, vp_new$z[[1]]$x, vp_new$x_y[[1]]$x, vp_new$x_y_z[[1]]$x, vp_new$x_z[[1]]$x, vp_new$x[[1]]$x), mean)
          labs_y <- sapply(list(vp_new$y[[1]]$y, vp_new$y_z[[1]]$y, vp_new$z[[1]]$y, vp_new$x_y[[1]]$y, vp_new$x_y_z[[1]]$y, vp_new$x_z[[1]]$y, vp_new$x[[1]]$y), mean)
        }
        usr_labs_id <- which(usr_labs2 > 75)
        text(x = labs_x[usr_labs_id], y = labs_y[usr_labs_id], labels = usr_labs[usr_labs_id], font = 2, cex=t_size)
      } else {
        text(x = head(labs$x, l_tmp), y = head(labs$y, l_tmp), labels = usr_labs, font = 2, cex=t_size, col = l_cols$text)
      }
    }
    if(usr$names == TRUE) {
      cat_pos_x <- tail(labs$x, length(usr$files))
      cat_pos_y <- tail(labs$y, length(usr$files))
      
      for(i in seq(length(usr$files))) {
        text(x = cat_pos_x[i], y = cat_pos_y[i], labels = usr_cats[i], font = 2, cex=2.5*cat_lim, col = "black", pos = c(2, 4, 1)[i], offset = 0.5)
      }
    }
  }
dev.off()
