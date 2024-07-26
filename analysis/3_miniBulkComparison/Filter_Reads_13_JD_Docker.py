############################################
# Read threshold filter v1.3 JD 2021/01/07 #
############################################

# User defined settings ------------
userThresh = 1 # reads need to be > than the given value
userSkip = None # criteria for files to be skipped; input as a list.
            # First criteria "mean" or "mode", 2nd the thresh, e. g. ["mean", 8]
            # set None to deactivate

####################################
######## Don't Change Below ########
####################################

version = '1.3'

# 0. Load modules
import os, statistics          # tkinter for GUI, regex for Levenshtein distance, os for writing files, math for n-faculty
# from tkinter.filedialog import askopenfilenames # GUI for file selection
from collections import Counter
from shutil import copyfile
import argparse, glob

# 1. functions
def get_all_modes(a):
    c = Counter(a)  
    mode_count = max(c.values())
    mode = {key for key, count in c.items() if count == mode_count}
    return mode

# 2. User Interaction
# # Initialize GUI
# root = tkinter.Tk()     # Initialize
# root.withdraw()         # Hide window

# # GUI
# Files = askopenfilenames(defaultextension='.fna', filetypes=[('.fna Files', '.fna')], title='Choose .fna files to filter')
# Files = list(Files)     # Saves file paths as list to iterate through them

# ---- Docker edit START -----
def get_fna_files(directory):
    """Get all .fna files from the specified directory."""
    return glob.glob(os.path.join(directory, '*.fna'))

# Set up the argument parser
parser = argparse.ArgumentParser(description='Collect all .fna files from a specified directory.')
parser.add_argument('directory', type=str, help='The directory containing .fna files')

# Parse the arguments
args = parser.parse_args()

# Get all .fna files from the specified directory
Files = get_fna_files(args.directory)
# ---- Docker edit END -----

dirFile = os.path.split(Files[0])[0]

# Create 'MaxDev' directory in the directory of the files
dirMinReads = os.path.split(Files[0])[0] + '/MinReads' + str(userThresh+1)
if not os.path.exists(dirMinReads):
    os.mkdir(dirMinReads)
    
# 4. Main Routine
# 4.1 Reading of all samples
infoFileNr = 0

for File in Files:  # allFiles contains the sublists of libraryLine, e.g. [Sample1.1, Sample1.2]
    fileReadList = []
    
    #4.1 Shell Output
    infoFileNr += 1
    fileName = os.path.split(File)[1]
    
    # 4.2 First calculate the mode
    with open(File) as f:
        for line in f:
            if line.startswith('Sequence'): # ... skip the header line ...
                continue
            lineSplit = line.split()
            fileReadList.append(int(lineSplit[1]))
    if userSkip != None:
        if userSkip[0] == "mean":
            fileSkip = statistics.mean(fileReadList)
        else:
            fileSkip = get_all_modes(fileReadList)
            fileSkip = min(fileSkip)
    if userSkip == None or fileSkip > userSkip[1]: # Skip file (= do not filter), if mean/mode is <= userSkip[1]
        dictSeqPool = {}            # This directory saves all sequences (and its reads and distances) of related samples
        # 4.3 Load all sequences of related Samples in a dictionary
        with open(File) as f:
            for line in f:
                if line.startswith('Sequence'): # ... skip the header line ...
                    continue
                lineSplit = line.split()    # split the lines by whitespace (because the structure is e.g. 'AATTCC 3 2')
                #print(int(lineSplit[1]))
                if int(lineSplit[1]) > userThresh: # skip sequences with a read count <= than defined by userThresh
                    dictSeqPool[lineSplit[0]] = [int(lineSplit[1]), int(lineSplit[2])] #key = Sequence, Values: 0 = Reads, 1 = Distance
    
        # Write Library File as .fna
        writeFile = open(dirMinReads + '/' + fileName, 'w')                                # Create and Open the File in 'Clustered'
        writeFile.write('Sequence Reads Distance\r\n' +                                           # Add Header to File
                '\r\n'.join('{} {} {}'.format(x,y[0],y[1]) for x,y in dictSeqPool.items()) +  # Add all Sequences and Reads (seperated by whitespace) of dictLibrary
                '\r\n')                                                           # Last line break to ensure functionality of other scripts
        writeFile.close()
    else:
        print(fileName, "not filtered (", userSkip[0], "of Reads:", str(round(fileSkip,1)), ")")
        copyfile(File, os.path.join(dirMinReads, fileName))

input("\nPress \'Enter\' to close ...")