########################################
# Sample Allocation v1.2 JD 2020/06/28 #
########################################
userMaxDev = 2

# 0. Load modules
import os, csv		# os -> read/write dirs/files, regex -> string comparison, csv -> .csv file handling
# import tkinter as tk				# tkinter for GUI
# from tkinter.filedialog import askopenfilename, askdirectory	# GUI for file/dir selection
from shutil import copyfile
import sys

# 2. User Interaction
# # Initialize GUI
# root = tk.Tk() 	# Initiliaze
# root.withdraw()	# Hide window
# # GUI for CSV Library File with Library Names (column 1, e.g. 'ITRGB_001') and corresponding Sequence (column 2, e.g. 'ttataacg')
# libraryFile = askopenfilename(defaultextension='.csv', filetypes=[('.csv File', '.csv')], title='Select CSV File (.csv) with Library IDs')
# # GUI for Directory where different runs are found, e.g. ".../Data/Preprocessed/"
# dataDir = askdirectory(title='Choose data directory with different runs')
# # GUI for Directory where to save Files, e.g. ".../Data/Allocated/"
# saveDir = askdirectory(title='Choose directory where to create subfolders')
# # Set delimiter

if len(sys.argv) > 3:
    libraryFile = sys.argv[1]
    dataDir = sys.argv[2]
    saveDir = sys.argv[3]
else:
    raise ValueError("Please provide correct arguments (see Readme).")
    

userDelimiter = input("Enter delimiter (de -> ; | en -> ,):")

# 3. Load CSV Library File and load into associative array (= dictionary)
libraryIDs = {} 	# initiate dictionary

with open(libraryFile, newline='') as csvfile:		# open file
	library = csv.reader(csvfile, delimiter=userDelimiter)	# read it as a csv file
	for row in library:
		if row[0] == "ID":
			continue
		if not os.path.exists(saveDir + '/' + row[0]):
			os.mkdir(saveDir + '/' + row[0])
		if userMaxDev == 5:
			fname = dataDir + '/' + row[1] + '/Reads/ITRGB_' + '{:03d}'.format(int(row[2])) + '.fna'
		else:
			fname = dataDir + '/' + row[1] + '/Reads/MaxDev' + str(userMaxDev) + '/ITRGB_' + '{:03d}'.format(int(row[2])) + '.fna'
		if os.path.isfile(fname):
			copyfile(fname, saveDir + '/' + row[0] + '/' + row[3] + '_' + row[4] + '_' + row[1] + '_' + '{:03d}'.format(int(row[2])) + '.fna')
		else:
			print('Skipped ' + fname)

input("\nPress \'Enter\' to close ...")