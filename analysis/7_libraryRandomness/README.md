# Library Randomness

## Data preparation

1. Create a local `figures` directory.
2. Open `.../7_libraryRandomness/scripts/Merge_Animal_Multiple_12_JD_Docker.py` with NotePad++ and set line 5 to: `usr_filter = ```.
3. Save. Run the code, passing the path to the unclustered, unfiltered (raw) but allocated files inside `/data/mouse`, which are required for the distance distribution comparison of the entire and bone marrow data set in Fig. 29c-d:

```sh
docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/7_libraryRandomness/scripts/Merge_Animal_Multiple_12_JD_Docker.py /JD/data/mouse
```

The files will be in the same directory (`/data/mouse`) and named like `Merged__SF-3#1` (so no filter like `CS` in between the `_`).

## Fig. 29a: Sequence Logos

1. Run `.../7_libraryRandomness/scripts/Sequence-Logo_Docker.R` (no user-defined parameters):

```sh
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/7_libraryRandomness/scripts/Sequence-Logo_Docker.R
```

2. Move the generated image files from the export to the local figures directory.

## Fig. 29b: Distance distribution plots

### In-silico data

1. First, create a persistent R environment, as the 01b_Graph-in-silico_Docker.R will rely on the data environment of the primarily executed 01a_Generate-Seq_20_JD.R:

```sh
docker run -it -v C:/your/path:/JD --name clonal_dev_container -d r_env tail -f /dev/null
```

2. Open an interactive R session within this container:

```sh
docker exec -it clonal_dev_container R
```

3. Open `.../7_libraryRandomness/scripts/01a_Generate-Seq_20_JD_Docker.R` with NotePad++ and adjust lines 28-38 to the following user settings:

   ```r
   num_files = 1,
   num_seq = 1000,
   rand_pos = 16,
   stringent_only = TRUE,
   base_weight = c("A" = 0.35, "T" = 0.35, "C" = 0.15, "G" = 0.15),
   max_dist = 3,
   dist_rel = c(0.5, 0.25, 0.15, 0.1),
   perc_real = 0.025,
   perc_daughters = 0.95,
   max_err = 3,
   err_rel = c(0.65, 0.3, 0.05)
   ```

4. Inside the CLI (active R Session), now run:

   ```r
   source("/JD/analysis/7_libraryRandomness/scripts/01a_Generate-Seq_20_JD_Docker.R")
   ```

5. Inside the CLI (active R Session), now write:

   ```r
   df_AT70 <- df_final
   ```

6. Adjust the base_weight to NA in the user settings within NotePad++:

   ```r
   num_files = 1,
   num_seq = 1000,
   rand_pos = 16,
   stringent_only = TRUE,
   base_weight = NA,  // cave: don’t forget the comma at the end of the line!
   max_dist = 3,
   dist_rel = c(0.5, 0.25, 0.15, 0.1),
   perc_real = 0.025,
   perc_daughters = 0.95,
   max_err = 3,
   err_rel = c(0.65, 0.3, 0.05)
   ```

7. Rerun the code with the adjusted user settings:

   ```r
   source("/JD/analysis/7_libraryRandomness/scripts/01a_Generate-Seq_20_JD_Docker.R")
   ```

8. Without closing the active R session (and thus the variable environment): Open `.../7_libraryRandomness/scripts/01b_Graph-in-silico_Docker.R` with NotePad++ and adjust lines 1, 2, 24, and 31, if you have used different proportions/names, otherwise just run the code (the execution may take a couple of seconds):

   ```r
   source("/JD/analysis/7_libraryRandomness/scripts/01b_Graph-in-silico_Docker.R")
   ```

9. Close the R session, without saving the workspace image

   ```r
   q()
   ```

10. Terminate the R container:

   ```sh
   docker rm -f clonal_dev_container 
   ```

11. Move the figure from the export into the local figure directory and rename it to `In-silico.tiff`.

## Entire data

1. Open `.../7_libraryRandomness/scripts/02_Distance-Distr-Cohort_Docker.R` with NotePad++. Use the following user settings (line 1): `usr_thresh <- 1000`.
2. Run the code, passing the directory of where the merged, raw files are located, e.g., `/data/mouse/Merged__SF-3#1.fna` as the first argument and the CSR-treated merged files, e.g., `/data/mouse_CSR/Merged__SF-3#1.fna` as the 2nd argument:

   ```sh
   docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/7_libraryRandomness/scripts/02_Distance-Distr-Cohort_Docker.R /JD/data/mouse /JD/data/mouse_CSR
   ```

   cave: it is important that the relevant files, in both cases, start with `Merged__` (so a double underscore, as I used this in the Docker version to select the respective files, but not, e.g. the `Merged_CS_` files)

   cave2: Calculating might take a while. Afterward, the plot is saved in the export directory. Rename it to `Entire-data.tiff` and move it to the local figures folder.

## Bone marrow data

1. We again need a persistent R container:

   ```sh
   docker run -it -v C:/your/path:/JD --name clonal_dev_container -d r_env tail -f /dev/null
   ```

2. Open an interactive R session within this container:

   ```sh
   docker exec -it clonal_dev_container R
   ```

3. Set the arguments that will be passed to the script in the R session (directory with the raw mouse files):

   ```r
   args <- "/JD/data/mouse"
   ```

4. Open `.../7_libraryRandomness/scripts/03a_Dist-certain_Docker.R` with NotePad++. Use the following user settings (line 1):

   ```r
   usr_thresh <- 1000
   usr_choice <- c("BM") 
   usr_filter <- NA
   ```

5. Run the code:

   ```r
   source("/JD/analysis/7_libraryRandomness/scripts/03a_Dist-certain_Docker.R")
   ```

   cave: may take a couple of seconds

6. Then write the following into the R session:

   ```r
   df_BM_raw <- df_data_smooth
   ```

7. Adjust the `args` variable:

   ```r
   args <- "/JD/data/mouse_CSR"
   ```

8. Rerun the code:

   ```r
   source("/JD/analysis/7_libraryRandomness/scripts/03a_Dist-certain_Docker.R")
   ```

9. Without deleting the Global Environment or renaming any variable, run `.../7_libraryRandomness/scripts/03b_BM-fuse-graph_Docker.R` (no user-defined settings):

   ```r
   source("/JD/analysis/7_libraryRandomness/scripts/03b_BM-fuse-graph_Docker.R")
   ```

   The plot is saved in the export directory. Rename it to `BM-data.tiff` and move it to figures.

10. Leave the R session without saving the environment:

   ```r
   q()
   ```

11. Remove the container:

   ```sh
   docker rm -f clonal_dev_container 
   ```

## Final Steps

Figure 29 is composed of the figures from above and is slightly edited with PowerPoint in `.../7_LibraryRandomness/LibraryRandomness.pptx`.

cave: The figure may not be exactly the same during reproduction, as out of performance reasons, I do not include all sequences from the real samples, instead only a subset of `usr_thresh` (here 1000 sequences). However, the overall distribution will be the same, only the exact height of the peak will slightly differ.
