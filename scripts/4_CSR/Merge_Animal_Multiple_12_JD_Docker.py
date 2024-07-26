#######################################
# Merge Animal Multiple v1.2 - Docker #
#######################################

usr_filter = "CS"   # which filters are already applied? Correct order necessary
usr_replace = {'C': "UsedLibrary",
                'S': "MaxDev0",
                'R': "MinReads3"}

####################################
######## Don't Change Below ########
####################################

import sys, os, re
# import tkinter as tk				# tkinter for GUI
# from tkinter.filedialog import askdirectory	# GUI for file/dir selection

# root = tk.Tk() 	# Initiliaze
# root.withdraw()	# Hide window
# GUI for FASTA File with Sequences			# ('all files', '.*')
# usr_dir = askdirectory(title='Choose directory with mice subfolders, e.g. "/Mouse_CSR"')

if len(sys.argv) == 2 and os.path.isdir(sys.argv[1]):
    usr_dir = sys.argv[1]
else:
    raise ValueError("No path argument provided.")

usr_mice = []
for dir in os.listdir(usr_dir):
    if os.path.isdir(os.path.join(usr_dir, dir)):
        usr_mice.append(dir)

for i in range(0, len(usr_mice)): #range(0,1):
    dictOut = {}	# dictOut ={"AATTCC":[300, 0], "GGAATT":[151, 1], ...} ; key = Sequence, value[0] = mean Reads, value[1] = Distance
    dictFile = {}   # dictOut ={"AATTCC":[300, 280, 320, ...], "GGAATT":[151, 150, 166, ...], ...} ; key = Sequence, value[0] = Reads in file 1, value[1] = Reads in file 2, ...
    mouse_dir = os.path.join(usr_dir, usr_mice[i])
    usr_file_dir = mouse_dir
    for x in range(0, len(usr_filter)):
        usr_file_dir = os.path.join(usr_file_dir, usr_filter[x].translate(str.maketrans(usr_replace)))

    #print(usr_file_dir)
    mouse_files = [f.path for f in os.scandir(usr_file_dir) if f.is_file()]
    for file in mouse_files:
        if re.search('(Lib-)|(.txt)', os.path.basename(file)): continue
        with open(file) as f:	# open current File...
                for line in f:		# ... read line by line ...
                    if line.startswith('Sequence'):	# ... skip the header line ...
                        continue
                    lineSplit = line.split()	# split the lines by whitespace (because the structure is e.g. 'AATTCC 3 2')
                    if lineSplit[0] in dictFile:
                        dictFile[lineSplit[0]].append(int(lineSplit[1]))
                    else:
                        dictFile[lineSplit[0]] = [int(lineSplit[1])]
                        dictOut[lineSplit[0]] = [0, int(lineSplit[2])]

        for k, v in dictFile.items():
            dictOut[k][0] = sum(v)

        strFilename = ('Merged_' + usr_filter + '_' + usr_mice[i] + '.fna')
        writeFile = open(usr_dir + '/' + strFilename, 'w')									# Create and Open the File
        writeFile.write('Sequence Reads Distance\r\n')												# Add Header to File
        writeFile.write('\r\n'.join('{} {} {}'.format(x,y[0],y[1]) for x,y in dictOut.items()))	# Add all Sequences and Reads (seperated by whitespace) of dictFinal
        writeFile.write('\r\n')															# Last line break to ensure functionality of other scripts
        writeFile.close()																# Close the File