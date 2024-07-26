#################################
# Clustering v2.1 JD 2018/08/14 #
#################################

# User defined settings ------------
user_fixed_CD = 2	# Option whether a fix CD should be used or not. Possible values: False, 1, 2, 3, ...
type1Prob = 0.01 		# Setting for the calculation of the clustering distance
						# It stands for the maximum percentage of sequences (from all sequences) that can be falsely clustered together (= Type I error)
highestDeviation = 2	# With this number you can decide which sequences are allowed to create a cluster where other sequences can be grouped to
						# the number stands for their amount of errors im comparison to the original barcode structure
						# e.g. 0 would mean, that only sequences with a fully intact structure can serve as a cluster centrum
						# and only those sequences will appear in the clustered file (with the added read counts from their groupped sequences)
saveDumbFiles = True	# Set True or False, will be saved in 'Dumb' folder
						
####################################
######## Don't Change Below ########
####################################

version = '2.1'

# 0. Load modules
# import tkinter
import regex, re, os, math					# tkinter for GUI, regex for Levenshtein distance, os for writing files, math for n-faculty
# from tkinter.filedialog import askopenfilenames	# GUI for file selection
from operator import itemgetter					# for sorting
from datetime import datetime 		# datetime -> script running time
import argparse, glob

# 1. Functions
def dbinom (n, k, p):	# Binomial Distribution Function (outputs the integral), similiar to pbinom() in R
	final = []					# List that saves results for every k
	for x in range(0,k+1):		# we always need the integral (0, k) that's why we iterate from 0 to k
		if x > n:				# cave: the stop value in range is NOT included, therefore it's k+1
			final.append(0)		# if x is higher than n, just return 0 (it's not possible to calculate)
		else:
			coeff = math.factorial(n)/((math.factorial(x))*(math.factorial(n-x)))	# this equals ne binomial coefficient (n over k) = n!/(k!(n-k)!)
			distr = coeff*(p**x)*((1-p)**(n-x))		# this is the formula for the binomial probability: (n over k) * p^k * (1-p)^(n-k)
			final.append(distr)						# the the value for this k in the 'final' list and go to next x
	return sum(final)			# sum all values to receive the integral (0, k)

# 2. User Interaction
# # Initialize GUI
# root = tkinter.Tk() 	# Initialize
# root.withdraw()			# Hide window
# # GUI for Choosing Files to Cluster
# Files = askopenfilenames(defaultextension='.fna', filetypes=[('.fna Files', '.fna')], title='Choose .fna files to cluster')
# Files = list(Files)		# Saves file paths as list to iterate through them

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
Files = get_fna_files(args.directory)

def natural_sort_key(s):
    return [int(text) if text.isdigit() else text.lower() for text in re.split('([0-9]+)', s)]

Files = sorted(Files, key=natural_sort_key)

# ---- Docker edit END -----

# Create 'Clustered' directory in the directory of the files
if user_fixed_CD != False:
	dirClustered = os.path.split(Files[0])[0] + '/Clustered_CD' + str(user_fixed_CD)
	dirDumb = os.path.split(Files[0])[0] + '/Dumb_CD' + str(user_fixed_CD)
	info_fix_CD = str(user_fixed_CD)
else:
	dirClustered = os.path.split(Files[0])[0] + '/Clustered'
	dirDumb = os.path.split(Files[0])[0] + '/Dumb'
	info_fix_CD = 'False'
if not os.path.exists(dirClustered):
	os.mkdir(dirClustered)


# 3. Shell Output with chosen files, directory, settings, ...
startTime = datetime.now()	# Script starting time
outputHeader = ('######################\n# Clustering v' + version + ' JD #\n######################',
				'Script started at: ' + startTime.strftime('%Y-%m-%d %H:%M:%S') + '\n',
				'User-defined CD: ' + info_fix_CD,
				'Type I Error: ' + str(type1Prob),
				'Highest Deviation: ' + str(highestDeviation),
				'Files: ' + str(len(Files)) + ' files in ' + os.path.split(Files[0])[0],
				'Save Path: ' + dirClustered + '\n')
print('\n'.join('{}'.format(x) for x in outputHeader))
print('Execution of Script can be aborted by pressing \'Ctrl + C\'.\n')
print('---------------------------------')
writeStatistics = open(dirClustered + '/Statistics_' + startTime.strftime('%Y-%m-%d_%H-%M-%S') + '.txt', 'w')
writeStatistics.write('\r\n'.join('{}'.format(x) for x in outputHeader))

# 4. Main Routine
infoFileNr = 0
for File in Files:		# Loop over all files that were selected
	
	# 3.0 Shell Output
	infoFileNr += 1
	outputShell = ['\n' + startTime.strftime('%Y-%m-%d %H:%M:%S') + ' File ' + str(infoFileNr) + ' of ' + str(len(Files)) + ' (' + os.path.split(File)[1] + ') -------------------']
	print(outputShell[0])
	
	# 3.1 Load current file into a list of lists
	dictFile = []			# dictFile = [['AATTCC', 3, 2], ['GGAATT', 2, 0], ...] where 0 = Sequence, 1 = Reads, 2 = Distance
	with open(File) as f:	# to realize this, open the current File...
		for line in f:		# ... read line by line ...
			if line.startswith('Sequence'):	# ... skip the header line ...
				continue
			lineSplit = line.split()	# split the lines by whitespace (because the structure is e.g. 'AATTCC 3 2')
			if len(lineSplit) >3:
				dictFile.append([lineSplit[0], int(lineSplit[1]), int(lineSplit[2]), int(lineSplit[3]), 0])	# and append this line as a list element in the main list 'dictFile'
				int_group_col = 4
			else:																							# further add a 3rd value for each sequence which is the group (value = 0)
				dictFile.append([lineSplit[0], int(lineSplit[1]), int(lineSplit[2]), 0])					# 0 = Sequence, 1 = Reads, 2 = Distance, (3 = Library), 4 = Group
				int_group_col = 3
				
	# 3.2 Calculation of the Cluster Distance
	# 3.2.1 Calculate the Number of Comparisons possible for amount of sequences
	dictFileLength = len(dictFile)		# saves the amount of sequences
	
	for x in range(0,17):	# max range again NOT included, that's why it's 17 instead of 16
		clusteredPreviously = 0	# sequences that are already clustered to previous sequences
		
		for a in range(1,dictFileLength+1):	# iterate through all sequences
			clusteredCurrently = dbinom(16,x,3/4)*(dictFileLength-a-clusteredPreviously)	# amount of sequences that are clustered to the current sequence
																							# subtract seq already iterated through (a) and seq that were
																							# already clustered to previous seq (clusteredPreviously)
			if clusteredCurrently > 0:	# if the amount of seq is > 0 ...
				clusteredPreviously += clusteredCurrently	# save it
				
		clusteredPerc = clusteredPreviously/dictFileLength # set it into % relation to # of total sequences
		
		if clusteredPerc > type1Prob:	# if % clustered is higher than the determined type 1 error
			cDistance = x-1		# take the previous cluster distance (x) as the one to work with
			break
	
	# 3.2.3 Shell Output
	if user_fixed_CD != False:
		cDistance = user_fixed_CD
		outputShell.append(' -> User-defined Cluster Distance: ' + str(cDistance))
	else:
		outputShell.append(' -> Individually determined Cluster Distance: ' + str(cDistance))
	print(outputShell[1])
	
	# 3.3 Sorting of dictFile: 1st criterium: Library (ascending), 2nd Distance (ascending), 3rd criterium: Reads (descending)
	dictFile = sorted(dictFile, key=itemgetter(1), reverse=True)	# To achieve our sorting criteria, we need to sort the 3rd first (Reads, desc.)
	dictFile = sorted(dictFile, key=itemgetter(2), reverse=False)	# Then the 2nd (Distance, asc)
	dictFile = sorted(dictFile, key=itemgetter(3), reverse=False)	# At least the 1st (Library, asc)
	
	# 3.4 Grouping
	groupNr = 1		# Variable for setting the group number
	infoSeqNr = 0	# Variable for tracking Progress
	for i in dictFile:	# iterate through every sequence in the list 'dictFile'
		
		# 3.4.1 Shell Output
		infoSeqNr += 1			# Increase progress variable
		if dictFileLength > 1000:	# Show Progress for Files with > 1000 sequences
			if infoSeqNr % (round(0.001*dictFileLength,0)) == 0:	# Progress Output
				print (' -> Progress: {0:.1f}'.format(round(100*infoSeqNr/dictFileLength,1)) + '%', end='\r')	# Progress Output
		
		# 3.4.2 Routine
		if (i[int_group_col] != 0) | (i[2] > highestDeviation):		# if the sequence belongs to a group already or it's distance is higher than initially determined (highestDeviation)...
			continue									# ...skip this sequence
		i[int_group_col] = groupNr		# otherwise assign the current group number to it
		for x in dictFile:	# now iterate with the current sequence again through every sequence in dictFile
			if x[int_group_col] != 0:	# here again, ignore sequences that already belong to a group
				continue
			ldist = regex.match(r'(?e)(' + i[0] + '){e<=' + str(cDistance) + '}', x[0], flags=regex.IGNORECASE)	# if the sequence doesn't have a group yet, match the i and x sequence
																												# it can only be matched if the errors are <= determined cDistance
			if ldist:																							# so if it can be matched, they will be grouped
				x[int_group_col] = groupNr									# assign the same group number for the 'x' sequence like for our parent 'i' sequence
		groupNr += 1											# afterwards (iterated through all 'x' sequences), the groupNr variable can be increased by 1

	# 3.5 Summarize Groups
	dictFinal = {}				# this dictionary 'dictFinal' receives the Sequences as keys and one value for each key, which are the Reads
	for i in range(1,groupNr):	# iterate through all groups (excluding 0 because these sequences weren't grouped and they are exluded from beeing a cluster centrum [by highestDeviation])
								# groupNr is correct this time because the variable was increased by 1 at the very end of the loop before (without assigning sequences to it)
		# 3.5.1 Create a Temporary List with Sequences of one Group
		dictTemp = []		# Temporary List
		for x in dictFile:	# Iterate through all sequences...
			if x[int_group_col] == i:	# ... if the group value of the sequence 'x' is the same as our current groupNr 'i'...
				if int_group_col >3:
					dictTemp.append([x[0], int(x[1]), int(x[2]), int(x[3]), int(x[4])])	# ... append it to 'dictTemp' with all values
				else:
					dictTemp.append([x[0], int(x[1]), int(x[2]), int(x[3])])
					
		# 3.5.2 Sort dictTemp: 1st criterium: Library (asc), 2nd Distance (ascending), 3rd: Reads (descending)
		dictTemp = sorted(dictTemp, key=itemgetter(1), reverse=True)	# Again we have to sort for the 3rd
		dictTemp = sorted(dictTemp, key=itemgetter(2), reverse=False)	# then 2nd
		dictTemp = sorted(dictTemp, key=itemgetter(3), reverse=False)	# And then for the 1st
		
		# 3.5.3 Copy the First Sequences (1st: highest library id, 2nd: less distance, 3rd: highest Reads) to 'dictFinal' and assign Reads as the Sum of Reads from this Group
		dictFinal[dictTemp[0][0]] = [sum([x[1] for x in dictTemp]), dictTemp[0][2], dictTemp[0][3]]
		
		# # 3.5.4 DEBUGGING OUTPUT OF GROUP LIST
		# if i == 1:	# Group 1 only
			# writeFile1 = open(dirClustered + '/Groups_' + os.path.split(File)[1], 'w+')	# Create and open file
			# writeFile1.write('Sequence Reads Distance Group\n')
			# writeFile1.write('\n'.join('{} {} {} {}'.format(x[0],x[1],x[2],x[3]) for x in dictTemp))
			# writeFile1.close()
	
	# 4. Write to File
	writeFile = open(dirClustered + '/' + os.path.split(File)[1], 'w')				# Create and Open the File in 'Clustered'
	if int_group_col >3:
		writeFile.write('Sequence Reads Distance Library\r\n')												# Add Header to File
		writeFile.write('\r\n'.join('{} {} {} {}'.format(x,y[0],y[1],y[2]) for x,y in dictFinal.items()))	# Add all Sequences and Reads (seperated by whitespace) of dictFinal
	else:
		writeFile.write('Sequence Reads Distance\r\n')												# Add Header to File
		writeFile.write('\r\n'.join('{} {} {}'.format(x,y[0],y[1]) for x,y in dictFinal.items()))	# Add all Sequences and Reads (seperated by whitespace) of dictFinal
	writeFile.write('\r\n')															# Last line break to ensure functionality of other scripts
	writeFile.close()																# Close the File
	
	# 5. Dumb Information
	dictDumb = {}					# Dictionary for non grouped sequences
	for i in dictFile:				# Find them in dictFile ...
		if i[int_group_col] == 0:				# ... by Group value == 0
			if int_group_col >3:
				dictDumb[i[0]] = [i[1],i[2],i[3]]	# ... and add them to dictDumb
			else:
				dictDumb[i[0]] = [i[1],i[2]]
	dictDumbSeq = len(dictDumb)
	dictDumbSeqRel = round(100*dictDumbSeq/dictFileLength)
	if int_group_col >3:
		dictDumbReads = sum(a for a, _, _ in dictDumb.values())
	else:
		dictDumbReads = sum(a for a, _ in dictDumb.values())
	dictFileReads = sum([x[1] for x in dictFile])
	dictDumbReadsRel = round(100*dictDumbReads/dictFileReads)
	if dictDumbSeq > 0:
		dictDumbMax = max(item[0] for item in dictDumb.values())
		dictDumbMaxRel = round(100*dictDumbMax/dictFileReads,3)
	else:
		dictDumbMax = dictDumbMaxRel = 0
	
	# 6. Write Dumb File if wanted
	
	if saveDumbFiles and dictDumbSeq > 0:
		if not os.path.exists(dirDumb):
			os.mkdir(dirDumb)
		writeDumb = open(dirDumb + '/' + os.path.split(File)[1], 'w')					# Create and Open the File in 'Dumb'
		if int_group_col >3:
			writeDumb.write('Sequence Reads Distance Library\r\n')												# Add Header to File
			writeDumb.write('\r\n'.join('{} {} {} {}'.format(x,y[0],y[1],y[2]) for x,y in dictDumb.items()))	# Add all Sequences and Reads (seperated by whitespace) of dictDumb
		else:
			writeDumb.write('Sequence Reads Distance\r\n')												# Add Header to File
			writeDumb.write('\r\n'.join('{} {} {}'.format(x,y[0],y[1]) for x,y in dictDumb.items()))	# Add all Sequences and Reads (seperated by whitespace) of dictDumb
		writeDumb.write('\r\n')															# Last line break to ensure functionality of other scripts
		writeDumb.close()																# Close the File
	
	# 7. Shell Output
	print (' -> Progress: 100.0%')
	outputShell.append(' -> Dumb statistics: Seq.=' + str(dictDumbSeq) + '/' + str(dictFileLength) + ' (' + str(dictDumbSeqRel) + '%), '
						'Reads=' + str(dictDumbReads) + '/' + str(dictFileReads) + ' (' + str(dictDumbReadsRel) + '%), '
						'Highest Read Count=' + str(dictDumbMax) + ' (' + str(dictDumbMaxRel) + '%)')
	print(outputShell[2])
	writeStatistics.write('\r\n'.join('{}'.format(x) for x in outputShell))

# 7. Final Shell Output
# Calculate Running Time
endTime = datetime.now()-startTime
if endTime.days > 0:
	runTime = str(endTime.days) + ' day(s), ' + str(endTime.seconds//3600) + ' hour(s), ' + str((endTime.seconds%3600)//60) + ' minute(s), ' +  str((endTime.seconds%3600)%60) + ' second(s).\n'
else:
	if endTime.seconds >= 3600:
		runTime = str(endTime.seconds//3600) + ' hour(s), ' + str((endTime.seconds%3600)//60) + ' minute(s) and ' +  str((endTime.seconds%3600)%60) + ' second(s).\n'
	else:
		if endTime.seconds >= 60:
			runTime = str(endTime.seconds//60) + ' minute(s) and ' + str(endTime.seconds%60) + ' second(s).\n'
		else:
			runTime = str(endTime.seconds) + ' second(s).\n'

# Generate Footer information
outputFooter = ('\n##############\n# Statistics #\n##############',
				'Script finished at: ' + datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
				'Running time: ' + runTime,
				'Files clustered: ' + str(infoFileNr) + ' of ' + str(len(Files)),
				'Saved in: ' + dirClustered)

# Print to Shell
print('\n'.join('{}'.format(x) for x in outputFooter))

# Write to statistics file
writeStatistics.write('\r\n'.join('{}'.format(x) for x in outputFooter))
writeStatistics.close()

input("\nPress \'Enter\' to close ...")