#############################################
# PreProcessing v1.2 JD 2016/11/29 - Docker #
#############################################

# User defined settings ------------
structureDeviation = 5 	# Allowed errors (substitution/insertion/deletion) in barcode sequence

# Barcode Sequences ----------------
mcherryBarcode = 'ATCTA..CTA..CAG..CTT..CGA..CTA..CTT..GGA..GATCT'
ceruleanBarcode = 'ATCTA..CAG..ATC..CTT..CGA..GGA..CTA..CTT..GATCT'
venusBarcode = 'ATCTA..CAC..AGA..CTT..CGA..CTA..GGA..CTT..GATCT'

####################################
######## Don't Change Below ########
####################################

version = '1.2'
csv_filename = "PreProcessing_Library.csv"

# 0. Load modules
import sys, os, regex, csv, datetime		# os -> read/write dirs/files, regex -> string comparison, csv -> .csv file handling
import tkinter as tk				# tkinter for GUI
from tkinter.filedialog import askopenfilename, askdirectory	# GUI for file/dir selection
from datetime import datetime 		# datetime -> script running time

# 1. Declaration of statistics variables
statsSeq = 0 		# Sequences in total
statsLib = 0 		# Sequences with a library ID but no barcode structure
statsBarTotal = 0 	# Sequences with a library ID & Barcode structure
statsBar = {} 		# Dictionary for subgrouping seq. w/ libr. ID & BC structure depending on their structureDeviation
for x in range(0,structureDeviation+1):
	statsBar[x] = 0
statsDumb = 0 		# Sequences w/o library ID and sequences w/ library ID but no valid barcode structure
statsLibUsed = 0 	# Library IDs found

# 2. User Interaction

# 1. User Interaction
if len(sys.argv) > 2:
    fastaFile = sys.argv[1]
    saveDir = sys.argv[2]
else:
    raise ValueError("Please provide the FASTA file path (1st arg) and respective preprocessed directory path (2nd arg).")

# Get the directory where the script is located
script_dir = os.path.dirname(os.path.realpath(__file__))

# Construct the full path to the CSV file
libraryFile = os.path.join(script_dir, csv_filename)

# 3. Load CSV Library File and load into associative array (= dictionary)
libraryIDs = {} 	# initiate dictionary

with open(libraryFile, newline='') as csvfile:		# open file
	library = csv.reader(csvfile, delimiter=',')	# read it as a csv file
	for row in library:
		libraryIDs[row[0]] = row[1]		# dict[key] = value, e.g. key = 'ITRGB_001', value = 'ttataacg' + primerPost

libraryUsed = dict.fromkeys(libraryIDs,0)			# copy dictionary w/o values to track which library IDs will be found (and how often)

# 4. Create Directory 'Sorted' and Create & Open Files for every Library ID
dirSorted = saveDir + '/Sorted'
if not os.path.exists(dirSorted):
	os.mkdir(dirSorted)

fileHandle = {}		# This directory allows direct interaction with the created library files
					# e.g. fileHandle['ITRGB_001'] represents the opened file 'ITRGB_001.fna' in the sorted folder
					# it is therefore possible to interact with it, like: fileHandle['ITRGB_001'].write('text i want to output\n')

for key in libraryIDs:
	fileHandle[key] = open(dirSorted + '/' + key + '.fna', 'w+')	# Create and open files
		# w+ stands for write (= w) which means, that if the file already exists, it will be overwritten (in contrary to 'a' = append)
		# and the '+' means, that if the file doesn't exist yet, it can be created (otherwise you would need to create empty files before)

fileDumb = 	open(dirSorted + '/Dumb.fna', 'w+')		# also create and open a Dumb file in the 'Sorted' folder

# 5. Shell Output with chosen files, directory, settings, ...
startTime = datetime.now()	# Script starting time
outputHeader = ('#########################\r\n# PreProcessing v' + version + ' JD #\r\n#########################\r\n',
				'Script started at: ' + startTime.strftime('%Y-%m-%d %H:%M:%S') + '\r\n',
				'Allowed errors in barcode sequence: ' + str(structureDeviation) + '\r\n',
				'Fasta File: ' + fastaFile,
				'Library csv file: ' + libraryFile,
				'Save dir: ' + saveDir + '\r\n')
print('\n'.join('{}'.format(x) for x in outputHeader))
print('Execution of Script can be aborted by pressing \'Ctrl + C\'.\n')

# 6. Determine lines in the FASTA File for the Progress Output
# Function
def file_length(filename):
    with open(filename) as f:
        for i, lines in enumerate(f):
            pass
    return i + 1
# Determination
fileLength = file_length(fastaFile) # Length
currLine = 0 # variable for progress

# 7. First Main Procedure
header = None
sequence = ''

with open(fastaFile) as f:		# Open Fasta File
	for line in f:				# Read line by line
		currLine += 1			# Progress variable
		if fileLength > 10000:	# Show Progress for Files with > 10000 lines
			if currLine % (round(0.0001*fileLength,0)) == 0:	# Progress Output
				print ('Progress: {0:.2f}'.format(round(100*currLine/fileLength,2)) + '%', end='\r')	# Progress Output

		if line[:1] == '>':				# If the line begins with a '>'
			if header is not None:		# if a header already exists, then the full sequence is read in and can be processed:
				matchedLibrary = None		# this variable turns True if a library ID was found
				for key in libraryIDs:		# iterate through library ID sequences
					if sequence[:8] == libraryIDs[key].upper():		# if a library ID was found at the beginning of the sequence:
						matchedLibrary = True	# mark that this sequence contains a library ID
						# search inside the sequence for the three barcodes, allwoing chosen errors ('structureDeviation')
						barcodeMatch = regex.search(r'(?e)(' + mcherryBarcode + '|' + ceruleanBarcode + '|' + venusBarcode + '){e<=' + str(structureDeviation) + '}', sequence, flags=regex.IGNORECASE)
						if barcodeMatch:	# if a barcode was found:
							currDistance = sum(barcodeMatch.fuzzy_counts) # get distance (= number of errors) from original barcode structure
							statsBarTotal += 1 # Update statistics (criteria: library ID + BC structure)
							statsBar[currDistance] += 1 # Update statistics (same criteria like before but also the subgroup [how much errors])
							libraryUsed[key] += 1 # Update the dictionary which saves how often a library ID was used
							# write the overlapping part (barcode structure & sequence) to the file
							# 1st column: the saved header, 2nd column: sequence, 3rd column: the distance
							fileHandle[key].write(header + ' ' + barcodeMatch.group(0) + ' ' + str(currDistance) + '\r\n')
						else: # if no barcode structure was found:
							#print('Library ID but no Barcode: ' + header) # DEBUGGING LINE
							fileDumb.write(header + ' ' + sequence + '\r\n') # write this sequence to the dumb file
							statsDumb += 1 # Update statistics for dumb
							statsLib += 1 # Update statistics: Library ID but no Barcode structure
						break # stop iterating through all library IDs for this sequence after a library ID was found
				if matchedLibrary is None: # if no library ID was found:
					#print('no primer: '+header) # DEBUGGING LINE
					fileDumb.write(header + ' ' + sequence + '\r\n') # write this sequence to the dumb file
					statsDumb += 1 # Update statistics for dumb
				# Reset header and sequence
				header = None 	# After all iteration through all library IDs for the sequence undefine header...
				sequence = ''	# ... and sequence
			# now a new header is being created for reading in the next sequence
			header = line.rstrip('\r\n')	# Determine it as a header
			statsSeq += 1				# And count for statistics that a sequence will follow
		else:			# line does not start with a '>', therefore it is (part of) the sequence
			sequence += line.rstrip('\r\n')	# add this line to the current sequence
											# unfortunately the structure of files is not always line 1 -> header, line 2 -> complete sequence
											# insted one sequence is distributed over for example 3 lines.
											# therefore this 'addition' of sequence is needed to work w/ the complete sequence

# 8. Close Opened Files in 'Sorted' and Delete Empty Ones
for key in fileHandle:		# Iterate through all keys of the fileHandle dictionary
	fileHandle[key].close()
fileDumb.close()

for key in libraryUsed:						# the libraryUsed dictionary saves how often a library ID was found ...
	if libraryUsed[key] == 0: 						# ... therefore if one ID was not used ...
		os.remove(dirSorted + '/' + key + '.fna')	# ... it can be removed.

# 9. Create 'Reads' Folder
dirReads = saveDir + '/Reads'
if not os.path.exists(dirReads):
	os.mkdir(dirReads)
	
# 10. Second Main Procedure
for key in libraryUsed:			# Iterate again through all keys of the libraryUsed dictionary
	if libraryUsed[key] != 0: 	# Only those which were used at least 1 time are interesting...
		statsLibUsed += 1		# Statistics Update: how many different library IDs where used
		readHandle = open(dirSorted + '/' + key + '.fna', 'r')	# Open the corresponding (just written) file from 'Sorted'
		writeHandle = open(dirReads + '/' + key + '.fna', 'w') # Create a new file with the same name in 'Reads' directory
		
		writeHandle.write('Sequence Reads Distance\r\n')	# Write the header line to the file
		
		tempDict = {}	# This dictionary will save all sequences for the current library ID as their keys
						# each key (= sequence) will get 2 values: 1st [0] -> the read count (which will be increased,
						# if the same sequences occures more often) and 2nd [1] -> the distance from the original
						# barcode structure (this value will not change of course)
						# to access for example the read count of 'ATCATC' use: tempDict['ATCATC'][0]
		
		with readHandle as f: 	# Load the 'Sorted' File
			for line in f:		# Read it line by line
				lineSplit = line.split()	# Split the line by whitespace
				sequence = lineSplit[1]			# [0] = header (e.g. '>Sequence 13') , [1] = sequence (e.g. 'AATTCC...'),
				distance = int(lineSplit[2])	# [2] = distance
				if sequence not in tempDict: 	# Look whether a sequence already exisits inside the dictionary
					tempDict[sequence] = [1, distance]	# if not: add it to the dictionary, set reads = 1 and copy distance
				else:
					tempDict[sequence][0] += 1 # if yes: higher the readcount of the sequence by 1
		
		# After every line was read:
		for i in tempDict:	# iterate through all unique sequences for this library ID (represented in keys of tempDict)
			# write the sequence (i), their read count (tempDict[i][0]) and their distance (tempDict[i][1]) into 'Read' file
			writeHandle.write(i + ' ' + str(tempDict[i][0]) + ' ' +  str(tempDict[i][1]) + '\r\n')
		
		# Close 'Sorted' and 'Read' File for this library ID and continue iterate through next library ID
		readHandle.close()
		writeHandle.close()

# 11. Shell Output: Statistics
print ('Progress: 100.00%\n')
print('##############\n# Statistics #\n##############')
# Calculate Running Time
endTime = datetime.now()-startTime
if endTime.days > 0:
	runTime = str(endTime.days) + ' days, ' + str(endTime.seconds//3600) + ' hours, ' + str((endTime.seconds%3600)//60) + 'minutes, ' +  str((endTime.seconds%3600)%60) + 'seconds.\r\n'
else:
	if endTime.seconds >= 3600:
		runTime = str(endTime.seconds//3600) + ' hours, ' + str((endTime.seconds%3600)//60) + 'minutes and ' +  str((endTime.seconds%3600)%60) + 'seconds.\r\n'
	else:
		if endTime.seconds >= 60:
			runTime = str(endTime.seconds//60) + ' minutes and ' + str(endTime.seconds%60) + ' seconds.\r\n'
		else:
			runTime = str(endTime.seconds) + ' seconds.\r\n'

# Generate Footer information
outputFooter = ('\r\nRunning time: ' + runTime,
				str(statsSeq) + ' sequences in total',
				' - ' + str(statsBarTotal) + ' (' + str(round(100*statsBarTotal/statsSeq,2)) + '%) contain a valid library ID and have a barcode structure <= ' + str(structureDeviation) + ' errors')
for x in range(0,structureDeviation+1):
	outputFooter = outputFooter + ('   * ' + str(round(100*statsBar[x]/statsBarTotal,2)) + '% with ' + str(x) + ' errors',)
outputFooter = outputFooter + (' - ' + str(statsDumb) + ' (' + str(round(100*statsDumb/statsSeq,2)) + '%) allocated to dumb',
								'   * ' + str(round(100*statsLib/statsDumb,2)) + '% of them contain a valid library ID but no barcode structure',
								'\r\nFound a valid barcode structure for ' + str(statsLibUsed) + ' of the ' + str(len(libraryUsed)) + ' library IDs')
# Print to shell
print('\n'.join('{}'.format(x) for x in outputFooter))

# 12. Statistics Output as Text File (.txt) in chosen Save Dir
writeStatistics = open(saveDir + '/Statistics.txt', 'w+')
writeStatistics.write('\r\n'.join('{}'.format(x) for x in outputHeader))
writeStatistics.write('\r\n'.join('{}'.format(x) for x in outputFooter))
writeStatistics.close()

input("\nPress \'Enter\' to close ...")