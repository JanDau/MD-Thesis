# Polymerase Comparison
## Data
Preprocessed data (max. deviation = 5) without any further clustering, filtering, or merging.
Samples from run 1507: 

-	_ITRGB_087_: 6-Barcode Sample equally distributed, myTaq

-	_ITRGB_088_: 6-Barcode Sample equally distributed, MyFi

-	_ITRGB_089_: 6-Barcode Sample gradually diluted, myTaq

-	_ITRGB_090_: 6-Barcode Sample gradually diluted, myFi


## Instructions:

1.	Create local `data` and `figures` folders (e.g., `.../analysis/2_polymeraseComparison/data`). 

2.	Copy samples _ITRGB_087_, __088_, __089_, and __90_ from `.../data/preprocessed/run-name/Reads` to the local data folder.

3.	Run the following:

```sh
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/2_polymeraseComparison/Polymerase_Comparison_Docker.R /JD/analysis/2_polymeraseComparison/data
```

   -> Three .tiff files are saved in the local figures directory
