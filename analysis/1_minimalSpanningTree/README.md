# Minimal Spanning Tree
## Data
Preprocessed data (max. deviation = 5) without further clustering, filtering, or merging.
Samples: _ITRGB_084_, __85_, and __86_ from the _1602_ run (= technical triplicate of a one-barcode sample containing only `ATCTATCCAGAAATCCTCTTTGCGACGGGAGACTAACCTTTTGATCT`).

I used Figure __85_ in my main thesis text.

## Instructions:
1.	Create a local `data`, `figures`, and `statistics` folders (e.g., `.../analysis/1_minimalSpanningTree/data`).
   
2.	Copy samples _ITRGB_084_, __085_, and __86_ from `./data/preprocessed/run1/Reads` to the local Data folder.
   
3.	Prepare the data for the MST analysis by running the following for the samples _ITRGB_084_, __085_, and __86_ from `./data/preprocessed/run1/Reads` (1st argument):

```sh
docker run -it --rm -v C:/your/path:/JD py_env python /JD/data/barcode_data/analysis/1_minimalSpanningTree/MST-Prep_11_JD_Docker.py /JD/data/barcode_data/analysis/1_minimalSpanningTree/data/ITRGB_084.fna
```

(Repeat for the other to files)

   -> new files are created (e.g., _MST_ITRGB_085.fna_) in the local data directory.

4.	Create the images using the [MST_12_JD_Docker.R](MST_12_JD_Docker.R) script and provide the respective file created in the previous step as the first argument (e. g. _data/MST_ITRGB_085.fna_)


```sh
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/1_minimalSpanningTree/MST_12_JD_Docker.R /JD/analysis/1_minimalSpanningTree/data/MST_ITRGB_084.fna
```

(Repeat for the other files)

   -> a .tiff file is saved in the export directory (`./docker/export`). Move those .tiff files to the local figures directory.

5.	For the statistics (how many sequences and percentages of reads, ...) adjust line 1 in [MST_Stats_Docker.R](MST_Stats_Docker.R) to set the correct csv delimiter (depending on your local OS language and, e.g., MS Office language). Run the following:


```sh
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/1_minimalSpanningTree/MST_Stats_Docker.R /JD/analysis/1_minimalSpanningTree/data
```

=> The script creates an `MST_Stats.csv` file in the `/docker/export` directory. Move it to the local statistics folder. Copy everything inside MST_Stats.csv into the yellow area in worksheet _Raw_ in `Statistics.xlsx`. The formula inside _Formatted_ summarizes the relevant lines and creates also a table, which has the format of the final Table 14 of my thesis.

| Dist | Dev | Seq_M | Seq_SD | R_abs_M | R_abs_SD | R_rel_M | R_rel_SD |
|------|-----|-------|--------|---------|----------|---------|----------|
|    0 |   0 |     1 |      0 |   43277 |    10244 |  77.23% |    0.71% |




cave: The plot might minimally differ between different executions of the same sample because the used _jitter()_ effect and its random component. Nevertheless, all relevant information (connections, shell positions, colors) is identical.


## Explanation of the code:
### Python code:
1.	The script will compare each sequence in the file nucleotide-wise towards the known sequence with the regex module and saves the individual error profile for each sequence in a new .fna file (_MST_ITRGB_085.fna_)

2.	The type of error is determined by comparing the rest of the string, e.g.

a.	Deletion:		Compare[x] = Pattern[x+1]

i.	Pattern = ABCDE,	Compare = ABDE

ii.	While comparing each position (1. A == A, 2. B == B, ...) at position 3 C != D

iii.	The substring from the current position of compare (DE) is tested to be the same like the substring from the current position + 1 in the Pattern (DE)

iv.	If this is true (like here), it’s a deletion

b.	Substitution:		Compare[x+1] = Pattern[x+1]

c.	Insertion:		Compare[x+1] = Pattern[x]

3.	Up to 9 error types and positions are saved for each sequence. Further the distance towards the reference sequence is saved as _DistRef_.

### R code:
1.	A “parent” is searched for every sequence, which means that the error profile of the current sequence is compared to all sequences, that have less distance towards the reference sequence (lower shells). If a sequence can be found, the ID of the sequence (“Closest”) and the distance (“ClosestDist”) are saved

2.	The angle calculation of the first shell is 360, for the next shells daughters can deviate up to -15/+15° from the parent.

3.	Size can be adjusted under “6.2 Size” -> currently it’s the 4th root of a sequence’s reads
