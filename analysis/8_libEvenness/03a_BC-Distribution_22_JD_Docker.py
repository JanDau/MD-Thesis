######################################
# BC Distribution v2.2 JD 2021/01/18 #
######################################
usr_stats = True # if stats file shall be exported (True or False)
usr_print = list(range(2,19))   # which group export, set 0 to deactivate (0, 1, 2, ..., 18) or multiple as a list [1, 2, 3 ...]
usr_delim = ',' # Delimiter in csv files de -> ';' en -> ','		leave it to , as otherwise it gets corrupted with the decimal point as well.

##################

# 0. Load modules
# import tkinter, csv, math, re, os                   # tkinter for GUI, os for writing files
import csv, math, re, os                   # os for writing files
# from tkinter.filedialog import askopenfilenames # GUI for file selection
from statistics import mean
from datetime import datetime       # datetime -> script running time
from pathlib import Path
import glob, argparse

# 2. User Interaction
# Initialize GUI
# root = tkinter.Tk()     # Initialize
# root.withdraw()         # Hide window

# GUI
# Files = askopenfilenames(defaultextension='.fna', filetypes=[('.fna Files', '.fna')], title='Select all CSR-treated and merged .fna files, e.g., in Mouse_CSR')
# Files = list(Files)     # Saves file paths as list to iterate through them
#dirSave = Path(__file__).parent


def get_fna_files(directory):
    """Get all .fna files from the specified directory that start with 'Merged__'."""
    # Create a path pattern that includes only files starting with 'Merged__' and ending with '.fna'
    pattern = os.path.join(directory, 'Merged__*.fna')
    
    # Use glob.glob() to get the files matching the pattern
    # The pattern ensures that only files directly in the directory are included (no subdirectories)
    return glob.glob(pattern)

# Set up the argument parser
parser = argparse.ArgumentParser(description='Collect all .fna files starting with "Merged__" from a specified directory.')
parser.add_argument('directory', type=str, help='The directory containing .fna files that start with "Merged__"')

# Parse the arguments
args = parser.parse_args()

# Get all .fna files from the specified directory
Files = get_fna_files(args.directory)

# Optional: print or process the files
print(Files)


test = re.search("Mouse|Human", Files[0], re.IGNORECASE)
dirSaveTmp = test.group() if test else 'Data'   
# dirSave = os.path.join(Path(__file__).parent, 'BC-Distr_' + dirSaveTmp)
dirSave = os.path.join('/JD/docker/export', 'BC-Distr_' + dirSaveTmp)
if not os.path.exists(dirSave):
    os.mkdir(dirSave)

# 4. Main Routine
# 4.1 Reading of all samples
dictSeqPool = {}            # This directory saves all sequences (and its reads and distances) of related samples
header = 'Sequence'
for i in range(len(Files)):
    fileName = Path(Files[i]).stem
    header += usr_delim + fileName
    with open(Files[i]) as f:
        for line in f:
            if line.startswith('Sequence'): # ... skip the header line ...
                continue
            lineSplit = line.split()    # split the lines by whitespace (because the structure is e.g. 'AATTCC 3 2')
            if lineSplit[0] not in dictSeqPool: # sequence as key
                #dictSeqPool[lineSplit[0]] = [[fileName, int(lineSplit[1])]]
                dictSeqPool[lineSplit[0]] = [float('NaN')] * len(Files)
            dictSeqPool[lineSplit[0]][i] = int(lineSplit[1])

# for key, value in dictSeqPool.items():
    # print(key, value)

dictDistr = {}
for key, value in dictSeqPool.items():
    # print(str(key), " -> ", str(value), " -> ", str(len(value)))
    intOccurance = len(value)-len([0 for x in value if math.isnan(x)])
    if intOccurance not in dictDistr:
        dictDistr[intOccurance] = 1
    else:
        dictDistr[intOccurance] += 1

# for key, value in dictDistr.items():
    # print(key, value)

dictSeqs = {}
for seq, value in dictSeqPool.items():
    group = len(value)-len([0 for x in value if math.isnan(x)])
    if group not in dictSeqs:
        dictSeqs[group] = {}
    dictSeqs[group][seq] = value

# for group in dictSeqs.keys():
    # if(group == usr_print):
        # print("Group: " + str(group))
        # for seq, values in dictSeqs[group].items():
            # #print(seq, values)
            # print(seq + usr_delim + usr_delim.join(map(str, values)))

# Statistic export
dictDistr = {k: v for k, v in sorted(dictDistr.items(), key=lambda item: item[1], reverse=True)}
if usr_stats:
    print('No. of Animals with particular BC -> No. of BC')
    for key, value in dictDistr.items():
        print(str(key), " -> ", str(value))
    fname = 'BC-Distr_Stats_' + datetime.now().strftime('%Y%m%d_%H%M%S') + '.csv'
    fileExportStats = os.path.join(dirSave, fname)
    with open(fileExportStats, mode='w', newline='') as f:
        f.write('\n'.join('{x}{a}{y}'.format(a=usr_delim, x=x, y=y) for x,y in dictDistr.items()))
    print("\nThe following files were saved at " + str(dirSave) + ":")
    print("- Overall statistics: " + str(fname))

# Group Export
for group in dictSeqs.keys():
    if(group in usr_print):
        fname = 'BC-Distr_Group_' + str(group) + '_' + datetime.now().strftime('%Y%m%d_%H%M%S') + '.csv'
        fileExportGroup = os.path.join(dirSave, fname)
        with open(fileExportGroup, mode='w', newline='') as f:
            f.write(header + '\n')
            for seq, values in dictSeqs[group].items():
                val = [0 if math.isnan(x) else x for x in values]
                f.write(seq + usr_delim + usr_delim.join(map(str, val)) + '\n')
        print("- Occurance in " + str(group) + " animals: " + str(fname))

input("\nPress \'Enter\' to close ...")