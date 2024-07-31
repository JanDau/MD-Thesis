# Data preparation

1. Create local `figures`, `data`, and `statistics` directories. 
2. Create a txt file named `Stats.txt` in the `statistics` directory.

## Data for information given in the text

1. Run `.../8_libEvenness/scripts/01_LibraryStats_Docker.R` (no user-defined parameters) passing the `mouse_CSR` directory path `/data/mouse_CSR`:

```sh
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/8_libEvenness/scripts/01_LibraryStats_Docker.R /JD/data/mouse_CSR
```

2. Copy the console output giving the general library statistics into `statistics/Stats.txt`.

3. Repeat for the human cohort:

```sh
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/8_libEvenness/scripts/01_LibraryStats_Docker.R /JD/data/human_CSR
```

4. And repeat for the murine 12w PB files:

```sh
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/8_libEvenness/scripts/01_LibraryStats_83d_Docker.R /JD/data/mouse_CSR
```

Copy the console output to the `Stats.txt` as well.

For the mean number of mice that had shared barcodes (`shared barcodes were present in only 1.28 ± 0.63 mice, on average (xenograft cohort: 1.15 ± 0.38)`), you need to (eventually) transform the `Sample-Frequency-Stats_....csv` files from within the local `data/BC-Distr_mouse/mean` or `data/BC-Distr_human/mean` to the German CSV format. For this, copy both CSV files into the local `statistics` directory and rename them (added `_mouse_transformed` or `_human_transformed`). Open with NotePad++. Replace all `,` with `;` and afterwards all `.` with `,`. Then open with Excel. Copy and paste into the yellow area inside `Shared-Analysis..xlsx`, respectively. The mean is calculated (green area).

## Fig. 30a: Read distribution and Shannon/Equitability of low and high diverse samples

### Read distribution

1. Open `.../8_libEvenness/scripts/02a_Read-Distribution_Docker.R` with NotePad++. Set the user settings (lines 4-5) to:
   - `usr_high <- "preTX"`
   - `usr_low <- "83d"`

2. Run the code, passing the `mouse_CSR` directory as the first and the `human_CSR` directory as the second argument:

```sh
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/8_libEvenness/scripts/02a_Read-Distribution_Docker.R /JD/data/mouse_CSR /JD/data/human_CSR
```

The code creates a `Read-Distr_... .tiff` file in the export directory. Move it to `figures`.

### Shannon/Equitability Table

1. Open `.../8_libEvenness/scripts/02b_ShannonEquitability_Docker.R` with NotePad++. Set the user setting (line 4) to `usr_choice <- "83d"`.

2. Run the code, passing the `mouse_CSR` directory as its single argument:

```sh
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/8_libEvenness/scripts/02b_ShannonEquitability_Docker.R /JD/data/mouse_CSR
```

cave: It is important that the merged preTX files are named like `Merged__preTX_...`. Two CSV files will be created in the export directory (`Evenness_mouse_83d_... .xlsx` and `Evenness_mouse_preTX_... .xlsx`).

3. Repeat running `02b_ShannonEquitability_Docker.R` for the human counterpart:

```sh
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/8_libEvenness/scripts/02b_ShannonEquitability_Docker.R /JD/data/human_CSR
```

An error will be returned in the console:

_Error in matrix(NA, ncol = 4, nrow = length(x), dimnames = list(paste0(LETTERS[1:length(x)],  :  ... Execution halted_

Ignore it. It is thrown because the 83d samples are not available for the human cohort, but we only need the preTX information. Move all three `.csv` files into the local `statistics` directory.

The data is directly used for the table in `LibraryEvenness.pptx`.

## Fig. 30b: Barcode distribution

### Data preparation

1. Open `.../8_libEvenness/scripts/03a_BC-Distribution_22_JD_Docker.py` with NotePad++ and ensure that the following user settings are set:
   - `usr_stats = True`
   - `usr_print = list(range(2,19))`
   - `usr_delim = ','` (leave it as ','; otherwise, the following codes become buggy)

Run the code passing the `mouse_CSR` directory as its single argument:

```sh
docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/8_libEvenness/scripts/03a_BC-Distribution_22_JD_Docker.py /JD/data/mouse_CSR
```

2. Repeat with the same settings for the human cohort:

```sh
docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/8_libEvenness/scripts/03a_BC-Distribution_22_JD_Docker.py /JD/data/human_CSR
```

Move the created directories `BC-Distr_human` and `BC-Distr_mouse` from the export directory into the local `data` folder.

3. Next, open `.../8_libEvenness/scripts/03b_BC-Distr_Max-Mean-Med_Docker.py` with NotePad++ and adjust the following settings:
   - `usr_include = ("preTX", "PB_19d", "PB_41d", "PB_83d", "PB_175d", "BM_175d")`
   - `usr_param = "mean"`
   - `usr_delim = ','` (leave it as ','; otherwise, the following codes become buggy)

Run the code passing the `mouse_CSR` directory as its first argument and the `.../data/BC-Distr_mouse` directory as its second argument:

```sh
docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/8_libEvenness/scripts/03b_BC-Distr_Max-Mean-Med_Docker.py /JD/data/mouse_CSR /JD/analysis/8_libEvenness/data/BC-Distr_mouse
```

4. For the human cohort, adjust the settings:
   - `usr_include = ("preTX", "PB_3w", "PB_12w", "BM_12w")`
   - `usr_param = "mean"`
   - `usr_delim = ','` (leave it as ','; otherwise, the following codes become buggy)

Then run:

```sh
docker run -it --rm -v C:/your/path:/JD py_env python /JD/analysis/8_libEvenness/scripts/03b_BC-Distr_Max-Mean-Med_Docker.py /JD/data/human_CSR /JD/analysis/8_libEvenness/data/BC-Distr_human
```

Data will be saved in a new directory `mean` within `.../data/BC-Distr_mouse` or `.../data/BC-Distr_human`.

### Generate Figure: Measured vs. Expected

For the `expected` curve, the library's rough size and the number of barcodes found per animal are required. 
For example, if I had a pool size of 100 distinct BCs and in each animal, 10 barcodes were found, there’s a higher probability that two mice share a certain barcode (p = 0.3874) than three mice sharing that certain barcode (p = 0.1937). The probability that two mice share that specific barcode is even higher than if it is not shared at all (thus occurring only in one mouse: p= 0.3487). The probabilities can be calculated with the binomial distribution function `dbinom(0:10, 10, 10/100)`. In other words, in this scenario, it is most likely that two mice will share one barcode. 
When plotting this as a graph, the first data points would be: `[x, y] = [1, 10], [2, 1]`, whereas the x-axis represents the `shared between ... mice` or `observed in ... mice` and the y-axis `unique barcodes`. Here, x = 1 means that it is not shared, or quite redundantly saying that in one mouse, there will be most likely 10 barcodes. The number of unique barcodes that are shared by two mice (x=2) is most likely 1 (y=1) as calculated with the binomial distribution (highest probability of all).

The relative drop in the probability depends on the (average) number of barcodes found in each mouse; however, whether at least one barcode is shared between x mice further depends greatly on the initial number of unique barcodes. Ideally, estimated library sizes (of unique barcodes) could be used; however, as they were lower than the absolute count of sequences found in the sample (including real barcodes and noise), its calculation is not possible. Therefore, also to have an independent script, I chose the absolute sequence count of the respective samples.

Run `.../8_libEvenness/scripts/03c_Overlap-Comparison_Docker.R`, either passing the `.../data/BC-Distr_mouse` or `.../data/BC-Distr_human` directory as its first argument, which locates the most recent `BC-Distr_Stats_` file in the respective folder and uses its information:

```sh
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/8_libEvenness/scripts/03c_Overlap-Comparison_Docker.R /JD/analysis/8_libEvenness/data/BC-Distr_mouse

docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/8_libEvenness/scripts/03c_Overlap-Comparison_Docker.R /JD/analysis/8_libEvenness/data/BC-Distr_human
```

Assumed data (automatically determined during script execution):
- For the mouse cohort: Size: 97091 BCs/mouse: 43064
- For the human cohort: Size: 32142 BCs/mouse: 27104

During code execution, the theoretical probability for the overlap is displayed. Save this data to the local `Theoretic-Overlap.txt`, as this information is needed for table 15 and table 17.

The figures are saved to the docker/export folder. Move them into local `figures`.

## Fig. 30c, Fig. 57a-c and Fig. 58: Shared Barcode Analysis

1. Open `.../8_libEvenness/scripts/04_BC-Distr_Groups_23_JD_Docker.R` with NotePad++ and set the `usr_limit` in line 5 to 0.005 (which determines the biological relevance). Run the code, passing the `mean` directory of either the `BC-Distr_mouse` or `_human` folder generated in step 2 of the data preparation:

```sh
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/8_libEvenness/scripts/04_BC-Distr_Groups_23_JD_Docker.R /JD/analysis/8_libEvenness/data/BC-Distr_mouse/mean

docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/8_libEvenness/scripts/04_BC-Distr_Groups_23_JD_Docker.R /JD/analysis/8_libEvenness/data/BC-Distr_human/mean
```

2. Move the generated tiff files from the export to the local `figures/BC-Distr_mouse` or `figures/BC-Distr_human` directory.

cave: Due to `jitter()` the dots will slightly differ between each reproduction of the images. However, the information will always be the same.

## Final Composition

Figure 30 is composed of the figures `Overlap_human`, `Overlap_mouse`, `Read-Distr_...` and `mouse_Group-8_...`, and the `statistics.csv` files slightly edited, e.g., height of their axis titles, in PowerPoint: `.../8_libEvenness/LibraryRandomness.pptx`.

The other overlap images are composed for Fig. 57a-c (mouse) and Fig. 58 (human).

## Table 15 and 17

Use the information saved in `.../statistics/Theoretic-Overlap.txt` during scripts for Fig. 30b. Moreover, use the information printed in the images from Fig. 30c; you find the total sequence number in the header, as well as the number of biologically relevant sequences in >= 2 mice. The column `viz. in ... mice` needs to be counted by eye, indicating how many same symbols are in how many mice.
