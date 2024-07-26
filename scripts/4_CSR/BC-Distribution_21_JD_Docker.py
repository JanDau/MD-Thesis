###############################################
# BC Distribution v2.1 JD 2020/07/02 - Docker #
###############################################
usr_stats = True # if stats file shall be exported (True or False)
usr_print = list(range(2,19))   # which group export, set 0 to deactivate (0, 1, 2, ..., 18) or multiple as a list [1, 2, 3 ...]
usr_delim = ',' # Delimiter in csv files de -> ';' en -> ','

##################

# 0. Load modules
import sys, os, csv, math					#os for writing files
# from tkinter.filedialog import askopenfilenames	# GUI for file selection
from statistics import mean
from datetime import datetime 		# datetime -> script running time
from pathlib import Path

# 2. User Interaction
# Initialize GUI
# root = tkinter.Tk() 	# Initialize
# root.withdraw()			# Hide window

# # GUI
# Files = askopenfilenames(defaultextension='.fna', filetypes=[('.fna Files', '.fna')], title='Choose .fna files')
# Files = list(Files)		# Saves file paths as list to iterate through them
# dirSave = Path(__file__).parent

if len(sys.argv) == 2 and os.path.isdir(sys.argv[1]):
    usr_dir = sys.argv[1]
else:
    raise ValueError("No path argument provided.")

Files = [os.path.join(usr_dir, file) for file in os.listdir(usr_dir) if file.startswith("Merged_CS_")]
dirSave = Path("/JD/docker/export")


# 4. Main Routine
# 4.1 Reading of all samples
dictSeqPool = {}			# This directory saves all sequences (and its reads and distances) of related samples
header = 'Sequence'
for i in range(len(Files)):
	fileName = Path(Files[i]).stem
	header += usr_delim + fileName
	with open(Files[i]) as f:
		for line in f:
			if line.startswith('Sequence'):	# ... skip the header line ...
				continue
			lineSplit = line.split()	# split the lines by whitespace (because the structure is e.g. 'AATTCC 3 2')
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
	fileExportStats = dirSave / fname
	with fileExportStats.open(mode='w', newline='') as f:
		f.write('\r\n'.join('{x}{a}{y}'.format(a=usr_delim, x=x, y=y) for x,y in dictDistr.items()))
	print("\nStatistics csv file saved at " + str(fileExportStats))

# Group Export
for group in dictSeqs.keys():
	if(group in usr_print):
		fname = 'BC-Distr_Group_' + str(group) + '_' + datetime.now().strftime('%Y%m%d_%H%M%S') + '.csv'
		fileExportGroup = dirSave / fname
		with fileExportGroup.open(mode='w') as f:
			f.write(header + '\r\n')
			for seq, values in dictSeqs[group].items():
				val = [0 if math.isnan(x) else x for x in values]
				f.write(seq + usr_delim + usr_delim.join(map(str, val)) + '\r\n')
		print("\nGroup export csv file saved at " + str(fileExportGroup))

input("\nPress \'Enter\' to close ...")