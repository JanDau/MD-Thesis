############################################
# Apply deviation filter MULTIPLE - Docker #
############################################

# User defined settings ------------
usr_dev = 0
usr_filter = "C"   # which filters are already applied? Correct order necessary
usr_replace = {'C': "UsedLibrary",
                'S': "MaxDev0",
                'R': "MinReads3"}

####################################
######## Don't Change Below ########
####################################

# 0. Load modules
import sys, os, re					# regex for Levenshtein distance, os for writing files, math for n-faculty
# from tkinter.filedialog import askdirectory	# GUI for file selection

# 2. User Interaction
# Initialize GUI
# root = tkinter.Tk() 	# Initialize
# root.withdraw()			# Hide window

# usr_dir = askdirectory(title='Choose directory with mice subfolders, e.g. "/Allocated"')

if len(sys.argv) == 2 and os.path.isdir(sys.argv[1]):
    usr_dir = sys.argv[1]
else:
    raise ValueError("No path argument provided.")

usr_mice = []
for dir in os.listdir(usr_dir):
    if os.path.isdir(os.path.join(usr_dir, dir)):
        usr_mice.append(dir)

for i in range(0, len(usr_mice)): #range(0,1):
    mouse_dir = os.path.join(usr_dir, usr_mice[i])
    usr_file_dir = mouse_dir
    for x in range(0, len(usr_filter)):
        usr_file_dir = os.path.join(usr_file_dir, usr_filter[x].translate(str.maketrans(usr_replace)))

    #print(mouse_dir)
    mouse_files = [f.path for f in os.scandir(usr_file_dir) if f.is_file()]
    for file in mouse_files:
        dictSeqPool = {}			# This directory saves all sequences (and its reads and distances) of related samples
        fileName = os.path.basename(file)
        if re.search('(Lib-)|(.txt)', fileName): continue
        
        with open(file) as f:   # Load all sequences into a dictionary
            for line in f:
                if line.startswith('Sequence'):	# ... skip the header line ...
                    continue
                lineSplit = line.split()	# split the lines by whitespace (because the structure is e.g. 'AATTCC 3 2')
                if int(lineSplit[2]) > usr_dev: # only keep sequences with a smaller deviation than defined
                    continue
                dictSeqPool[lineSplit[0]] = [int(lineSplit[1]), int(lineSplit[2])] #key = Sequence, Values: 0 = Reads, 1 = Distance
        
        # Write Library File as .fna
        dirSave = os.path.join(usr_file_dir, 'MaxDev' + str(usr_dev))
        if not os.path.exists(dirSave):
            os.mkdir(dirSave)
        writeFile = open(dirSave + '/' + fileName, 'w')								# Create and Open the File in 'Clustered'
        writeFile.write('Sequence Reads Distance\r\n' +											# Add Header to File
                '\r\n'.join('{} {} {}'.format(x,y[0],y[1]) for x,y in dictSeqPool.items()) +	# Add all Sequences and Reads (seperated by whitespace) of dictLibrary
                '\r\n')															# Last line break to ensure functionality of other scripts
        writeFile.close()	

input("\nPress \'Enter\' to close ...")