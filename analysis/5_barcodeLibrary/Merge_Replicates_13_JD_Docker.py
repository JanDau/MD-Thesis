################################################
# Merge Replicates v1.3 JD 2020/06/22 - Docker #
################################################

# User defined settings ------------
user_defined_sample_names = True	# True or False. Switch to True if samples named like "PB_175d_2_1507_030.fna"

####################################
######## Don't Change Below ########
####################################

import os, regex, sys
# import tkinter as tk				# tkinter for GUI
# from tkinter.filedialog import askopenfilenames	# GUI for file/dir selection

def mean(numbers):
    return float(sum(numbers)) / max(len(numbers), 1)

# root = tk.Tk() 	# Initiliaze
# root.withdraw()	# Hide window
# GUI for FASTA File with Sequences			# ('all files', '.*')
# files = askopenfilenames(defaultextension='.fna', filetypes=[('.fna File', '.fna')], title='Select replicates (.fna files)')

# Docker edit ---
if len(sys.argv) == 2 and os.path.isdir(sys.argv[1]):
    usr_dir = sys.argv[1]
else:
    raise ValueError("No path argument provided.")
# ---------------

dictSamples = {}
mouse_files = [f.path for f in os.scandir(usr_dir) if f.is_file() and f.name.endswith('.fna')]
for file in mouse_files:
    fname = os.path.basename(file).split("_")
    #print(fname)
    fsample = '_'.join(fname[0:2])
    #print(fsample)
    if fsample in dictSamples:
        dictSamples[fsample].append(file)
    else:
        dictSamples[fsample] = [file]

for k, v in dictSamples.items():
    #print(k, v)
    dictOut = {}	# dictOut ={"AATTCC":[300, 0], "GGAATT":[151, 1], ...} ; key = Sequence, value[0] = mean Reads, value[1] = Distance
    dictFile = {}   # dictOut ={"AATTCC":[300, 280, 320, ...], "GGAATT":[151, 150, 166, ...], ...} ; key = Sequence, value[0] = Reads in file 1, value[1] = Reads in file 2, ...
    for file in v:
        with open(file) as f:	# open current File...
            for line in f:		# ... read line by line ...
                if line.startswith('Sequence'):	# ... skip the header line ...
                    continue
                lineSplit = line.split()	# split the lines by whitespace (because the structure is e.g. 'AATTCC 3 2')
                if lineSplit[0] in dictFile:
                    #print(dictFile[lineSplit[0]])
                    dictFile[lineSplit[0]].append(int(lineSplit[1]))
                    #print(dictFile[lineSplit[0]])
                else:
                    dictFile[lineSplit[0]] = [int(lineSplit[1])]
                    dictOut[lineSplit[0]] = [0, int(lineSplit[2])]
        
    for key, seqs in dictFile.items():
        dictOut[key][0] = sum(seqs)

    strFilename = os.path.split(v[0])[1]
    strFilenameStart = '_'.join(strFilename.split("_")[0:(len(strFilename.split("_"))-3)])
    strFilename = (strFilenameStart + '_Merged-' + str(len(v)) + '.fna')
    # print(strFilename)

    dirSave = os.path.join(usr_dir, 'merged')
    if not os.path.exists(dirSave):
        os.mkdir(dirSave)
    writeFile = open(dirSave + '/' + strFilename, 'w')									# Create and Open the File
    writeFile.write('Sequence Reads Distance\r\n')												# Add Header to File
    writeFile.write('\r\n'.join('{} {} {}'.format(x,y[0],y[1]) for x,y in dictOut.items()))	# Add all Sequences and Reads (seperated by whitespace) of dictFinal
    writeFile.write('\r\n')															# Last line break to ensure functionality of other scripts
    writeFile.close()