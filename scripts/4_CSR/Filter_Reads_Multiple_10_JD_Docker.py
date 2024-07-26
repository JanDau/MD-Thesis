#####################################################
# Read threshold filter Multiple v1.0 JD 2020/12/17 #
#####################################################

# User defined settings ------------
userThresh = 2 # reads need to be > than the given value (set 2 for the Mouse and 1 for the Human cohort)
userSkip = ["mean", 8] # criteria for files to be skipped; as list: First criteria "mean" or "mode", 2nd: thresh
usr_filter = "CS"   # which filters are already applied? Correct order necessary
usr_replace = {'C': "UsedLibrary",
                'S': "MaxDev0",
                'R': "MinReads2"}

####################################
######## Don't Change Below ########
####################################

# 0. Load modules
import sys, os, statistics          # regex for Levenshtein distance, os for writing files, math for n-faculty
# from tkinter.filedialog import askdirectory # GUI for file selection
from collections import Counter
from shutil import copyfile

# 1. functions
def get_all_modes(a):
    c = Counter(a)  
    mode_count = max(c.values())
    mode = {key for key, count in c.items() if count == mode_count}
    return mode

# 2. User Interaction
# Initialize GUI
# root = tkinter.Tk()     # Initialize
# root.withdraw()         # Hide window

# usr_dir = askdirectory(title='Choose directory with mice subfolders, e.g. "/Allocated"')

# Docker edit ---
if len(sys.argv) == 2 and os.path.isdir(sys.argv[1]):
    usr_dir = sys.argv[1]
else:
    raise ValueError("No path argument provided.")
# ---------------

usr_mice = []
for dir in os.listdir(usr_dir):
    if os.path.isdir(os.path.join(usr_dir, dir)):
        usr_mice.append(dir)

for i in range(0, len(usr_mice)): #range(0,1):
    mouse_dir = os.path.join(usr_dir, usr_mice[i])
    usr_file_dir = mouse_dir
    for x in range(0, len(usr_filter)):
        usr_file_dir = os.path.join(usr_file_dir, usr_filter[x].translate(str.maketrans(usr_replace)))

    #print(usr_file_dir)
    dirSave = os.path.join(usr_file_dir, 'MinReads' + str(userThresh+1))
    if not os.path.exists(dirSave):
        os.mkdir(dirSave)
    mouse_files = [f.path for f in os.scandir(usr_file_dir) if f.is_file()]
    for file in mouse_files:
        fileReadList = []
        fileName = os.path.basename(file)

        # 4.2 First calculate the mode/mean
        with open(file) as f:
            for line in f:
                if line.startswith('Sequence'): # ... skip the header line ...
                    continue
                lineSplit = line.split()
                fileReadList.append(int(lineSplit[1]))
        if userSkip[0] == "mean":
            fileSkip = statistics.mean(fileReadList)
        else:
            fileSkip = get_all_modes(fileReadList)
            fileSkip = min(fileSkip)
        if fileSkip > userSkip[1]: # Skip file (= do not filter), if mean/mode is <= userSkip[1]
            dictSeqPool = {}            # This directory saves all sequences (and its reads and distances) of related samples
            # 4.3 Load all sequences of related Samples in a dictionary
            with open(file) as f:
                for line in f:
                    if line.startswith('Sequence'): # ... skip the header line ...
                        continue
                    lineSplit = line.split()    # split the lines by whitespace (because the structure is e.g. 'AATTCC 3 2')
                    #print(int(lineSplit[1]))
                    if int(lineSplit[1]) > userThresh: # skip sequences with a read count <= than defined by userThresh
                        dictSeqPool[lineSplit[0]] = [int(lineSplit[1]), int(lineSplit[2])] #key = Sequence, Values: 0 = Reads, 1 = Distance
        
            # Write Library File as .fna
            writeFile = open(dirSave + '/' + fileName, 'w')                                # Create and Open the File in 'Clustered'
            writeFile.write('Sequence Reads Distance\r\n' +                                           # Add Header to File
                    '\r\n'.join('{} {} {}'.format(x,y[0],y[1]) for x,y in dictSeqPool.items()) +  # Add all Sequences and Reads (seperated by whitespace) of dictLibrary
                    '\r\n')                                                           # Last line break to ensure functionality of other scripts
            writeFile.close()
        else:
            print(fileName, "not filtered (", userSkip[0], "of Reads:", str(round(fileSkip,1)), ")")
            copyfile(file, os.path.join(dirSave, fileName))

input("\nPress \'Enter\' to close ...")