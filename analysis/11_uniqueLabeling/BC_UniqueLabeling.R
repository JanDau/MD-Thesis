args <- commandArgs(trailingOnly = TRUE)
librarySize <- args[1]
cells <- args[2]

n <- as.integer(librarySize)
k <- as.integer(cells)

res <- 1-pbinom(1, k, 1/n)

cat(paste0(
	"\n--------\nLibrary size: ", librarySize, ", Number of cells: ", cells,"\n",
	"Ratio librarySize : cells = ", n/n, " : ", n/k, 
	"\nRisk of having two cells labeled with the same barcode: ", round(res*100, 5), "%\n--------\n\n"
))