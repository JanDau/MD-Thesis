# miniBulk Comparison
## Data Preparation
1. Create local `Data`, `Statistics`, and `Figures` directories
2. Copy relevant preprocessed files (unclustered, unfiltered) into local Data folder:

   o 1-BC samples: ITRGB_084, _085 and _086 of run 1602
   
   o 6-BC samples (equally distributed): ITRGB_087, _088 of run 1507
   
   o 6-BC samples (gradually diluted): ITRGB_089 and _090 of run 1507
4. Apply different combinations of clustering and filtering steps:

   o **S: Stringency Filter**: Run `Filter_Deviation_10_JD_Docker.py` with userMaxDev = 0 (line 6).

   ```sh
   docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/3_miniBulkComparison/scripts/Filter_Deviation_10_JD_Docker.py /JD/analysis/3_miniBulkComparison/data
   ```

   o **R: Read Filter**: Run `Mode_miniBulk_Docker.R`:

   ```sh
   docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/3_miniBulkComparison/scripts/Mode_miniBulk_Docker.R /JD/analysis/3_miniBulkComparison/data
   ```

   => In my case, the most frequent read count was 1 in all seven files; hence, I set a minimum read count of 2 (>= 2).
   =>	Run `Filter_Reads_13_JD_Docker.py` with userThresh = 1 (line 6) and set userSkip = None.

   ```sh
   docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/3_miniBulkComparison/scripts/Filter_Reads_13_JD_Docker.py /JD/analysis/3_miniBulkComparison/data
   ```

   o **C: Clustering**: Run `Clust-Indiv_21_JD_Docker.py` with user_fixed_CD = 5 (line 6) and highestDeviation = 5 (line 9). The other settings can be ignored. 

   ```sh
   docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/3_miniBulkComparison/scripts/Clust-Indiv_21_JD_Docker.py /JD/analysis/3_miniBulkComparison/data
   ```

   o **SC:** Run the clustering script with the same settings on the stringency-filtered files (`03_miniBulkComparison/data/MaxDev0`)

   ```sh
   docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/3_miniBulkComparison/scripts/Clust-Indiv_21_JD_Docker.py /JD/analysis/3_miniBulkComparison/data/MaxDev0
   ```

   o **SCR:** Run the read filtering script (same settings) on the SC-filtered files (`03_miniBulkComparison/data/MaxDev0/Clustered_CD5)

   ```sh
   docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/3_miniBulkComparison/scripts/Filter_Reads_13_JD_Docker.py /JD/analysis/3_miniBulkComparison/data/MaxDev0/Clustered_CD5
   ```

   o **CS:** Run the stringency-filtering script on the clustered files (`03_miniBulkComparison/Data/Clustered_CD5)

   ```sh
   docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/3_miniBulkComparison/scripts/Filter_Deviation_10_JD_Docker.py /JD/analysis/3_miniBulkComparison/data/Clustered_CD5
   ```

   o **CSR**: run the read filtering script on the CS files. (`03_miniBulkComparison/Data/Clustered_CD5/MaxDev0`)

   ```sh
   docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/3_miniBulkComparison/scripts/Filter_Reads_13_JD_Docker.py /JD/analysis/3_miniBulkComparison/data/Clustered_CD5/MaxDev0
   ```


## Analysis of the 1-barcode sample
1.	Open `1-BC-Table.R`. Adapt the paths in usr$strategy (line 3-9) if necessary.

2.	Run the code, passing the raw files of the 1-barcode samples  (084-086) to it:

      ```sh
      docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/3_miniBulkComparison/1-BC-Table_Docker.R /JD/analysis/3_miniBulkComparison/data/ITRGB_084.fna /JD/analysis/3_miniBulkComparison/data/ITRGB_085.fna /JD/analysis/3_miniBulkComparison/data/ITRGB_086.fna
      ```

      ->	a .csv file containing the sequence count (+/- SD) and %Reads of reference BC (+/- SD) is exported in the /docker/export directory. Move it to the local statistics folder.


## Analysis of the 6-barcode samples (illustration of representation)
1. Open `Method-Comparison_12var_JD.R`.
   - set usr$nSeq <- 6 (line 6) and usr$equal <- TRUE (line 7)
   - eventually adapt paths in line 8 and 16

2. Run the code, selecting the raw files of the equal distributed 6-BC-samples (087, 088) in the local Data folder:

   ```sh
   docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/3_miniBulkComparison/Method-Comparison_12var_JD_Docker.R /JD/analysis/3_miniBulkComparison/data/ITRGB_087.fna /JD/analysis/3_miniBulkComparison/data/ITRGB_088.fna
   ```

   => .tiff files are generated in the /docker/export directory. Move to local figures/equally directory

3. Repeat for the gradually diluted samples. Set line 7 to usr$equal <- FALSE
	
   Afterwards run the code selecting ITRGB_089 and _090.fna

   ```sh
   docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/3_miniBulkComparison/Method-Comparison_12var_JD_Docker.R /JD/analysis/3_miniBulkComparison/data/ITRGB_089.fna /JD/analysis/3_miniBulkComparison/data/ITRGB_090.fna
   ```

   -> The image for CSR-filtered data for the equally distributed samples was used in the thesis.


## Analysis of the 6-barcode samples (Sensitivity, Specificity, Precision)
1. Open `6-BC_Create-csv_Docker.R`.
   - Adapt paths in usr$strategy (line 6-12) if necessary.
   
   - Set usr$nseq to 6 (line 13).
   
   - Depending on the files you analyze, set usr$equal to TRUE (087, 088) or FALSE (089, 090)
2. With line 14 set to TRUE, run the code, selecting the raw files of the equal distributed 6-BC-samples (087, 088) in the local Data folder:

   ```sh
   docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/3_miniBulkComparison/6-BC_Create-csv_Docker.R /JD/analysis/3_miniBulkComparison/data/ITRGB_087.fna /JD/analysis/3_miniBulkComparison/data/ITRGB_088.fna
   ```
   
3. Repeat for the gradually diluted samples. Set line 14 to usr$equal <- FALSE

   Afterwards run the code selecting ITRGB_089 and _090.fna

   ```sh
   docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/3_miniBulkComparison/6-BC_Create-csv_Docker.R /JD/analysis/3_miniBulkComparison/data/ITRGB_089.fna /JD/analysis/3_miniBulkComparison/data/ITRGB_090.fna
   ```

   => Two CSV files are exported per run (1 for each file) to the /docker/export directory used in the next step. Move them to the local statistics directory.

4. Run `6-BC_Sens-Spec-Prec_Docker.R` giving the local statistics directory as the first argument. All files that start with `ITRGB_` will be automatically included in the code

   ```sh
   docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/3_miniBulkComparison/6-BC_Sens-Spec-Prec_Docker.R /JD/analysis/3_miniBulkComparison/statistics
   ```

   -> Sensitivity, Specificity, and Precision plots are created in the /docker/export directory.
   (order of the bars from top to bottom: Raw, S, R, C, SC, SCR, CS, CSR).
   -> Move those figures to the local figures folder.

Figure 25 is a composition of the 1-BC statistics (.../statistics/1-BC-Table.csv), the CSR-treated figure of the equally distributed 6-BC-Sample (.../figures/equally/Method-Comp_CSR_....tiff), and the Precision, Sensitity and Specificity images (.../figures) combined in the local pptx file (.../miniBulkComparison.pptx).
