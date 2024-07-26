###########################################
# Use Library v2.3 JD 2021/01/08 - Docker #
###########################################
						
####################################
######## Don't Change Below ########
####################################

version = '2.3'

# 0. Load modules
import csv, regex, re, os, math					# regex for Levenshtein distance, os for writing files, math for n-faculty
# from tkinter.filedialog import askopenfilename, askopenfilenames	# GUI for file selection
from operator import itemgetter					# for sorting
from datetime import datetime 		# datetime -> script running time			# for sorting
import argparse, sys

# 1. Functions
def runningTime (startTime, endTime):
	dTime = endTime-startTime
	if dTime.days > 0:
		runTime = str(dTime.days) + ' day(s), ' + str(dTime.seconds//3600) + ' hour(s), ' + str((dTime.seconds%3600)//60) + ' minute(s), ' +  str((dTime.seconds%3600)%60) + ' second(s).\n'
	else:
		if dTime.seconds >= 3600:
			runTime = str(dTime.seconds//3600) + ' hour(s), ' + str((dTime.seconds%3600)//60) + ' minute(s) and ' +  str((dTime.seconds%3600)%60) + ' second(s).\n'
		else:
			if dTime.seconds >= 60:
				runTime = str(dTime.seconds//60) + ' minute(s) and ' + str(dTime.seconds%60) + ' second(s).\n'
			else:
				runTime = str(dTime.seconds) + ' second(s).\n'
	return runTime

# 2. User Interaction
# # Initialize GUI
# root = tkinter.Tk() 	# Initialize
# root.withdraw()			# Hide window

# # GUI
# files = askopenfilenames(defaultextension='.fna', filetypes=[('.fna Files', '.fna')], title='Choose .fna files')
# files = list(files)		# Saves file paths as list to iterate through them


def get_fna_files_in_directory(directory_path):
    """Get all .fna files located directly in the specified directory."""
    files_to_process = []
    for item in os.listdir(directory_path):
        full_path = os.path.join(directory_path, item)
        if os.path.isfile(full_path) and full_path.endswith('.fna'):
            files_to_process.append(full_path)
    return files_to_process

def construct_expected_filename(directory_path):
    """Construct the expected file name based on the directory name."""
    # Extract the last part of the directory path
    last_dir_name = os.path.basename(os.path.normpath(directory_path))
    # Construct the file name
    expected_file_name = f"Lib-{last_dir_name}.fna"
    return expected_file_name
    
# Initialize the parser
parser = argparse.ArgumentParser(description='Check for a specific .fna library file in the specified directory.')
parser.add_argument('directory', type=str, help='The path to the directory')

# Parse the argument
args = parser.parse_args()

# Get the .fna files in the specified directory
files = get_fna_files_in_directory(args.directory)

# Construct the expected file name
expected_file_name = construct_expected_filename(args.directory)
usrLib = os.path.join(args.directory, expected_file_name)
usrLibAlt = os.path.join(args.directory, "Lib.fna")

# Check if a library file exists
if usrLib not in files:
	if usrLibAlt not in files:
		print(f"Error: Neither {expected_file_name}, nor Lib.fna was not found in the specified directory.")
		sys.exit(1)  # Exit the script with an error code
	else:
		usrLib = usrLibAlt

usrFiles = [file for file in files if file != usrLib]
# usrFiles = files
# fileNames = [os.path.basename(x) for x in files]
# r = re.compile(".*(Lib).*")
# fileNameLib = [m.group(0) for l in fileNames for m in [r.search(l)] if m]
# fileLibID = fileNames.index(''.join(fileNameLib))
# usrLib = files[fileLibID]

# if usrLib != '':
	# usrFiles.remove(usrLib)
# else:
	# usrLib = askopenfilename(defaultextension='.fna', filetypes=[('.fna Files', '.fna')], title='Select .fna library file')

dirSave = os.path.split(files[0])[0] + '/UsedLibrary'		
if not os.path.exists(dirSave):
	os.mkdir(dirSave)

# 3. Shell Output with chosen files, directory, settings, ...
startTime = datetime.now()	# Script starting time
outputHeader = ('#######################\n# Use Library v' + version + ' JD #\n#######################',
				'Script started at: ' + startTime.strftime('%Y-%m-%d %H:%M:%S') + '\n',
				'Save Path: ' + dirSave + '\n')
print('\n'.join('{}'.format(x) for x in outputHeader))
print('Execution of Script can be aborted by pressing \'Ctrl + C\'.\n')
print('---------------------------------')

# Load Library in Dictionary
dictLibrary = {}					# every existing sequence will be a key, the assigned value is the sequence to cluster to
print('\nReading library: ...', end='\r')
with open(usrLib) as l:
	for row in l:
		if row.startswith('Sequence'):	# ... skip the header row ...
			continue
		lineSplit = row.split()	# split the lines by whitespace (because the structure is e.g. 'AATTCC ATTTC 0 1')
		dictLibrary[lineSplit[0]] = [lineSplit[1], lineSplit[2], lineSplit[3]]
print('Reading library: Done\n')

# Iterate through every sample replacing sequences
infoFileNr = 0
for file in usrFiles:
	#4.1 Shell Output
	infoFileNr += 1
	fileName = os.path.split(file)[1]
	
	# print('\n -> Rewriting samples: ' + fileName + ' (File ' + str(infoFileNr) + ' of ' + str(len(usrFiles)) + ')', end='\r')
	
	# 4.2 Load all sequences of related Samples in a dictionary
	dictFile = {}			# This directory saves all sequences (and its reads and distances) of related samples
	
	FileLength = 0
	FileReads = 0
	with open(file) as f:	# to realize this, open the current File...
		for line in f:		# ... read line by line ...
			if line.startswith('Sequence'):	# ... skip the header line ...
				continue
			lineSplit = line.split()	# split the lines by whitespace (because the structure is e.g. 'AATTCC 3 2')
			FileLength += 1
			FileReads += int(lineSplit[1])
			
			if lineSplit[0] not in dictLibrary:
				print(lineSplit[0] + ' not in dictLibrary\n')
				continue
						
			if dictLibrary[lineSplit[0]][0] not in dictFile:	# if the replaced sequenes did not exist in the file before...
				dictFile[dictLibrary[lineSplit[0]][0]] = [int(lineSplit[1]), dictLibrary[lineSplit[0]][1], dictLibrary[lineSplit[0]][2]] # add to dictFile with key = (replaced) Sequence, Values: [0 = Reads, 1 = Distance (replaced), 2 = Library]
			else:
				dictFile[dictLibrary[lineSplit[0]][0]][0] += int(lineSplit[1])	# otherwise access the reads of the replaced sequence and add the current read count to it
				if dictFile[dictLibrary[lineSplit[0]][0]][2] != dictLibrary[lineSplit[0]][2]:
					print('Library property differs between BC ' + dictLibrary[lineSplit[0]][0] + ' and its descendant ' + lineSplit[0])
	print(fileName + ' (before/after) -> Sequences: ' + str(FileLength) + '/' + str(len(dictFile)) +
			', Reads: ' + str(FileReads) + '/' + str(sum(i for i, _, _ in dictFile.values())))
	
	# Write file
	writeFile = open(dirSave + '/' + fileName, 'w')							# Create and Open the File in 'Clustered'
	writeFile.write('Sequence Reads Distance Library\r\n' +											# Add Header to File
					'\r\n'.join('{} {} {} {}'.format(x,y[0],y[1],y[2]) for x,y in dictFile.items()) +	# Add all Sequences and Reads (seperated by whitespace) of dictLibrary
					'\r\n')															# Last line break to ensure functionality of other scripts
	writeFile.close()																# Close the File

# 7. Final Shell Output
# Get Running Time
runTime = runningTime(startTime, datetime.now())

# Generate Footer information
outputFooter = ('\n---------------------------------\n',
				'Script finished at: ' + datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
				'Running time: ' + runTime)
print('\n'.join('{}'.format(x) for x in outputFooter))

input("Press \'Enter\' to close ...")