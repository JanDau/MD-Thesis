# Replicate Treatment
## Data Preparation

1. Create local `data`, `figures`, and `statistics` directories.

2. As a representative for a sample with high diversity, copy the CSR-treated, unmerged preTX samples of the SFT condition into the local Data folder:
   - `/data/mouse_CSR/preTX-SF-T/preTX_SFT_1_1505_004.fna`
   - `.../preTX_SFT_2_1505_064.fna`
   - `.../preTX_SFT_3_1505_065.fna`

   into `/analysis/6_replicateTreatment/data/high`

3. As a representative for a sample with low diversity, copy the CSR-treated, unmerged 19d PB samples of the SF-3#2 mouse into the local Data folder:
   - `/data/mouse_CSR/SF-3#2/PB_19d_1_1505_013.fna`
   - `.../PB_19d_2_1505_072.fna`
   - `.../PB_19d_3_1505_073.fna`

   into `data/barcode_data/analysis/6_replicateTreatment/data/low`

## Figure 28a: Reads per Sample

1. Open `.../6_replicateTreatment/readsPerSample_Docker.R` with NotePad++. Adjust lines 4-6, if desired. In my thesis, I used `usr_dev <- 2`, `usr_run <- 1505`, and `usr_comp <- all`, which means that only sequences with a deviation less than 2 were relevant, as well as all relevant samples for the murine cohort indicated/identified in/by `/scripts/Sample-Allocation.csv` from the run 1505.

2. Run the code passing the preprocessed directory as the first argument and the Sample-Allocation.csv as the 2nd argument:

   ```sh
   docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/6_replicateTreatment/scripts/readsPerSample_Docker.R /JD/data/preprocessed /JD/scripts/Sample-Allocation.csv
   ```
   The `.tiff` file is created in the /docker/export directory.

   Cave: the mean read count refers to all samples in that run after preprocessing but after exclusion of files with a too low read count.

3. Move the image file into figures.

### Figure 28b-c: Venn Diagrams

1. Open `.../6_replicateTreatment/venn_indiv_32_JD_Docker.R` with RStudio. Use the following settings (lines 8-15):

   - `usr[["weight"]] <- "Reads"`
   - `usr[["print"]] <- "raw"`
   - `usr[["scaled"]] <- TRUE`
   - `usr[["names"]] <- FALSE`
   - `usr[["lwd"]] <- 5`
   - `usr[["col"]] <- "viridis"`
   - `usr$own[["use"]] <- FALSE`

2. Run the code passing the path of the local data directory as the first argument and afterwards, the three preTX files in the following order as separate arguments, as the order will affect the placement of the file in the Venn diagram. In this case, `preTX_SFT_1_1505_004.fna` will be at the top left, `preTX_SFT_2_1505_064.fna` at the top right, and `preTX_SFT_3_1505_065.fna` at the bottom:

   ```sh
   docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/6_replicateTreatment/scripts/venn_indiv_32_JD_Docker.R /JD/analysis/6_replicateTreatment/data/high preTX_SFT_1_1505_004 preTX_SFT_2_1505_064 preTX_SFT_3_1505_065
   ```

3. Rerun the code, now selecting the 19d PB replicates:
   ```sh
   docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/6_replicateTreatment/scripts/venn_indiv_32_JD_Docker.R /JD/analysis/6_replicateTreatment/data/low PB_19d_1_1505_013 PB_19d_2_1505_072 PB_19d_3_1505_073
   ```

4. Now change the following settings:
   
   - usr[["weight"]] <- "Seq"
   - usr[["scaled"]] <- FALSE

5.	Run the code for the preTX and 19d samples using the same positioning as before.

6.	Move the image files into Figures.

## Figure 28d: Effects of Merging
1. Run  `.../6_replicateTreatment/scripts/shannon_Table_Multiple_10_JD_Docker.R` passing the directory with the CSR-treated mouse files as the first argument and the local statistics directory as the 2nd argument:

   ```sh
   docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/6_replicateTreatment/scripts/shannon_Table_Multiple_10_JD_Docker.R /JD/data/mouse_CSR /JD/analysis/6_replicateTreatment/statistics
   ```

2. Run `.../6_replicate-Treatment/scripts/mergingEffectShannonSequences_Docker.R`. passing the local statistics directory as its first argument and Shannon as the 2nd argument:

   ```sh
   docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/6_replicateTreatment/scripts/mergingEffectShannonSequences_Docker.R /JD/analysis/6_replicateTreatment/statistics Shannon
   ```
   
   -> save the statistics from the command line into a local txt file, e.g., t-tests.txt

3. Rerun the last script, now passing Sequences as the 2nd argument:

   ```sh
   docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/6_replicateTreatment/scripts/mergingEffectShannonSequences_Docker.R /JD/analysis/6_replicateTreatment/statistics Sequences
   ```

   -> save the statistics from the command line into a local txt file, e.g., t-tests.txt

4. Move the created images from the /docker/export to the local figures directory.

## Figure 28e: Clonal development merged vs. unmerged
1. Run `.../6_replicate-Treatment/scripts/Merge_Replicates_13_JD_Docker.py`. passing the `.../data/low` directory as its argument.

   ```sh
   docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/6_replicateTreatment/scripts/Merge_Replicates_13_JD_Docker.py /JD/analysis/6_replicateTreatment/data/low
   ```

2. Move the Merged file (from `.../6_replicate-Treatment/data/low/Merged/PB_19d_Merged-3.fna) into its parent directory (`.../6_replicate-Treatment/data/low/PB_19d_Merged-3.fna`
  
3. Open `.../6_replicate-Treatment/ClonalDev_85_JD.R` with RStudio. Use the following settings (lines 12-24):
   - usr[["thresh"]] <- 0.01
   - usr[["thresh.label"]] <- 0.05
   - usr[["minimalistic"]] <- TRUE
   - usr[["scale"]] <- 0.25
   - usr[["order"]] <- "first"
   - usr[["bar.width"]] <- 0.65
   - usr[["width"]] <- 826
   - usr[["height"]] <- 531
   - usr[["areas"]] <- TRUE
   - usr[["area.last"]] <- TRUE
   - usr[["areas.alpha"]] <- 0.5
   - usr$colors[["use.previous"]] <- FALSE
   - usr$colors[["set"]] <- "viridis"

   **cave:** colors may slightly differ 

   ```sh
   docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/6_replicateTreatment/scripts/ClonalDev_85_JD_Docker.R /JD/analysis/6_replicateTreatment/data/low PB_19d_1_1505_013 PB_19d_2_1505_072 PB_19d_3_1505_073 PB_19d_Merged-3
   ```

   -> move the figure from /docker/export to the local figures directory. The generated .csv file with the statistics can be deleted.

Figure 28 is composed and the figures from above slightly edited in their labels, the t-tests statistics added, ... with PowerPoint `.../6_replicate-Treatment/Replicate-Treatment.pptx`
