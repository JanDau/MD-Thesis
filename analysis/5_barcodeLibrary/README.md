# Barcode Library
## Data Preparation

1. Create local `Data_indiv` and `Data_lib` directories.

2. Copy preprocessed files that were not clustered or filtered from SF-T#1 (murine cohort) into the Data_indiv folder: all files (except subdirectories, Statistics.txt, Lib-SF-T#1.fna and preTx) from `Data/Barcode Data/Data/Mouse/SF-T#1` to `.../analysis/5_barcodeLibrary/data_indiv`.

3. Individual cluster files of mouse SF-T#1 (murine cohort).

    a. For this, run `.../5_barcodeLibrary/scripts/Clust-Indiv_21_JD_Docker.py` with `user_fixed_CD = 2` and `highestDeviation = 2`.

    b. Pass the `.../5_barcodeLibrary/data_indiv` directory as its argument:

    ```sh
    docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/5_barcodeLibrary/scripts/Clust-Indiv_21_JD_Docker.py /JD/analysis/5_barcodeLibrary/data_indiv
    ```

4. Merge the individually clustered replicates of mouse SF-T#1 using `.../5_barcodeLibrary/scripts/Merge_Replicates_13_JD_docker.py`:

    ```sh
    docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/5_barcodeLibrary/scripts/Merge_Replicates_13_JD_Docker.py /JD/analysis/5_barcodeLibrary/data_indiv/Clustered_CD2
    ```

5. Copy library-clustered files of the same mouse, found at `.../Data/Mouse/SF-T#1/UsedLibrary/` again without the preTX or subdirectories into the local Data_lib folder.

6. Merge files like in step 4:

    ```sh
    docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/5_barcodeLibrary/scripts/Merge_Replicates_13_JD_Docker.py /JD/analysis/5_barcodeLibrary/data_lib
    ```

## Create Figure

1. Open the local "ClonalDev_85_JD_Docker_bcLib.R" with NotePad++. Use the following settings (only important ones):
   
    a. `usr[["thresh"]] <- 0.01`
    
    b. `usr[["thresh.label"]] <- 0.05`
    
    c. `usr[["minimalistic"]] <- TRUE`
    
    d. `usr[["scale"]] <- 0.5`
    
    e. `usr[["order"]] <- "overall"`
    
    f. `usr[["bar.width"]] <- 0.5`
    
    g. `usr[["width"]] <- 944`
    
    h. `usr[["height"]] <- 413`
    
    i. `usr[["areas"]] <- TRUE`
    
    j. `usr[["area.last"]] <- TRUE`
    
    k. `usr[["areas.alpha"]] <- 0.5`
    
    l. `usr$colors[["use.previous"]] <- TRUE`
    
    m. `usr$colors[["set"]] <- "viridis"`

2. Calling these scripts with Docker is a little tricky, as data from the R environment after execution of the first code is required for the second script. For this, create a continuously running container:

    ```sh
    docker run -it -v C:/your/path:/JD --name clonal_dev_container -d r_env tail -f /dev/null
    ```

3. Open an interactive R session within this container:

    ```sh
    docker exec -it clonal_dev_container R
    ```

4. Save the arguments which are normally passed to the script via the CLI as `args`:

    ```R
    args <- c("/JD/analysis/5_barcodeLibrary/data_lib/merged", "PB_19d_Merged-2", "PB_41d_Merged-2", "PB_83d_Merged-2", "PB_175d_Merged-2", "BM_175d_Merged-2")
    ```

5. Run the code for the library-clustered files (given in the first `args` element):

    ```R
    source("/JD/analysis/5_barcodeLibrary/ClonalDev_85_JD_Docker_bcLib.R")
    ```

6. Adapt the `args` variable so in the next call of the code, the individually clustered and merged files are used:

    ```R
    args <- c("/JD/analysis/5_barcodeLibrary/data_indiv/Clustered_CD2/merged", "PB_19d_Merged-2", "PB_41d_Merged-2", "PB_83d_Merged-2", "PB_175d_Merged-2", "BM_175d_Merged-2")
    ```

7. And run the code:

    ```R
    source("/JD/analysis/5_barcodeLibrary/ClonalDev_85_JD_Docker_bcLib.R")
    ```

8. Afterwards, leave the R session without saving the environment:

    ```R
    q()
    ```

9. And remove the container:

    ```sh
    docker rm -f clonal_dev_container
    ```

The images are found in the `/docker/export` directory. Move them into the local figures folder. The CSV files holding the statistics can be deleted.

**Cave:** Some colors might change when running the code multiple times (only the first 15 are fixed).
