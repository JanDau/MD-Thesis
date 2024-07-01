# MD-Thesis

Within this GitHub repository I share my Python and R scripts which I used in my MD thesis as well as the respective version/packaging environment captured in Docker images. I recommend using [NotePad++](https://notepad-plus-plus.org/downloads/) for minor code adaptions, which will likely be necessary as you have to adapt the path to your repective local directories.

## Table of Contents

- [1. Docker Installation](#1-docker-installation)
- [2 Preprocessing](#2-preprocessing)
- [License](#license)
- [Contact](#contact)

## 1. Docker Installation
As my scripts were written in the past, the whole environment (operating system, Python, and R version, as well as their included packages and versions) is nowadays deprecated, and scripts won’t work with the current versions, which is common in all programming languages. I, therefore, set up two Docker environments (py_env and r_env) that hold the respective required versions; thus, my scripts can be executed from any machine, regardless of their local environment. Not even Python or R needs to be installed on the host machine; Docker Desktop creates a virtual environment and holds everything within the respective image.

### 1.1 Download
Follow the instructions on [https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/).

### 1.2 (Optional) Adjust Hardware Resources
You can limit the hardware resources Docker can access on your host machine by creating or editing the “.wslconfig” if you use wsl2. Otherwise, it will use the full capacities, if possible. Windows users will likely need to create that file in their user directory (C:/user/%username%/.wslconfig) and paste (and adapt) the following:

```sh
# Settings apply across all Linux distros running on WSL 2
[wsl2]

# Limits VM memory. For example, if the computer has 64 GB, you may use 32 GB. This can be set as whole numbers using GB or MB.
memory=32GB 

# Sets the number of virtual processors to use for the VM. Use half of your core number.
processors=6

# Sets the amount of swap storage space; default is the double amount of available RAM
swap=64GB
```

You need to restart the machine or at least WSL and Docker for changes to have an effect. Quit Docker Desktop. Execute
```sh
wsl --shutdown
```
Restart Docker Desktop. You can check whether it worked via
```sh
docker run --rm ubuntu nproc
```
and for the memory
```sh
docker run --rm ubuntu free -m
```

### 1.3 Build the Docker Images
Required Dockerfiles are found at ./dockerfiles. The Python environment hasn't many dependencies, though the R has plenty of required packages. It is critical to install them in the designated order (corresponding `r_package_list.txt`, which is automatically loaded during the building process), as the remotes package, which is necessary to install deprecated package versions, cannot install respective (deprecated, non pre-compiled) dependencies. You don't need to have both environments actively running. Instead, each script will create its instance of the environment and will close its instance after fulfilling its job.

#### Python
Download the [py_env Dockerfile](/dockerfiles/py_env/Dockerfile).
```sh
cd C:/your/path/to/py_env_dockerfile
docker build -t py_env .
```
(this may take a while)

#### R
Download the [r_env Dockerfile](/dockerfiles/r_env/Dockerfile) and the [r_package_list](/dockerfiles/r_env/r_package_list.txt). Ensure that boths files are in the same directory.
```sh
cd C:/your/filepath
docker build -t r_env .
```
(may take even longer)

### 1.4 Explanations on Path Adaptations
In all upcoming commands, you may need to adapt the respective paths. The general structure of the command line is
```sh
docker run -it --rm -v C:/your/local/path:/your/virtual/path docker_image_name script (args)
```
whereas `docker run -it --rm -v` remains identical at all times, `C:/your/local/path` should be the main directory of your experiment, which contains all the data. This directory and its subdirectories is provided to the Docker container (virtual environment) to the path that follows after the `:`, e.g. `/your/virtual/path`, which could simply be `/JD`. The docker_image_name is either `py_env` or `r_env` if you named them identical as I explained in [1.3 Build the Docker Images](1-3-build-the-docker-images). `script` is the (virtual) path to the script you want to execute and `args` is optional and can be one or more arguments, depending on the script.

In the following, we assume, that my data is found at `C:/your/path` and the main directory in my Docker environment is `/JD`.

## 2. Preprocessing
### 2.1 Converting FASTQ into FNA (FASTA)
Data provided as .fastq files need to be converted into .fna files, as their additional information about the quality of the sequences is not used in my scripts, in fact my scripts will only work if the data is supplied in the FNA (FASTA) format. 
The custom Python script `FASTQ-Convert_10_JD_Docker.py` will transform the .fastq files and save the corresponding .fna file in the respective directory.

```sh
docker run -it --rm -v C:/your/path:/JD py_env python /JD/scripts/1_preprocessing/FASTQ-Convert_10_JD_Docker.py /JD/sample_data/raw.fastq
```

### 2.2 Create Directory Structure
If you have multiplexed data, e.g. having 100 different so-called library/index sequences, where each library/index sequences was linked to a specific sample during pre-sequencing PCR amplification, the following script demultiplexes the data.
Create a local "preprocessed" directory, where to save the demultiplexed-data, e.g. "/data/preprocessed". If you want to analyze multiple runs, create subfolders for every run, e.g., "/data/preprocessed/run1".

### 2.3 Running Preprocessing
You may want to edit the maximum deviation from the stringent structure, for sequences to be included in the preprocessed files. You find the setting in line 6 in `/scripts/1_preprocessing/PreProcessing_12_JD_Docker.py`. I used a maximum deviation of 5.
Make sure that `PreProcessing_Library.csv` is edited to your library/index sequences is located in the same directory as `PreProcessing_12_JD_Docker.py`.

```sh
docker run -it --rm -v C:/your/path:/JD py_env python /JD/scripts/1_preprocessing/PreProcessing_12_JD_Docker.py /JD/data/raw_data/data.fna /JD/data/preprocessed/run1/
```

The statistics at the end of the code execution are automatically saved as a text file in the respective preprocessed directory. You can execute the scripts in parallel using different shells. It might take a couple of hours, depending on your hardware.
All sequences with up to 5 errors were now recovered from the raw data set.

## 3. Filtering of samples by read distribution (“Run Indices”) 
Reads of a run are not equally distributed between all samples \ index sequences (ITRGB_001, … ITRGB_100). Some samples are slightly overrepresented, assuming an equal distribution (expected reads). In contrast, others do not have any reads, e.g., in run 1505 ITRGB_002 and ITRGB_003, which is intended in these cases (mock controls). Samples with only very few sequences and minor read counts hamper the analysis of the relative composition. E. g. suppose a sample contains only one sequence with one read while all its related samples (e.g., different time points of peripheral blood samples) have>5.000 reads. In that case, it does not represent the real sample and should be excluded from the analysis. As a threshold, I decided to exclude samples that fail to exceed the lower 95% CI of the reads mean (= Run Index <0.127). By this, only very few samples were excluded, mainly containing one sequence with one read.

1.	Open “…\scripts\1_preprocessing\Run-indices_11_JD_Docker.R” with NotePad++.
2.	Adjust the variables “TotalReads”, “PercDumb”, and “UsedBarcodes” at the beginning of the code to the information given in the statistics file of every run. E. g. for run 1505:
o	TotalReads is the number in the following line: “6240802 sequences in total”.
o	PercDumb is the percentage in this line: “1857678 (29.77%) allocated to dumb”.
o	UsedBarcodes information is at the end: “Found a valid barcode structure for 98 of the 100 library IDs”.
6240802	29.77	98
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/data/barcode_data/scripts/1_preprocessing/Run-indices_11_JD_Docker.R /JD/data/barcode_data/data/preprocessed/1505/Reads

1881377	59.09	99
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/data/barcode_data/scripts/1_preprocessing/Run-indices_11_JD_Docker.R /JD/data/barcode_data/data/preprocessed/1507/Reads

3792322	70.96	100
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/data/barcode_data/scripts/1_preprocessing/Run-indices_11_JD_Docker.R /JD/data/barcode_data/data/preprocessed/1509/Reads

5474484	39.19	100
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/data/barcode_data/scripts/1_preprocessing/Run-indices_11_JD_Docker.R /JD/data/barcode_data/data/preprocessed/1602/Reads

Two .csv files with statistics are created at the path passed as the first argument (the English and German versions, as they have different delimiter settings). They contain the “RunIndex” in the fourth column.
Manually exclude samples that do not fulfill run index criteria by moving them from, e.g.. “…\data\preprocessed\1505\Reads” to “…\data\preprocessed\1505\Reads_excluded”). 
In the four runs, only a couple were excluded due to a lower run index than 0.127:
•	Run 1505: ITRGB_001, _016, _031
•	Run 1507: ITRGB_010, _040
Theoretically, an underperforming Illumina primer used for multiplexing could also be the reason for a low run index. I fused all four statistics files to detect it and calculated means and standard deviations for each of the 100 primers and the overall mean and SD (“…\data\preprocessed\Primer-Performance.xslx”). Only the 95% CI of primer ITRGB_001 includes values lower than the overall 95% CI; therefore, it might be underperforming (visualized “…\data\preprocessed\Primer-performance.tiff”). However, run “1505” contained a non-template control, and (unfortunately) one sequence with one read was returned for this BC, leading to a higher SD. I assume all primers work fine.
 

4. Rough estimation of barcode library size
This step is necessary to determine the data set's maximum allowed deviation (which corresponds to the cluster distance). Estimation needs to be done for both cohorts.
a) Chapman estimation based on plasmid triplicates and preTX samples
The path after Rscript needs to lead to the Chapman-Estimation_Docker.R file (“--file argument”). The first (real) argument is the path to Chapman-Estimation_Sample-Allocation.csv, while the 2nd arg is the preprocessed directory.
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/data/barcode_data/scripts/2_maxDeviation/Chapman-Estimation_Docker.R /JD/data/barcode_data/scripts/2_maxDeviation/Chapman-Estimation_Sample-Allocation.csv /JD/data/barcode_data/data/preprocessed

	A .csv file holding all Chapman estimations is created at “./docker/export/Chapman-Estimation_Results.csv”. Move the file to ../2_maxDeviation/.
b) Estimation based on the gain of new unique sequences (barcode saturation)
Murine cohort
Images are created with the BC-Saturation-Estimation_Docker.R script. The first arg (Sample-Allocation.csv) holds the information about which samples of the murine cohort can be found at which run and multiplexing ID. The second arg is the preprocessed directory.
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/data/barcode_data/scripts/2_maxDeviation/BC-Saturation-Estimation_Docker.R /JD/data/barcode_data/scripts/Sample-Allocation.csv /JD/data/barcode_data/data/preprocessed

human cohort
The 1st arg is changed to (Sample-Allocation_human.csv) for the human cohort.
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/data/barcode_data/scripts/2_maxDeviation/BC-Saturation-Estimation_Docker.R /JD/data/barcode_data/scripts/Sample-Allocation_human.csv /JD/data/barcode_data/data/preprocessed

	.tiff files are created at “./docker/export/. They visualize the regression, including its limit value (s), which surrogates the library size(s). Move the files to ../2_maxDeviation/.
c) Defining the sizes
Data from a) and b) was manually transferred into “Library-Size.xslx” and separated by their vector (either mCherry in the murine cohort or Cerulean in the human cohort). To be more conservative regarding the maximum allowed deviation, I took the maximum estimated value for each plasmid, which is 155,648 for mCherry and 85,483 for Cerulean.





5. Determination and application of deviation thresholds
The barcode library sizes of 4. are inserted into line 2 (userPoolsize) of “../2_maxDeviation/Return-Deviation-Threshold_Docker.py”. An applied type I error of 2.5% results in a deviation threshold of 2 for both cohorts.
docker run -it --rm -v C:/your/path:/JD py_env python /JD/data/barcode_data/scripts/2_maxDeviation/Return-Deviation-Threshold_Docker.py
	Both result in a recommended Deviation threshold of 2.
(cave: sizes between ~15,000 and 190,000 will result in a CD of 2 if the type I error is 2.5%)
Open “../2_maxDeviation/Filter_Deviation_10_JD_Docker.py” with NotePad++ change line 6 to userMaxDev = 2. Run the script while passing either whole directories as arguments (all files will be treated) or specific (multiple) files (as separate arguments). In my case, I selected the preprocessed “Reads” directory of every run separately, which creates a new folder “MaxDev2” inside each “Reads” folder, e.g., “./data/barcode_data/data/preprocessed/1505/Reads/MaxDev2”. 

docker run -it --rm -v C:/your/path:/JD py_env python /JD/data/barcode_data/scripts/2_maxDeviation/Filter_Deviation_10_JD_Docker.py /JD/data/barcode_data/data/preprocessed/1505/Reads

docker run -it --rm -v C:/your/path:/JD py_env python /JD/data/barcode_data/scripts/2_maxDeviation/Filter_Deviation_10_JD_Docker.py /JD/data/barcode_data/data/preprocessed/1507/Reads

docker run -it --rm -v C:/your/path:/JD py_env python /JD/data/barcode_data/scripts/2_maxDeviation/Filter_Deviation_10_JD_Docker.py /JD/data/barcode_data/data/preprocessed/1509/Reads

docker run -it --rm -v C:/your/path:/JD py_env python /JD/data/barcode_data/scripts/2_maxDeviation/Filter_Deviation_10_JD_Docker.py /JD/data/barcode_data/data/preprocessed/1602/Reads


6. Allocation of samples towards mice and cohort
Manually create a “mouse” and “human” directory inside “./data/barcode_data/data”.
Open “../3_sampleAllocation/Sample-Allocation_12_JD_Docker.py” with NotePad++ and make sure that userMaxDev in line 4 is set to 2. 
When calling the script, pass the following arguments:
•	1st arg: Sample-Allocation.csv (same as in Step 4, found at “./data/barcode_data/scripts/Sample-Allocation.csv”
•	2nd arg: “preprocessed” directory (“./data/barcode_data/data/preprocessed”)
•	3rd arg: Saving path
During code execution, you need to pass the delimiter used in the Sample-Allocation.csv file:
English → ,	German → ;	(in my case → ,)

Mouse:
docker run -it --rm -v C:/your/path:/JD py_env python /JD/data/barcode_data/scripts/3_sampleAllocation/Sample-Allocation_12_JD_Docker.py /JD/data/barcode_data/scripts/Sample-Allocation.csv /JD/data/barcode_data/data/preprocessed /JD/data/barcode_data/data/mouse

Human:
docker run -it --rm -v C:/your/path:/JD py_env python /JD/data/barcode_data/scripts/3_sampleAllocation/Sample-Allocation_12_JD_Docker.py /JD/data/barcode_data/scripts/Sample-Allocation_human.csv /JD/data/barcode_data/data/preprocessed /JD/data/barcode_data/data/human

	All samples belonging to one individual are collected and named in the corresponding folder inside “./data/barcode_data/data/mouse”.

7. Mouse-Library-based clustering
7.1 Create Individual Libraries
Open “../4_CSR/Clust-Lib_Create_24_JD_Docker.py” with NotePad++ and ensure that userFixedCD in line 6 is set to 2. The other two variables can be ignored.
Call the script supplying a directory or individual file(s) as separate arguments.
docker run -it --rm -v C:/your/path:/JD py_env python /JD/data/barcode_data/scripts/4_CSR/Clust-Lib_Create_24_JD_Docker.py /JD/data/barcode_data/data/mouse/preTX_SF-3

docker run -it --rm -v C:/your/path:/JD py_env python /JD/data/barcode_data/scripts/4_CSR/Clust-Lib_Create_24_JD_Docker.py /JD/data/barcode_data/data/mouse/preTX_SF-3T

docker run -it --rm -v C:/your/path:/JD py_env python /JD/data/barcode_data/scripts/4_CSR/Clust-Lib_Create_24_JD_Docker.py /JD/data/barcode_data/data/mouse/preTX_SF-T
…

	A library file is created within the corresponding directory.

Repeat for all 18 individuals of the murine and all 18 of the human cohort. You may run the script in parallel by just opening another command line.

7.2 Apply Libraries
Call “../4_CSR/Clust-Lib_Use_23_JD_Docker.py”, supplying an individual directory as an argument, e.g., “./data/barcode_data/data/human/SF-3#1.” The respective library file is recognized automatically; otherwise, the script stops.

docker run -it --rm -v C:/your/path:/JD py_env python /JD/data/barcode_data/scripts/4_CSR/Clust-Lib_Use_23_JD_Docker.py /JD/data/barcode_data/data/human/SF-3#1
…

	The clustered files are located inside “…/UsedLibrary” in the respective folder.

Repeat for all individuals of both cohorts.



8. Stringency filtering
Open “…/4_CSR/Filter_Deviation_Multiple_11_JD_Docker.py” with NotePad++. Set line 6 to 0 (usr_dev = 0) and line 7 to “C” (usr_filter = “C”).
Run …
docker run -it --rm -v C:/your/path:/JD py_env python /JD/data/barcode_data/scripts/4_CSR/Filter_Deviation_Multiple_11_JD_Docker.py /JD/data/barcode_data/data/mouse
… for the mouse cohort, and …
docker run -it --rm -v C:/your/path:/JD py_env python /JD/data/barcode_data/scripts/4_CSR/Filter_Deviation_Multiple_11_JD_Docker.py /JD/data/barcode_data/data/human
… for the human cohort.
	clustered files are being filtered for the stringent structure and saved inside a new folder “MaxDev0” in each animal directory, e.g., “…\Mouse\SF-T#1\UsedLibrary\MaxDev0\”.

9. Rough estimation of how much overlap is (un)likely between animals
This information is needed in the following step for the read threshold. Theoretically, a certain degree of overlap between different mice is statistically likely due to the limited barcode library size. However, sequences shared by all mice are more likely to be contaminations in all samples with only minor reads. This step determines the cut-off. The mode value of the sequences shared by more than the determined number of animals will be used as the read threshold.
9.1 Merge clustered and stringency-filtered (CS) samples
First, all mice's clustered and stringency-filtered (CS) samples must be merged. For this, open “../4_CSR/Merge_Animal_Multiple_12_JD_Docker.py” with NotePad++. Set usr_filter to “CS” at line Run… 
docker run -it --rm -v C:/your/path:/JD py_env python /JD/data/barcode_data/scripts/4_CSR/Merge_Animal_Multiple_12_JD_Docker.py /JD/data/barcode_data/data/mouse
… for the mouse cohort, and …
docker run -it --rm -v C:/your/path:/JD py_env python /JD/data/barcode_data/scripts/4_CSR/Merge_Animal_Multiple_12_JD_Docker.py /JD/data/barcode_data/data/human
… for the human cohort.
	CS-merged files are generated in the cohort directory.
9.2 Estimate a new barcode library size
Next, a new barcode library size must be estimated based on the CS files. This is based on the three preTX files for each cohort. For the mouse cohort run …
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/data/barcode_data/scripts/4_CSR/Chapman-Estimation_Merged-CS_Docker.R /JD/data/barcode_data/data/mouse
and for the human cohort…
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/data/barcode_data/scripts/4_CSR/Chapman-Estimation_Merged-CS_Docker.R /JD/data/barcode_data/data/human
	The library size is printed in the RStudio console:
o	Murine: 64,117 (+/- 1203)
o	Human: 79,103 (+/- 983)
9.3 Calculate the sequence overlap
Run… 
docker run -it --rm -v C:/your/path:/JD py_env python /JD/data/barcode_data/scripts/4_CSR/BC-Distribution_21_JD_Docker.py /JD/data/barcode_data/data/mouse
… for the mouse cohort. A couple of .csv files are exported to “./docker/export”. Create a subdirectory “mouse_CS” and move those files into it. Then, do a similar for the human cohort…
docker run -it --rm -v C:/your/path:/JD py_env python /JD/data/barcode_data/scripts/4_CSR/BC-Distribution_21_JD_Docker.py /JD/data/barcode_data/data/human

The “BC-Distr_Stats_” files contain statistics on how often a specific barcode (column B) occurs in how many other animals (column A). Further, the detailed sequence information and read count within each particular mouse is exported for each shared group, e.g., sequences shared by two animals are found in “BC-Distr_Group_2_....csv).
9.4	Compare theoretic and real overlap
Open “../4_CSR/Overlap-Comparison_Docker.R” with NotePad++ and adapt the usr_size in the first line to the respective size depending on the cohort you are analyzing (Mouse: 64117, Human: 79103).
Run …
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/data/barcode_data/scripts/4_CSR/Overlap-Comparison_Docker.R /JD/docker/export/mouse_CS
… for the murine cohort and for the human cohort…
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/data/barcode_data/scripts/4_CSR/Overlap-Comparison_Docker.R /JD/docker/export/human_CS
	a .tiff image is created, showing the differences between theoretical and real overlap. If an intersection occurs, it is marked by a vertical line.
	In the murine cohort, the intersection occurs at nine mice.
In the human cohort, no intersection occurs. I took five mice as the threshold.
9.5	Calculate the mode
This script now takes all BC-Distr_Group_....csv files from a cohort higher than the given threshold as the 2nd argument, which is 9 for the Mouse cohort and 5 for the Human cohort.
Mouse:
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/data/barcode_data/scripts/4_CSR/Mode_Docker.R /JD/docker/export/mouse_CS 9

Human:
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/data/barcode_data/scripts/4_CSR/Mode_Docker.R /JD/docker/export/human_CS 5

The mode is printed in the console: 	Mouse cohort: 2	Human cohort: 1
Lastly, you may move the files from “./docker/export” to the “../4_CSR” directory.

10. Read filtering
Open ”../4_CSR/Filter_Reads_Multiple_10_JD_Docker.py” with NotePad++.  Set userThresh to 2 (Murine cohort) or 1 (Human cohort). userSkip allows to skip (not apply the read filter) highly diverse (preTX) samples if the criteria are fulfilled, e.g., the “mean” read count is <= 8. Set usr_filter to “CS”, as you want to apply the filter on the clustered and stringency-filtered files. usr_replace does not need to be adapted.
Run 
docker run -it --rm -v C:/your/path:/JD py_env python /JD/data/barcode_data/scripts/4_CSR/Filter_Reads_Multiple_10_JD_Docker.py /JD/data/barcode_data/data/mouse
for the murine and …
docker run -it --rm -v C:/your/path:/JD py_env python /JD/data/barcode_data/scripts/4_CSR/Filter_Reads_Multiple_10_JD_Docker.py /JD/data/barcode_data/data/human
for the human cohort.
	a new folder “MinReads3” (or MinReads2 for the human cohort) is created in each animal directory, e.g.…\Mouse\SF-T#1\UsedLibrary\MaxDev0\MinReads3”.


11. Reallocate for easier access
Directing towards, e. g. “…\Human\SF-T#1\UsedLibrary\MaxDev0\MinReads2\” is cumbersome; hence files can be copied to “…\Human_CSR\” by running “../5_Misc/Copy-from-CSR_Docker.py”. First, open it with NotePad++ and adapt lines 5 and 6. Afterward, run it and select the cohort directory, e.g., “…\Human\”.
For the Mouse cohort, set lines 5 and 6 to 
     	'R': "MinReads3"} 
usr_cohort = "mouse"

And run
docker run -it --rm -v C:/your/path:/JD py_env python /JD/data/barcode_data/scripts/5_Misc/Copy-from-CSR_Docker.py /JD/data/barcode_data/data/mouse

For the human cohort, set lines 5 and 6 to
     	'R': "MinReads2"} 
usr_cohort = "human"
And run
docker run -it --rm -v C:/your/path:/JD py_env python /JD/data/barcode_data/scripts/5_Misc/Copy-from-CSR_Docker.py /JD/data/barcode_data/data/human

12. Merge animals
To merge the CSR-filtered files, open “../5_Misc/Merge_Animal_Multiple_11_JD_Docker.py”. As we reallocated the files, the usr_filter in line 5 can be set to empty (usr_filter = “”). Run the script. Select the CSR-cohort directory, e.g.. “…\Human_CSR\”.
docker run -it --rm -v C:/your/path:/JD py_env python /JD/data/barcode_data/scripts/5_Misc/Merge_Animal_Multiple_11_JD_Docker.py /JD/data/barcode_data/data/mouse_CSR

docker run -it --rm -v C:/your/path:/JD py_env python /JD/data/barcode_data/scripts/5_Misc/Merge_Animal_Multiple_11_JD_Docker.py /JD/data/barcode_data/data/human_CSR

13. Merge replicates
For clonal development figures, only replicates of the respective animals need to be merged (not all samples). For this, run “…/5_Misc/Merge_Replicates_Multiple_11_JD_Docker.py
docker run -it --rm -v C:/your/path:/JD py_env python /JD/data/barcode_data/scripts/5_Misc/Merge_Replicates_Multiple_11_JD_Docker.py /JD/data/barcode_data/data/mouse_CSR

docker run -it --rm -v C:/your/path:/JD py_env python /JD/data/barcode_data/scripts/5_Misc/Merge_Replicates_Multiple_11_JD_Docker.py /JD/data/barcode_data/data/human_CSR

	A new folder, “Merged,” is created in each animal directory containing the merged replicates.

14. Generation of final figures
Explanation of how to create final figures and additional filtering/clustering steps are explained in the respective readme file in the figure subdirectories found at “…\Analysis\”.


## License
This project is licensed under the MIT License. See the `[LICENSE](LICENSE)` file for details.

## Contact
If you want to contact me, you can reach me by [jannik.berlin@gmail.com](jannik.berlin@gmail.com).
