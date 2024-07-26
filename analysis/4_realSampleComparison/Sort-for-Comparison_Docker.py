# User defined settings ------------
usr_filter = ['Raw', 'S', 'R', 'C', 'SC', 'SCR', 'CS', 'CSR']
usr_replace = {'C': "Clustered_CD2",
                'S': "MaxDev0",
                'R': "MinReads2"}

####################################
######## Don't Change Below ########
####################################

# 0. Load modules
# import tkinter
import os, shutil          # tkinter for GUI, regex for Levenshtein distance, os for writing files, math for n-faculty
# from tkinter.filedialog import askopenfilenames # GUI for file selection
import argparse, glob

# 2. User Interaction
# Initialize GUI
# root = tkinter.Tk()     # Initialize
# root.withdraw()         # Hide window

# usr_files = askopenfilenames(title='Choose directory with mice subfolders, e.g. "/Allocated"')

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
usr_files = get_fna_files(args.directory)
# ---- Docker edit END -----


for file in usr_files:
    file_dir = os.path.join(os.path.split(file)[0], os.path.basename(file).split('.')[0])
    #print(file_dir)
    os.mkdir(file_dir)
    for filter in usr_filter:
        if filter == 'Raw':
            file_old = file
            file_new = os.path.join(file_dir, filter + '.fna')
            #print('from: ', file_old)
            #print('to: ', file_new)
        else:
            filter_dir = ""
            for x in range(0, len(filter)):
                filter_dir = os.path.join(filter_dir, filter[x].translate(str.maketrans(usr_replace)))
            file_old = os.path.join(os.path.split(file)[0], filter_dir, os.path.basename(file))
            file_new = os.path.join(file_dir, filter + '.fna')
            #print('from: ', file_old)
            #print('to: ', file_new)
        shutil.copy(file_old, file_new)