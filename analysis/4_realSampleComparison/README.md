# Real Sample Comparison
## Data preparation
1. Create local `data`, `statistics`, and `figures` directories

2. Copy different (random) preprocessed but not clustered/filtered biological files into the local Data folder. In my thesis, I used:

   - .../Data/Mouse/SF-3T#4/BM_175d_1_1507_025.fna
   
   - .../Data/Mouse/SF-3T#5/PB_41d_1_1505_035.fna
   
   - .../Data/Mouse/SF-3#1/PB_175d_2_1507_035.fna
   
   - .../Data/Mouse/SF-3#4/PB_41d_1_1505_030.fna
   
   - .../Data/Mouse/SF-T#1/PB_83d_1_1505_036.fna
   
   - .../Data/Mouse/SF-T#3/PB_19d_1_1505_009.fna
   
3.	Rename files, e.g., `PB_19d_1_1505_009.fna` to `SFT3_PB_19d_1.fna`
   
4. Apply different combinations of clustering and filtering steps:

    - **S: Stringency Filter**: Run `.../4_realSampleComparison/scripts/Filter_Deviation_10_JD_Docker.py` with `userMaxDev = 0` (line 6).

      ```sh
      docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/4_realSampleComparison/scripts/Filter_Deviation_10_JD_Docker.py /JD/analysis/4_realSampleComparison/data
      ```
      
    - **R: Read Filter**: Run `.../4_realSampleComparison/scripts/Filter_Reads_13_JD_Docker.py` with `userThresh = 1` (line 6) and set `userSkip = None`. Again select all files in Data.

      ```sh
      docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/4_realSampleComparison/scripts/Filter_Reads_13_JD_Docker.py /JD/analysis/4_realSampleComparison/data
      ```
      
    - **C: Clustering**: Run `.../4_realSampleComparison/scripts/Clust-Indiv_21_JD_Docker.py` with `user_fixed_CD = 2` (line 6) and `highestDeviation = 2` (line 9). The other settings can be ignored.

      ```sh
      docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/4_realSampleComparison/scripts/Clust-Indiv_21_JD_Docker.py /JD/analysis/4_realSampleComparison/data
      ```
    
    - **SC**: Run the clustering script with the same settings on the stringency-filtered files (`.../03_miniBulkComparison/Data/MaxDev0/`).

      ```sh
      docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/4_realSampleComparison/scripts/Clust-Indiv_21_JD_Docker.py /JD/analysis/4_realSampleComparison/data/MaxDev0
      ```
      
    - **SCR**: Run the read filtering script (same settings) on the SC-filtered files (`.../03_miniBulkComparison/Data/MaxDev0/Clustered_CD2/`).

      ```sh
      docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/4_realSampleComparison/scripts/Filter_Reads_13_JD_Docker.py /JD/analysis/4_realSampleComparison/data/MaxDev0/Clustered_CD2
      ```
      
    - **CS**: Run the stringency-filtering script on the clustered files (`.../03_miniBulkComparison/Data/Clustered_CD2/`).

      ```sh
      docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/4_realSampleComparison/scripts/Filter_Deviation_10_JD_Docker.py /JD/analysis/4_realSampleComparison/data/Clustered_CD2
      ```
      
    - **CSR**: Run the read filtering script on the CS files (`.../03_miniBulkComparison/Data/Clustered_CD2/MaxDev0/`).

      ```sh
      docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/4_realSampleComparison/scripts/Filter_Reads_13_JD_Docker.py /JD/analysis/4_realSampleComparison/data/Clustered_CD2/MaxDev0/
      ```

5. Run `.../4_realSampleComparison/scripts/Sort-for-Comparison_Docker.py`, passing the local data directory as its single argument.

   ```sh
   docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/4_realSampleComparison/scripts/Sort-for-Comparison_Docker.py /JD/analysis/4_realSampleComparison/data
   ```

   ->	This code creates subdirectories for each file and copies the respective filter-applied files of the same samples into it, meanwhile renaming the files to the applied filter.
   
	
## Create figure
1. Open `ClonalDev_85_JD_Docker.R`. Settings:

   - usr[["thresh"]] <- 0.01 
   - usr[["thresh.label"]] <- 0.1
   - usr[["minimalistic"]] <- FALSE 
   - usr[["scale"]] <- 0.25
   - usr[["order"]] <- "overall" 
   - usr[["bar.width"]] <- 0.75 
   - usr[["width"]] <- 1771 
   - usr[["height"]] <- 826 
   - usr[["areas"]] <- FALSE 
   - usr[["area.last"]] <- FALSE 
   - usr[["areas.alpha"]] <- 0.5 
   - usr$colors[["use.previous"]] <- FALSE
   - usr$colors[["set"]] <- "viridis" 
   - usr[["title"]] <- NA 
   - usr[["title.x"]] <- NA 
   - usr[["angle.x"]] <- 0 
   - usr$colors[["text"]] <- "white"
   - usr[["lab.size"]] <- 4.5

2. Run the code. Pass the directory of a certain sample as the first argument and afterwards the desired order of the bars (from left to right)

   _SF-3#1 PB 175d 2_
   ```sh
   docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/4_realSampleComparison/ClonalDev_85_JD_Docker.R /JD/analysis/4_realSampleComparison/data/SF3_PB_175d_2 Raw S R C SC SCR CS CSR
   ```

   _SF-3#4 PB 41d 1_
   ```sh
   docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/4_realSampleComparison/ClonalDev_85_JD_Docker.R /JD/analysis/4_realSampleComparison/data/SF3_PB_41d_1 Raw S R C SC SCR CS CSR
   ```

   _SF-T#3 PB 19d 1_
   ```sh
   docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/4_realSampleComparison/ClonalDev_85_JD_Docker.R /JD/analysis/4_realSampleComparison/data/SFT_PB_19d_1 Raw S R C SC SCR CS CSR
   ```

   _SF-3T#4 BM 175d 1_
   ```sh
   docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/4_realSampleComparison/ClonalDev_85_JD_Docker.R /JD/analysis/4_realSampleComparison/data/SF3T_BM_175d_1 Raw S R C SC SCR CS CSR
   ```

   _SF-3T#5 PB 41d 1_
   ```sh
   docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/4_realSampleComparison/ClonalDev_85_JD_Docker.R /JD/analysis/4_realSampleComparison/data/SF3T_PB_41d_1 Raw S R C SC SCR CS CSR
   ```
   _SF-T#1 PB 83d 1_
   ```sh
   docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/4_realSampleComparison/ClonalDev_85_JD_Docker.R /JD/analysis/4_realSampleComparison/data/SFT_PB_83d_1 Raw S R C SC SCR CS CSR
   ```

-> Move those images from the export to the local figures folder. For the final figure, SFT1_PB_83d_1 was taken and slightly adjusted in paint to have a higher color contrast between the different clones in Raw/R vs. C/CS/CSR

-> Further a corresponding statistics csv file for each file is created with those barcodes that at least have 5% participation in any of the strategies. Move those to the local statistics folder. Paste information from the exported `Comp_Biolog_Table.csv` into the Data.xslx. Manually type in the total read count (seen in the figure) and calculate the percentages. Make further adaptions in excel for the final table output in power point.
Allocation, which sequence is which color, can be done by the percentages and comparison of the sequence structure.

