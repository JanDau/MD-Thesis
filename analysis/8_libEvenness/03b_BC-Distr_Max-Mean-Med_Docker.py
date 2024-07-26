# v.20210328
### User settings
# usr_include = ("preTX", "PB_19d", "PB_41d", "PB_83d", "PB_175d", "BM_175d") # mouse cohort
usr_include = ("preTX", "PB_3w", "PB_12w", "BM_12w") # xenograft cohort
usr_param = "mean" # mean, median, max
usr_delim = ',' # Delimiter in csv files de -> ';' en -> ','

########

# import tkinter, csv, math, os, re
import csv, math, os, re
# from tkinter.filedialog import askopenfilenames, askdirectory
from statistics import mean, median, stdev
from datetime import datetime
from pathlib import Path
import glob, argparse



def load_files(path_list):
    res = dict()
    for i in range(len(path_list)):
        fname = os.path.basename(path_list[i])[:len(os.path.basename(path_list[i]))-13]
        res[fname] = dict()
        with open(path_list[i]) as f:	# open current File...
            for line in f:		# ... read line by line ...
                if line.startswith('Sequence'):	continue    # ... skip the header line ...
                lineSplit = line.split()	# split the lines by whitespace (because the structure is e.g. 'AATTCC 3 2')
                res[fname][lineSplit[0]] = int(lineSplit[1])
    return res
    
# 1. Initialize GUI
# root = tkinter.Tk()     # Initialize
# root.withdraw()         # Hide window

# 2. Establish paths to every file of each mouse
# usr_dir = askdirectory(title='Choose directory with mice subfolders, e.g. "/Mouse_CSR"')

# Docker Edit START -------------
def get_csv_files(directory):
    """Get all .csv files from the specified directory that start with 'BC-Distr_Group_'."""
    pattern = os.path.join(directory, 'BC-Distr_Group_*.csv')
    return glob.glob(pattern)

# Set up the argument parser
parser = argparse.ArgumentParser(description='Process .fna and .csv files from specified directories.')
parser.add_argument('csr_directory', type=str, help='The directory containing CSR-treated files')
parser.add_argument('csv_directory', type=str, help='The directory containing .csv files that start with "BC-Distr_Group_"')

# Parse the arguments
args = parser.parse_args()

# Check if the first directory exists
if not os.path.isdir(args.csr_directory):
    raise ValueError(f"The provided directory for the CSR-treated files does not exist: {args.csr_directory}")

# Check if the second directory exists
if not os.path.isdir(args.csv_directory):
    raise ValueError(f"The provided directory for .csv files does not exist: {args.csv_directory}")

usr_dir = args.csr_directory
usr_files = get_csv_files(args.csv_directory)

# Docker Edit END -------------




usr_filter = '|'.join("(" + x + ")" for x in usr_include)
usr_mice = dict()
for dir in os.listdir(usr_dir):
    if os.path.isdir(os.path.join(usr_dir, dir)):
        usr_mice[dir] = []

for mouse in usr_mice.keys(): #["SF-3#1"]:
    mouse_files = [f.path for f in os.scandir(os.path.join(usr_dir, mouse)) if f.is_file()]
    for i in mouse_files:
        if re.search(usr_filter, os.path.basename(i)):
            usr_mice[mouse].append(i)

# for key, value in usr_mice.items():
    # print(key, value)
    
# 3. Read in csv files
# usr_files = askopenfilenames(defaultextension='.csv', initialdir=Path(__file__).parent, filetypes=[('.csv files', '.csv')], title='Choose previously generated .csv files')
dir_save = os.path.join(os.path.dirname(usr_files[0]), usr_param)
if not os.path.exists(dir_save):
    os.mkdir(dir_save)

dict_freq = dict()

for file in usr_files:
    dict_freq[os.path.basename(file)] = dict()
    dict_freq[os.path.basename(file)]['Occurance'] = []
    dict_freq[os.path.basename(file)]['Samples'] = []
    # 3.1 Read csv into dict_file
    dict_file = dict()
    with open(file, newline='') as csvfile:
        f = csv.reader(csvfile, delimiter=usr_delim)
        for row in f:
            if(row[0] == "Sequence"):
                usr_header = row[1:len(row)] # Save the order of the mice represented by column titles
            else:
                dict_file[row[0]] = [int(x) for x in row[1:len(row)]]
    usr_header = [s[8:len(s)] for s in usr_header] # remove "Merged__" in the beginning of the strings
    
    # for key, value in dict_file.items():
        # print(key, value)
    # print(os.path.basename(file))
    # print(usr_header)
    
    # 3.2 Go mouse by mouse (col by col) with sequential loading of the required files into dict_mouse
    #debug = ("ATCTACCCTATCCAGCTCTTCTCGATTCTAACCTTTAGGAGCGATCT", "ATCTAAGCTAACCAGAACTTCTCGATGCTACTCTTATGGACGGATCT")
    for i in range(len(usr_header)):
        print('{}: Mouse {} of {}         '.format(os.path.basename(file), i+1, len(usr_header)), end='\r')
        mouse = usr_header[i]
        #print(mouse)
        dict_mouse = load_files(usr_mice[mouse])
        for seq, reads in dict_file.items():
            #if seq not in debug: continue
            if reads[i] != 0:
                #print(i, seq, reads[i])
                #print("Entry found for", seq)
                reads_list = []
                #print(seq)
                sample_freq = 0
                for f in dict_mouse.keys():
                    if seq in dict_mouse[f].keys():
                        reads_seq = dict_mouse[f][seq]
                        reads_total = sum(dict_mouse[f].values())
                        reads_list.append(reads_seq/reads_total)
                        sample_freq += 1
                        #print("Seq found in", f, "with", str(reads_seq), "of total", str(reads_total))
                    else:
                        reads_list.append(0.)
                #print(reads_list)
                dict_freq[os.path.basename(file)]['Occurance'].append(sample_freq)
                dict_freq[os.path.basename(file)]['Samples'].append(len(reads_list))

                if len(reads_list) > 0:
                    dict_file[seq][i] = eval(usr_param)(reads_list) # take mean/median/max and replace value in dict_file
                else:
                    dict_file[seq][i] = 0
        del dict_mouse
    dict_freq[os.path.basename(file)]['Occurance'] = [eval(x)(dict_freq[os.path.basename(file)]['Occurance']) for x in ('mean', 'stdev', 'len')]
    dict_freq[os.path.basename(file)]['Samples'] = [eval(x)(dict_freq[os.path.basename(file)]['Samples']) for x in ('mean', 'stdev', 'len')]
    
    # 3.3 Export
    fname = os.path.basename(file)[0:len(os.path.basename(file))-15] + datetime.now().strftime('%Y%m%d_%H%M%S') + '.csv'
    file_export = os.path.join(dir_save, fname)
    with open(file_export, mode='w', newline='') as f:
        f.write('Sequence' + usr_delim + usr_delim.join(x for x in usr_header) + '\n')
        for seq, values in dict_file.items():
            val = [0 if math.isnan(x) else x for x in values]
            if sum(values) != 0:
                f.write(seq + usr_delim + usr_delim.join(map(str, val)) + '\n')

fname = 'Sample-Frequency-Stats_' + datetime.now().strftime('%Y%m%d_%H%M%S') + '.csv'
file_export = os.path.join(dir_save, fname)
with open(file_export, mode='w', newline='') as f:
    f.write(usr_delim.join(['Group', 'Mean', 'SD', 'N', 'Samples-Mean', 'Samples-SD', 'Samples-N']) + '\n')
    for name, values in dict_freq.items():
        f.write(name + usr_delim + usr_delim.join(str(x) for x in values['Occurance']) + usr_delim + usr_delim.join(str(x) for x in values['Samples']) + '\n')
input("\nPress \'Enter\' to close ...")