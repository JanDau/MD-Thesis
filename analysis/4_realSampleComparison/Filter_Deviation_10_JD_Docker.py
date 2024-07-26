######################################################
# Apply deviation filter v1.0 JD 2018/08/09 - Docker #
######################################################

# User defined settings ------------
userMaxDev = 0
				
####################################
######## Don't Change Below ########
####################################

version = '1.0'

# 0. Load modules
import csv, regex, os, math					# tregex for Levenshtein distance, os for writing files, math for n-faculty
from operator import itemgetter					# for sorting
from datetime import datetime 		# datetime -> script running time			# for sorting
import argparse, glob

# 2. User Interaction
# # Initialize GUI
# root = tkinter.Tk() 	# Initialize
# root.withdraw()			# Hide window

# # GUI
# Files = askopenfilenames(defaultextension='.fna', filetypes=[('.fna Files', '.fna')], title='Choose .fna files to cluster')
# Files = list(Files)		# Saves file paths as list to iterate through them
# dirFile = os.path.split(Files[0])[0]

def get_files_from_directory(directory_path, extension=".fna"):
    """Get all files with the specified extension from the given directory."""
    return glob.glob(os.path.join(directory_path, '*' + extension))

def process_arguments(arguments):
    """Process the command line arguments to get a list of files."""
    files_to_process = []
    for arg in arguments:
        if os.path.isdir(arg):
            # If the argument is a directory, get all .fna files within it
            files_to_process.extend(get_files_from_directory(arg))
        elif os.path.isfile(arg):
            # If the argument is a file, add it to the list
            files_to_process.append(arg)
        else:
            print(f"Warning: {arg} is not a valid file or directory and will be ignored.")
    return files_to_process

# Initialize the parser
parser = argparse.ArgumentParser(description='Process .fna files or directories containing them.')
parser.add_argument('paths', type=str, nargs='+',
                    help='The path(s) to .fna files or directories containing .fna files')

# Parse the arguments
args = parser.parse_args()

# Process the arguments to get a list of files
Files = process_arguments(args.paths)
dirFile = os.path.split(Files[0])[0]

# Create 'MaxDev' directory in the directory of the files
dirMaxDev = os.path.split(Files[0])[0] + '/MaxDev' + str(userMaxDev)
if not os.path.exists(dirMaxDev):
	os.mkdir(dirMaxDev)
	
# 4. Main Routine
# 4.1 Reading of all samples
infoFileNr = 0

for File in Files:	# allFiles contains the sublists of libraryLine, e.g. [Sample1.1, Sample1.2]
	dictSeqPool = {}			# This directory saves all sequences (and its reads and distances) of related samples
	
	#4.1 Shell Output
	infoFileNr += 1
	fileName = os.path.split(File)[1]
	
	# 4.2 Load all sequences of related Samples in a dictionary
	with open(File) as f:
		for line in f:
			if line.startswith('Sequence'):	# ... skip the header line ...
				continue
			lineSplit = line.split()	# split the lines by whitespace (because the structure is e.g. 'AATTCC 3 2')
			if int(lineSplit[2]) > userMaxDev: # only keep sequences with a smaller deviation than defined
				continue
			dictSeqPool[lineSplit[0]] = [int(lineSplit[1]), int(lineSplit[2])] #key = Sequence, Values: 0 = Reads, 1 = Distance
	
	# Write Library File as .fna
	writeFile = open(dirMaxDev + '/' + fileName, 'w')								# Create and Open the File in 'Clustered'
	writeFile.write('Sequence Reads Distance\r\n' +											# Add Header to File
			'\r\n'.join('{} {} {}'.format(x,y[0],y[1]) for x,y in dictSeqPool.items()) +	# Add all Sequences and Reads (seperated by whitespace) of dictLibrary
			'\r\n')															# Last line break to ensure functionality of other scripts
	writeFile.close()	

input("\nPress \'Enter\' to close ...")