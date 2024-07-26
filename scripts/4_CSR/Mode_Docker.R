fun_mode <- function(x, null.rm) { # Return the mode (most frequent value)
  null.rm <- ifelse(missing(null.rm), FALSE, null.rm)
  if(is.data.frame(x)) x <- unlist(x, use.names = FALSE)
  if(null.rm) x <- x[x>0]
  return(as.integer(names(sort(table(x), decreasing = TRUE))[1]))
}


# csv_files <- choose.files(default = "", caption = "Select csv Overlapping group file BC-Distr", multi = TRUE)

# Docker edit ---
  args <- commandArgs(trailingOnly = TRUE)
  usr_dir <- args[1]
  
	# Convert thresh to an integer
	thresh <- as.integer(args[2])

	# List all files in the directory with their full paths
	all_files <- list.files(path = usr_dir, full.names = TRUE)

	# Extract just the filenames from the full paths
	filenames <- basename(all_files)
	filtered_files <- all_files[grepl("^BC-Distr_Group_", filenames)]
	filtered_filenames <- basename(filtered_files)

	# Initialize an empty vector to store the files that meet the criteria
	csv_files <- character()

	# Loop through each filename
	for (filename in filtered_filenames) {
	  # Split the filename on underscores
	  parts <- strsplit(filename, "_")[[1]]
	  
	  # Extract the group number part and convert it to integer
	  # Assuming the group number is always in the third position (index 3 in R)
	  group_num <- as.integer(parts[3])
	  
	  # Check if the group number is greater than thresh
	  if (!is.na(group_num) && group_num >= thresh) {
		# If it is, find the full path of the file and add it to csv_files
		csv_files <- c(csv_files, filtered_files[filename == filtered_filenames])
	  }
	}

	# print(csv_files)
# ---------------

for (i in seq(length(csv_files))) {
  if (i == 1) {
    df <- read.csv(csv_files[i], header = TRUE, stringsAsFactors = FALSE)
  } else {
    df <- rbind(df, read.csv(csv_files[i], header = TRUE, stringsAsFactors = FALSE))
  }
}

test <- fun_mode(df[,2:ncol(df)], null.rm = TRUE)

print(paste0("Mode: ", test))
