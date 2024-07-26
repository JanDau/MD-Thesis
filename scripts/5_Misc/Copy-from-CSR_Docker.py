
usr_filter = "CSR"
usr_replace = {'C': "UsedLibrary",
                'S': "MaxDev0",
                'R': "MinReads3"} #need to be changed to "MinReads2" for Human or "MinReads3" for Mouse
usr_cohort = "mouse" #need to be changed to "mouse" or "human"

###### Don't Change #####

import sys, os          # regex for Levenshtein distance, os for writing files, math for n-faculty
# from tkinter.filedialog import askdirectory # GUI for dir selection
from shutil import copyfile

usr_path = ""
for i in range(0, len(usr_filter)):
    usr_path = os.path.join(usr_path, usr_filter[i].translate(str.maketrans(usr_replace)))
#print(usr_path)

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
#print(usr_mice)

dirNew = os.path.join(os.path.split(usr_dir)[0], usr_cohort + '_' + usr_filter)
#print(dirNew)
if not os.path.exists(dirNew):
    os.mkdir(dirNew)

for i in range(0, len(usr_mice)): #range(0,1):
    mouse_dir = os.path.join(usr_dir, usr_mice[i], usr_path)
    #print(mouse_dir)
    mouse_files = [f.path for f in os.scandir(mouse_dir) if f.is_file()]
    #print(mouse_files)
    dirMouse = os.path.join(dirNew, usr_mice[i])
    if not os.path.exists(dirMouse):
        os.mkdir(dirMouse)
    for x in range(0, len(mouse_files)):
        copyfile(mouse_files[x], os.path.join(dirMouse, os.path.basename(mouse_files[x])))

input("\nPress \'Enter\' to close ...")