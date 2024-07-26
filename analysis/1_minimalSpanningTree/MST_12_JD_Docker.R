# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# + MST  - Version 1.2 - 16. October 2018 - Jannik Daudert - Docker +
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

usrShells <- 5 # How many shells are allowed

# -----------------------------------------------------------
# 0. Functions
# -----------------------------------------------------------
# Function for a good variation of positions in first shell
alternMax <- function(kids) {
  maxKids <- kids
  if (maxKids > 180) maxKids <- 180
  assigned <- c()
  vecFunc <- c(1)
  
  for (i in seq(maxKids)) {
    test <- paste(vecFunc, sep = "", collapse = "*")
    f <- function(x) { eval(parse(text = test)) }
    
    new <- which(f(1:kids) == max(f(1:kids)))
    if(length(new) > 1) new <- new[1]
    assigned <- append(assigned, new)
    vecFunc <- append(vecFunc, paste0("abs(x-assigned[", i, "])"))
  }
  if(kids > 180) assigned <- append(assigned, setdiff(1:kids, assigned))
  return(assigned)
}

# -----------------------------------------------------------
# 1. Load file
# -----------------------------------------------------------
# fileLoad <- choose.files(default = "", caption = "Select files", multi = FALSE)
args <- commandArgs(trailingOnly = TRUE)
fileLoad <- args[1]

file <- read.table(paste(fileLoad), header=TRUE, stringsAsFactors = FALSE)
fileName <- basename(fileLoad)
rm(fileLoad)

# -----------------------------------------------------------
# 2. Setup final data.frame
# -----------------------------------------------------------
file <- file[order(-file$Reads),]
file[c("ID", "Kids", "Closest", "ClosestDist", "Rho","Coords.x",
       "Coords.y")] <- list(1:nrow(file), 0, NA, NA, NA, NA, NA)

# -----------------------------------------------------------
# 3. Determine kids in shells
# -----------------------------------------------------------
if(max(file$DistRef) < usrShells) usrShells <- max(file$DistRef)

# ------------------
# 3.1 Separate outliers
# ------------------
outlier <- file[file$DistRef > usrShells,]
file <- file[!file$ID %in% outlier$ID,]

# ------------------
# 3.2 Kids for Shell 1
# ------------------
file$Closest[file$ID==1] <- 0
file$Kids[file$ID==1] <- nrow(file[file$DistRef==1,])
file$Closest[file$DistRef==1] <- 1
file$ClosestDist[file$DistRef==1] <- 1

# ------------------
# 3.3 Kids for Shell 2-5
# ------------------
for(i in seq(2,nrow(file))) {
  if(i%%(floor(0.01*nrow(file)))==0) { cat(paste0("\rProgress: " , round(i/nrow(file)*100,0)," %")) }
  if(file$DistRef[i] <= 1) next
  
  width <- file$DistRef[i]
  error <- as.vector(t(file[i,5:(4+width)])) # Individual error profile as a vector

  findClosest <- file[file$DistRef < width,] # only in lower shells
  intOverlap <- 0
  idFinal <- NA
  
  for(x in seq(nrow(findClosest))) {
    intTemp <- sum(findClosest[x,5:(4+findClosest$DistRef[x])] %in% error)
    if(intTemp > intOverlap) {
      intOverlap <- intTemp
      idFinal <- findClosest$ID[x]
    }
  }
  if(!is.na(idFinal)) {
    file$Kids[file$ID==idFinal] <- file$Kids[file$ID==idFinal]+1
    file$Closest[file$ID==file$ID[i]] <- idFinal
    file$ClosestDist[file$ID==file$ID[i]] <- width-intOverlap
  }
  
  rm(x, intOverlap, intTemp, findClosest, error, width, idFinal)
}

noClosest <- file[is.na(file$Closest),]

# -----------------------------------------------------------
# 4. Setup angle
# -----------------------------------------------------------

# ------------------
# 4.1 Shell 1
# ------------------
intKids <- file$Kids[file$ID==1]
shell <- file[file$DistRef==1,]

angles <- c()
for(i in seq(0,intKids-1)) {
  angles <- append(angles, i*360/intKids)
}
angles[angles>180] <- (-1)*(angles[angles>180]-180)
angles <- angles[order(abs(angles))]

anglesSet <- alternMax(intKids)

for(i in seq(intKids)) {
  file$Rho[file$ID==shell$ID[i]] <- angles[anglesSet[i]]
}

# ------------------
# 4.2 Without a closest
# ------------------
intKids <- nrow(noClosest)
x <- 0
if(intKids > 0) {
  for(i in seq(1,intKids,by=2)) {
    file$Rho[file$ID==noClosest$ID[i]] <- x*360/intKids
    file$Closest[file$ID==noClosest$ID[i]] <- 1
    file$ClosestDist[file$ID==noClosest$ID[i]] <- noClosest$DistRef[i]
    if(!is.na(noClosest$ID[i+1])) {
      file$Rho[file$ID==noClosest$ID[i+1]] <- 180+x*360/intKids
      file$Closest[file$ID==noClosest$ID[i+1]] <- 1
      file$ClosestDist[file$ID==noClosest$ID[i+1]] <- noClosest$DistRef[i+1]
    }
    x <- x+1
  }
}

# ------------------
# 4.3 Shell 2-5
# ------------------
for(i in seq(usrShells)) {
  shell <- file[file$DistRef==i,]

  for(x in seq(nrow(shell))) {
    intKids <- shell$Kids[x]
    if(intKids>0) {
      seqKids <- file[file$Closest==shell$ID[x],]
      
      anglesTemp <- c()
      for(a in seq(intKids)) {
        if(a>1) {
          anglesTemp <- append(anglesTemp,anglesTemp[a-1]+30/(intKids+1))
        } else {
          anglesTemp <- append(anglesTemp,30/(intKids+1))
        }
      }
      anglesTemp <- file$Rho[file$ID==shell$ID[x]]-15+anglesTemp
      
      for(a in seq(intKids)) {
        file$Rho[file$ID==seqKids$ID[a]] <- anglesTemp[a]
      }
      
    }
  }
}

rm(shell, intKids, seqKids, anglesTemp, a, x, i)
#noRho <- (file[is.na(file$Rho),])

# -----------------------------------------------------------
# 5. Calculation of coordinates
# -----------------------------------------------------------

# ------------------
# 5.1 General
# ------------------
for(i in unique(file$ID)) {
  if(i == 1) {
    file$Coords.x[file$ID==1] <- 0
    file$Coords.y[file$ID==1] <- 0
  } else {
    curRow <- file[file$ID==i,]
    # file$Coords.x[file$ID==i] <- curRow$DistRef*cos(curRow$Rho*(2*pi/360))
    # file$Coords.y[file$ID==i] <- curRow$DistRef*sin(curRow$Rho*(2*pi/360))
    
    intKids <- 0
    if(!is.na(curRow$Closest)) intKids <- file$Kids[file$ID==curRow$Closest]
    if(curRow$DistRef==1) {
      file$Coords.x[file$ID==i] <- jitter(curRow$DistRef*cos(curRow$Rho*(2*pi/360)), factor=(intKids/60)*1.1^2)
      file$Coords.y[file$ID==i] <- jitter(curRow$DistRef*sin(curRow$Rho*(2*pi/360)), factor=(intKids/60)*1.1^2)
    } else {
      file$Coords.x[file$ID==i] <- jitter(curRow$DistRef*cos(curRow$Rho*(2*pi/360)), factor=(intKids/25)*1.1^2)
      file$Coords.y[file$ID==i] <- jitter(curRow$DistRef*sin(curRow$Rho*(2*pi/360)), factor=(intKids/25)*1.1^2)
    }
  }
}
rm(curRow, intKids)
#noCoords <- file[is.na(file$Coords.x),]

pLim <- max(file$Coords.x, file$Coords.y)+0.1*max(file$Coords.x, file$Coords.y)

# ------------------
# 5.2 Outlier
# ------------------

intOutliers <- nrow(outlier)
pps <- intOutliers/4 # points per side
sl <- 2*pLim*0.9 #side length
pd <- sl/pps # point distance

for(i in seq(intOutliers)) {
  if(ceiling(i/pps) == 1) {
    outlier$Coords.x[i] <- -pLim+i*pd
    outlier$Coords.y[i] <- -pLim
  } else if(ceiling(i/pps) == 2) {
    outlier$Coords.x[i] <- -pLim+(i-pps)*pd
    outlier$Coords.y[i] <- pLim
  } else if(ceiling(i/pps) == 3) {
    outlier$Coords.x[i] <- -pLim
    outlier$Coords.y[i] <- -pLim+(i-2*pps)*pd
  } else if(ceiling(i/pps) == 4) {
    outlier$Coords.x[i] <- pLim
    outlier$Coords.y[i] <- -pLim+(i-3*pps)*pd
  } else {
    print("Error in Outlier coord")
  }
}

rm(pps, sl, pd)

# -----------------------------------------------------------
# 6. Setting color and size
# -----------------------------------------------------------

# ------------------
# 6.1 Color
# ------------------
file$Color <- NA

for(i in seq(nrow(file))) {
  if(file$ID[i]==1) {
    file$Color[i] <- "#8f8f8f"
  } else {
    if(all(grepl("sub",file[i,5:(4+file$DistRef[i])]))) {
      file$Color[i] <- "#0000ff"    # sub
    } else if(all(grepl("ins",file[i,5:(4+file$DistRef[i])]))) {
      file$Color[i] <- "#00ff00"    # ins
    } else if(all(grepl("del",file[i,5:(4+file$DistRef[i])]))) {
      file$Color[i] <- "#ff0000"    # del
    } else {
      file$Color[i] <- "#ffff00" # combination
    }
  }
}

# ------------------
# 6.2 Size
# ------------------
nRoot <- 4
file$Size <- file$Reads^(1/nRoot)
outlier$Size <- outlier$Reads^(1/nRoot)

# -----------------------------------------------------------
# 7. Plot and export
# -----------------------------------------------------------

# # ------------------
# # 7.1 RStudio
# # ------------------
# par(pty="s")
# tiff(filename = paste0(substr(fileName,0,nchar(fileName)-4),".tiff"), compression = "lzw", width = 9, height = 9, units = "cm", res = 300)
  # plot(x=0, y=0, col="red", xlim = c(-pLim,pLim), ylim = c(-pLim,pLim), xaxt="n", yaxt="n", ann=FALSE)
  
  # # 7.1.1 Lines
  # for(i in unique(file$ID)) {
    # curRow <- file[file$ID==i,]
    # if((curRow$ID != 1) & (curRow$ClosestDist<=2)) {
      # x1 <- file$Coords.x[file$ID==i]
      # x2 <- file$Coords.x[file$ID==curRow$Closest]
      # y1 <- file$Coords.y[file$ID==i]
      # y2 <- file$Coords.y[file$ID==curRow$Closest]
      
      # if(curRow$ClosestDist==1) {
        # lines(x=c(x1,x2), y=c(y1,y2), col="#878787", lty=1) #floor(3*curRow$ClosestDist/2)
      # } else {
        # lines(x=c(x1,x2), y=c(y1,y2), col="#c3c3c3", lty=3) #floor(3*curRow$ClosestDist/2)
      # }
      
    # }
  # }
  
  # # 7.1.2 Points
  # for(i in rev(unique(file$ID))) {
    # curRow <- file[file$ID==i,]
    # points(x=curRow$Coords.x, y=curRow$Coords.y, pch=21, col="black", bg=curRow$Color, cex=curRow$Size) #bg=vCol[curRow$Distance+1]
  # }
  
  # # 7.1.3 Outliers
  # for(i in seq(intOutliers)) {
    # points(x=outlier$Coords.x[i], y=outlier$Coords.y[i], pch=21, col="black", bg="white", cex=outlier$Size[i])
  # }
  
  # # 7.1.4 Legend
  # # legend(x=0.5*pLim, y=-0.6*pLim, bty="n", pch=21, cex=2,legend=c("Substitution", "Insertion", "Deletion", "Mixed"),
  # #        pt.bg=c("#0000ff","#00ff00", "#ff0000", "#ffff00"),
  # #        text.col=c("#0000ff","#00ff00", "#ff0000", "#ffff00"))
# dev.off()

# ------------------
# 7.2 Export as .png
# ------------------

outputFileName <- paste0(substr(fileName,0,nchar(fileName)-4),".tiff")
outputDir <- "/JD/docker/export"
outputFilePath <- file.path(outputDir, outputFileName)

tiff(outputFilePath, compression = "lzw", type="cairo", width = 3000, height = 3000, units = "px", res = 300)

# tiff(filename = paste0(substr(fileName,0,nchar(fileName)-4),".tiff"), compression = "lzw", width = 3000, height = 3000, units = "px", res = 300) # res = DPI, size = px/dpi
#png(file = paste0(substr(fileName,0,nchar(fileName)-4),".png"), width=800, height=800)
  
  plot(x=0, y=0, col="red", xlim = c(-pLim,pLim), ylim = c(-pLim,pLim), xaxt="n", yaxt="n", ann=FALSE)
  
  # 7.1.1 Lines
  for(i in unique(file$ID)) {
    curRow <- file[file$ID==i,]
    if((curRow$ID != 1) & (curRow$ClosestDist<=2)) {
      x1 <- file$Coords.x[file$ID==i]
      x2 <- file$Coords.x[file$ID==curRow$Closest]
      y1 <- file$Coords.y[file$ID==i]
      y2 <- file$Coords.y[file$ID==curRow$Closest]
      
      if(curRow$ClosestDist==1) {
        lines(x=c(x1,x2), y=c(y1,y2), col="#878787", lty=1) #floor(3*curRow$ClosestDist/2)
      } else {
        lines(x=c(x1,x2), y=c(y1,y2), col="#c3c3c3", lty=3) #floor(3*curRow$ClosestDist/2)
      }
      
    }
  }
  
  # 7.1.2 Points
  for(i in rev(unique(file$ID))) { #rev()
    curRow <- file[file$ID==i,]
    points(x=curRow$Coords.x, y=curRow$Coords.y, pch=21, col="black", bg=curRow$Color, cex=curRow$Size) #bg=vCol[curRow$Distance+1]
  }
  
  # 7.1.3 Outliers
  for(i in seq(intOutliers)) {
    points(x=outlier$Coords.x[i], y=outlier$Coords.y[i], pch=21, col="black", bg="white", cex=outlier$Size[i])
  }
  
  # 7.1.4 Legend
  # legend(x=0.5*pLim, y=-0.6*pLim, bty="n", pch=21, cex=2,legend=c("Substitution", "Insertion", "Deletion", "Mixed"),
  #        pt.bg=c("#0000ff","#00ff00", "#ff0000", "#ffff00"),
  #        text.col=c("#0000ff","#00ff00", "#ff0000", "#ffff00"))

dev.off()
  
