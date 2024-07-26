n <- 200000

########


calc_chap <- function(size, prolif) {
  s <- prolif * size # shared
  u <- (1-prolif) * size / 2 # unique
  m <- s + u # in first and second sample
  
  chap <- (m+1)*(m+1)/(s+1)-1
  return(chap)
}

df <- data.frame(matrix(NA, 100, 2))
colnames(df) <- c("x", "y")
df$x <- seq(100)

for (i in seq(100)) {
  df$y[i] <- calc_chap(n, i/100)
}

# plot(df$x, df$y)

outputFileName <- paste0("poolsize_sim_", format(Sys.time(), "%Y%m%d_%H-%M-%S"), ".csv")
outputDir <- "/JD/docker/export"
outputFilePath <- file.path(outputDir, outputFileName)


write.csv2(df, file=outputFilePath)
