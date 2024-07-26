usr_delimiter <- "de"     # de = german = ;   vs. en = english = ,
outputFileName <- "MST_Stats.csv"
outputDir <- "/JD/docker/export"
outputFilePath <- file.path(outputDir, outputFileName)

##############

# fileLoad <- choose.files(default = "", caption = "Select files", multi = TRUE)

# Docker edit ---
	args <- commandArgs(trailingOnly = TRUE)
	usr_dir <- args[1]

	# List all files in the directory with their full paths
	all_files <- list.files(path = usr_dir, full.names = TRUE)

	# Extract just the filenames from the full paths
	filenames <- basename(all_files)
	
	# Filter files and save either with full path or filename only
	filtered_files <- all_files[grepl("^MST_", filenames)]
	filtered_filenames <- basename(filtered_files)

	# Initialize an empty vector to store the files that meet the criteria
	fileLoad <- c()

	# Loop through each filename
	for (filename in filtered_filenames) {
		fileLoad <- c(fileLoad, filtered_files[filename == filtered_filenames])
	}
# ---------------


dat <- list()

# Read In
for(i in seq(length(fileLoad))) {
  file <- read.table(paste(fileLoad[i]), header=TRUE, stringsAsFactors = FALSE)
  
  for (k in 0:6) { # k = distance to ref
    if(i == 1) {
      dat[k+1] <- list(NULL)
      names(dat)[k+1] <- paste0("dist", k)
    }
  
    if (k == 6) {
      seq_subset <- file[file$DistRef>=k,]
    } else {
      seq_subset <- file[file$DistRef==k,]
    }
    
    ind <- 0
    for (l in 0:5) { # l = deviation
          if(i == 1) {
            dat[[k+1]][ind+1]  <- list(NULL)

            dat[[k+1]][[ind+1]] <- setNames(list(nrow(seq_subset[seq_subset$Distance==l,]),
                                               sum(seq_subset$Reads[seq_subset$Distance==l]),
                                               sum(seq_subset$Reads[seq_subset$Distance==l])/sum(file$Reads)),
                                             c("Seq", "Reads_abs", "Reads_rel"))
            
              names(dat[[k+1]])[ind+1] <- paste0("dev", l)

          } else {
              dat[[k+1]][[ind+1]]$Seq <- append(dat[[k+1]][[ind+1]]$Seq, nrow(seq_subset[seq_subset$Distance==l,]))
              dat[[k+1]][[ind+1]]$Reads_abs <- append(dat[[k+1]][[ind+1]]$Reads_abs, sum(seq_subset$Reads[seq_subset$Distance==l]))
              dat[[k+1]][[ind+1]]$Reads_rel <- append(dat[[k+1]][[ind+1]]$Reads_rel, sum(seq_subset$Reads[seq_subset$Distance==l])/sum(file$Reads))
          }
        
          ind <- ind+1

      #}
    }

  }
}

# print(dat)
  
# Evaluate
df <- data.frame(matrix(NA, 42, 8))
colnames(df) <- c("Dist", "Dev", "Seq_M", "Seq_SD", "R_abs_M", "R_abs_SD", "R_rel_M", "R_rel_SD")
r <- 1
for (k in 0:6) {
  ind <- 0
  for (l in 0:5) {
    df[r,]$Dist <- k  # cave: in case of k = 6: all seq. with dist >5 are summarized
    df[r,]$Dev <- l
    df[r,]$Seq_M <- mean(dat[[k+1]][[ind+1]]$Seq)
    df[r,]$Seq_SD <- sd(dat[[k+1]][[ind+1]]$Seq)
    df[r,]$R_abs_M <- mean(dat[[k+1]][[ind+1]]$Reads_abs)
    df[r,]$R_abs_SD <- sd(dat[[k+1]][[ind+1]]$Reads_abs)
    df[r,]$R_rel_M <- mean(dat[[k+1]][[ind+1]]$Reads_rel)
    df[r,]$R_rel_SD <- sd(dat[[k+1]][[ind+1]]$Reads_rel)
    r <- r+1
    ind <- ind+1
  }
}

# print(df$Seq_M)
# print(sum(df$Seq_M))
  
# df2 <- data.frame(round(df[,1:6], 0), round(df[,7:8], 4))


if(usr_delimiter == "de") {
  write.csv2(df, file=outputFilePath, row.names = F)
  # write.csv2(df2, file="/JD/docker/export/compare.csv", row.names = F)
} else {
  write.csv(df, file=outputFilePath, row.names = F)
}




###

comb.mean <- function(m, n) {
  # m = vector of means
  # n = weight, e.g. population sizes (same length as m)
  x <- 0
  for(i in seq(length(m))) {
    x <- x + m[i]*n[i]
  }
  x <- x/sum(n)
  return(x)
}

comb.sd <- function(m, n, s) {
  # m = vector of means
  # n = weight, e.g. population sizes (same length as m)
  # s = vector of SDs (same length as m)
  #d <- c()
  m_all <- comb.mean(m, n)
  x <- 0
  for(i in seq(length(m))) {
    #d <- append(d, m[i]-m_all)
    x <- x + n[i]*(s[i]^2+(m[i]-m_all)^2)
  }
  x <- sqrt(x/sum(n))
  return(x)
}


###

# df3 <- df2[df2$Seq_M != 0, ]
df3 <- df[df$Seq_M != 0, ]

# stats for combined dist = n

for (n in 3:6) {
#  print(paste0("Dist: ", n, ", Seq_M: ", sum(df3$Seq_M[df3$Dist==n]),
#               ", Seq_SD: ", round(comb.sd(df3$Seq_M[df3$Dist==n], rep(1, nrow(df3[df3$Dist==n,])), df3$Seq_SD[df3$Dist==n]),0),
#               ", R_abs_M: ", sum(df3$R_abs_M[df3$Dist==n]),
#               ", R_abs_SD: ", round(comb.sd(df3$R_abs_M[df3$Dist==n], rep(1, nrow(df3[df3$Dist==n,])), df3$R_abs_SD[df3$Dist==n]),4),
#               ", R_rel: ", sum(df3$R_rel_M[df3$Dist==n]),
#               ", R_rel_SD: ", round(comb.sd(df3$R_rel_M[df3$Dist==n], rep(1, nrow(df3[df3$Dist==n,])), df3$R_rel_SD[df3$Dist==n]),4)))
  
  cat(paste0("\nDist: ", n, "\t", sum(df3$Seq_M[df3$Dist==n]),
               " (", round(comb.sd(df3$Seq_M[df3$Dist==n], rep(1, nrow(df3[df3$Dist==n,])), df3$Seq_SD[df3$Dist==n]),0),
               ")\t", sum(df3$R_abs_M[df3$Dist==n]),
               " (", round(comb.sd(df3$R_abs_M[df3$Dist==n], rep(1, nrow(df3[df3$Dist==n,])), df3$R_abs_SD[df3$Dist==n]),4),
               ")\t", sum(df3$R_rel_M[df3$Dist==n])*100,
               " (", round(comb.sd(df3$R_rel_M[df3$Dist==n], rep(1, nrow(df3[df3$Dist==n,])), df3$R_rel_SD[df3$Dist==n])*100,4), ")"))
}


