#######################################
# Merge Replicates Multiple v1.1      #
#######################################

# Samples need to be named like PB-T_175d_1_1507_080 (the third split contains the replicate count)

####################################
######## Don't Change Below ########
####################################

import os, sys
# import tkinter as tk				# tkinter for GUI
# from tkinter.filedialog import askdirectory	# GUI for file/dir selection

# root = tk.Tk() 	# Initiliaze
# root.withdraw()	# Hide window
# GUI for FASTA File with Sequences			# ('all files', '.*')
# usr_dir = askdirectory(title='Choose directory with mice subfolders, e.g. "/Mouse_CSR"')

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

for i in range(0, len(usr_mice)): #range(5,6):
    dictSamples = {}
    mouse_dir = os.path.join(usr_dir, usr_mice[i])
    #print(mouse_dir)
    mouse_files = [f.path for f in os.scandir(mouse_dir) if f.is_file()]
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

        dirSave = os.path.join(mouse_dir, 'Merged')
        if not os.path.exists(dirSave):
            os.mkdir(dirSave)
        writeFile = open(dirSave + '/' + strFilename, 'w')									# Create and Open the File
        writeFile.write('Sequence Reads Distance\r\n')												# Add Header to File
        writeFile.write('\r\n'.join('{} {} {}'.format(x,y[0],y[1]) for x,y in dictOut.items()))	# Add all Sequences and Reads (seperated by whitespace) of dictFinal
        writeFile.write('\r\n')															# Last line break to ensure functionality of other scripts
        writeFile.close()		
