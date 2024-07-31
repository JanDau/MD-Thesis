# Library Size

## Data preparation

1. Create local `figures` and `data` directories; within the latter, create `Cer-1507`, `mCh-fuse`, `Ven-1507`, `mCh_preTX`, and `Cer_preTX` directories.
2. Copy preprocessed plasmid data (applied maximum deviation of 2) into the local `data` directory: From `/data/preprocessed/1507/Reads/MaxDev2`:
   - Cer-1507: ITRGB_091, _092, and _093
   - mCh-fuse: _094, _095, and _096
   - Ven-1507: _097, _098, and _099

   And from `/data/preprocessed/1602/Reads/MaxDev2` copy files _081, _082, and _083 into `mCh-fuse`. Hence, for mCh, use the `fused` / combined data of both runs.

3. Create a cluster library for each plasmid using `.../9_libSize/scripts/Clust-Lib_Create_24_JD_Docker.py` with `userFixedCD = 2`.

```sh
docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/9_libSize/scripts/Clust-Lib_Create_24_JD_Docker.py /JD/analysis/9_libSize/data/Cer-1507

docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/9_libSize/scripts/Clust-Lib_Create_24_JD_Docker.py /JD/analysis/9_libSize/data/mCh-fuse

docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/9_libSize/scripts/Clust-Lib_Create_24_JD_Docker.py /JD/analysis/9_libSize/data/Ven-1507
```

4. Afterward, apply the library using `.../9_libSize/scripts/Clust-Lib_Use_23_JD_Docker.py`. Select all files inside, e.g., the Cer-1507 folder (the replicates and the Lib.fna).

```sh
docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/9_libSize/scripts/Clust-Lib_Use_23_JD_Docker.py /JD/analysis/9_libSize/data/Cer-1507

docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/9_libSize/scripts/Clust-Lib_Use_23_JD_Docker.py /JD/analysis/9_libSize/data/mCh-fuse

docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/9_libSize/scripts/Clust-Lib_Use_23_JD_Docker.py /JD/analysis/9_libSize/data/Ven-1507
```

5. Run `.../9_libSize/scripts/Filter_Deviation_10_JD_Docker.py` with `usrMaxDev = 0` (edit the script with NotePad++ prior to execution).

```sh
docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/9_libSize/scripts/Filter_Deviation_10_JD_Docker.py /JD/analysis/9_libSize/data/Cer-1507/UsedLibrary

docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/9_libSize/scripts/Filter_Deviation_10_JD_Docker.py /JD/analysis/9_libSize/data/mCh-fuse/UsedLibrary

docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/9_libSize/scripts/Filter_Deviation_10_JD_Docker.py /JD/analysis/9_libSize/data/Ven-1507/UsedLibrary
```

6. Run `.../9_libSize/scripts/Filter_Reads_13_JD_Docker.py` with:
   - `userThresh = 1`
   - `userSkip = ["mean", 8]` (edit the script with NotePad++ prior to execution).

```sh
docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/9_libSize/scripts/Filter_Reads_13_JD_Docker.py /JD/analysis/9_libSize/data/Cer-1507/UsedLibrary/MaxDev0

docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/9_libSize/scripts/Filter_Reads_13_JD_Docker.py /JD/analysis/9_libSize/data/mCh-fuse/UsedLibrary/MaxDev0

docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/9_libSize/scripts/Filter_Reads_13_JD_Docker.py /JD/analysis/9_libSize/data/Ven-1507/UsedLibrary/MaxDev0
```

7. Create a local Excel file (`.../Data_LibrarySize.xlsx`) to collect/summarize all data for easier graph generation.

## Figure 31a

1. Run `.../9_libSize/scripts/01_Chapman-Chao-MLE_Docker.R` by first passing the path with the raw files:

```sh
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/9_libSize/scripts/01_Chapman-Chao-MLE_Docker.R /JD/analysis/9_libSize/data/Cer-1507

docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/9_libSize/scripts/01_Chapman-Chao-MLE_Docker.R /JD/analysis/9_libSize/data/mCh-fuse

docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/9_libSize/scripts/01_Chapman-Chao-MLE_Docker.R /JD/analysis/9_libSize/data/Ven-1507
```

The code creates .csv files `Chap-Chao-MLE_....csv` in the export directory. Copy the `Linc` and `Linc_SD` columns into `Data_LibrarySize.xlsx` (worksheet `a_treatment`). Create a third column, `N,` with the number of replicates included (3 for Cerulean, Venus, and 6 for mCherry). Repeat for the other two plasmids, ultimately having a structure like:

2. Repeat step 1 for the clustered (`./Data/Cer-1507/UsedLibrary`) and for the CSR-treated files (`./Data/Cer-1507/UsedLibrary/MaxDev0/MinReads2/`):

```sh
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/9_libSize/scripts/01_Chapman-Chao-MLE_Docker.R /JD/analysis/9_libSize/data/Cer-1507/UsedLibrary

docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/9_libSize/scripts/01_Chapman-Chao-MLE_Docker.R /JD/analysis/9_libSize/data/Cer-1507/UsedLibrary/MaxDev0/MinReads2

docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/9_libSize/scripts/01_Chapman-Chao-MLE_Docker.R /JD/analysis/9_libSize/data/mCh-fuse/UsedLibrary

docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/9_libSize/scripts/01_Chapman-Chao-MLE_Docker.R /JD/analysis/9_libSize/data/mCh-fuse/UsedLibrary/MaxDev0/MinReads2

docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/9_libSize/scripts/01_Chapman-Chao-MLE_Docker.R /JD/analysis/9_libSize/data/Ven-1507/UsedLibrary

docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/9_libSize/scripts/01_Chapman-Chao-MLE_Docker.R /JD/analysis/9_libSize/data/Ven-1507/UsedLibrary/MaxDev0/MinReads2
```

3. Paste the data into the local GraphPad file to generate the bar plot.
4. Move the csv files from the export to the local csv directory.

## Figure 31b

1. You find the Lincoln, Chapman, Chao, and MLE values in the previously (Figure 31a) generated .csv files for the CSR-treated files. Copy and paste them into `Data_LibrarySize.xlsx` (worksheet `b_estimators`).

2. For the Hypergeom estimation, open `.../9_libSize/scripts/02_HypergeomPoolsize_11_JD_Docker.R` with NotePad++ and use the following user variables:
   - `sizeMin <- 1`
   - `sizeMax <- 200000`

Run the code, passing the path of the CSR-treated replicates of the respective plasmid, e.g., (`./Data/Cer-1507/UsedLibrary/MaxDev0/MinReads2/`):

```sh
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/9_libSize/scripts/02_HypergeomPoolsize_11_JD_Docker.R /JD/analysis/9_libSize/data/Cer-1507/UsedLibrary/MaxDev0/MinReads2

docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/9_libSize/scripts/02_HypergeomPoolsize_11_JD_Docker.R /JD/analysis/9_libSize/data/mCh-fuse/UsedLibrary/MaxDev0/MinReads2
```

Copy the information, Mean and SD, from the console into the Excel sheet at worksheet `b_estimators`, e.g., for the CSR-treated Cerulean replicates it would be `Mean = 33247 SD = 2974`.

3. Paste the data into the local GraphPad file to generate the bar plot.

## Figure 31c

1. Copy CSR-treated preTX data into the local data directory, e.g., for mCherry copy:
   - preTX_SF3_1_1505_005.fna, _066, _067 from `/data/mouse_CSR/preTX_SF-3`
   - preTX_SF3T_1_1505_006.fna, _068, _069 from `/data/mouse_CSR/preTX_SF-3T`
   - preTX_SFT_1_1505_004.fna, _064, _065 from `/data/mouse_CSR/preTX_SF-T`

into `.../data/mCh_preTX`.

Repeat for Cerulean from the Human/Xenograft cohort.

2. Run `.../9_libSize/scripts/01_Chapman-Chao-MLE_Docker.R` on the previous preTX replicates:

```sh
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/9_libSize/scripts/01_Chapman-Chao-MLE_Docker.R /JD/analysis/9_libSize/data/Cer_preTX

docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/9_libSize/scripts/01_Chapman-Chao-MLE_Docker.R /JD/analysis/9_libSize/data/mCh_preTX
```

3. Move the csv file to the local csv directory and paste the information into `Data_LibrarySize.xlsx` (worksheet `c_preTX_vs_plasm`).
4. Paste the data into GraphPad for the plot.

## Figure 31d and e

1. Run `.../9_libSize/scripts/03a_Complexity_Docker.R` passing the directory with the merged, CSR-treated files of the murine or human cohort:

```sh
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/9_libSize/scripts/03a_Complexity_Docker.R /JD/data/mouse_CSR

docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/9_libSize/scripts/03a_Complexity_Docker.R /JD/data/human_CSR
```

cave: All numbers except Rows, Shannon, and Complexity of the last row will differ, depending on the order the files are processed in the script. The preTX files should go first in any strategy. New .csv files are generated at the export directory `Complexity_...csv`. Move them to the local csv directory.

2. For the murine cohort, run `.../9_libSize/scripts/03b_BC-Saturation-Regression_Docker.R` passing the complexity csv file of the mouse cohort as its single argument:

```sh
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/9_libSize/scripts/03b_BC-Saturation-Regression_Docker.R /JD/analysis/9_libSize/csv/mouse_Complexity_20240517_11-22-45.csv
```

A .tiff file is created in the export directory, which should be moved to the local figures folder. Further, save the information from the console into the local `Regression Limit Counts.txt`.

3. For the xenograft cohort, open and run `.../9_libSize/scripts/03c_BC-Saturation-Regression_xeno_Docker.R`, passing the respective human complexity csv:

```sh
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/9_libSize/scripts/03c_BC-Saturation-Regression_xeno_Docker.R /JD/analysis/9_libSize/csv/human_Complexity_20240517_11-22-56.csv
```

Assemble all figures and respective legends and custom annotations including the regression limit, simple count information, etc. in `LibrarySize.pptx`.
