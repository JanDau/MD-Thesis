##############################################
# Create Library v2.4 JD 2021/01/06 - Docker #
##############################################

# User defined settings ------------
userFixedCD = 2			# Option whether a fix CD should be used or not. Possible values: False, 1, 2, 3, ...
userType1error = 0.01 	# Is IGNORED if userFixedCD != False
						# Otherwise it is used for the calculation of the clustering distance
						# It stands for the maximum percentage of sequences (from all sequences) that can be falsely clustered together (= Type I error)
userUseStrinLen = True	# Is IGNORED if userFixedCD != False
						# Otherwise it defines whether  calculation of CD should be based on the number of stringent sequences only
						
####################################
######## Don't Change Below ########
####################################

version = '2.4'

# 0. Load modules
import csv, regex, re, os, math		# regex for Levenshtein distance, os for writing files, math for n-faculty
from operator import itemgetter					# for sorting
from datetime import datetime 		# datetime -> script running time			# for sorting
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

def runningTime (startTime, endTime):
	dTime = endTime-startTime
	if dTime.days > 0:
		runTime = str(dTime.days) + ' day(s), ' + str(dTime.seconds//3600) + ' hour(s), ' + str((dTime.seconds%3600)//60) + ' minute(s), ' +  str((dTime.seconds%3600)%60) + ' second(s).\n'
	else:
		if dTime.seconds >= 3600:
			runTime = str(dTime.seconds//3600) + ' hour(s), ' + str((dTime.seconds%3600)//60) + ' minute(s) and ' +  str((dTime.seconds%3600)%60) + ' second(s).\n'
		else:
			if dTime.seconds >= 60:
				runTime = str(dTime.seconds//60) + ' minute(s) and ' + str(dTime.seconds%60) + ' second(s).\n'
			else:
				runTime = str(dTime.seconds) + ' second(s).\n'
	return runTime

def clustDist (sequences):
	comparisons = ((sequences**2)-sequences)/2	# calculates the number of comparisons (subtracting double comparisons [e.g. A<->B & B<->A] and self comparisons [e.g. A<->A])
	# 4.3.2 Now determine the highest Cluster Distance which is possible for the given type 1 Error (userType1error)
	for x in range(0,17):	# max range again NOT included, that's why it's 17 instead of 16
		prob = dbinom(16,x,0.75)*comparisons	# multiply the probability of integral (0, x) with the amount of comparisons to receive an estimation how much sequences are statistically likely
		if prob > userType1error*sequences:		# if this amount is higher than the given type 1 Error times the number of total sequences...
			cDistance = x-1		# ... return the cluster distance (cDistance), which has to be x-1 because for the current x the prob is too high for the first time
			break				# ... and exit the loop
	return cDistance

# 2. User Interaction
# # Initialize GUI
# root = tkinter.Tk() 	# Initialize
# root.withdraw()			# Hide window

# # GUI
# Files = askopenfilenames(defaultextension='.fna', filetypes=[('.fna Files', '.fna')], title='Choose .fna files to cluster')
# Files = list(Files)		# Saves file paths as list to iterate through them
# dirFile = os.path.split(Files[0])[0]


def get_files_from_directory(directory_path, extension=".fna"):
    """Get all files with the specified extension from the given directory."""
    return glob.glob(os.path.join(directory_path, '*' + extension))

def process_arguments(arguments):
    """Process the command line arguments to get a list of files."""
    files_to_process = []
    for arg in arguments:
        if os.path.isdir(arg):
            # If the argument is a directory, get all .fna files within it
            files_to_process.extend(get_files_from_directory(arg))
        elif os.path.isfile(arg):
            # If the argument is a file, add it to the list
            files_to_process.append(arg)
        else:
            print(f"Warning: {arg} is not a valid file or directory and will be ignored.")
    return files_to_process

# Initialize the parser
parser = argparse.ArgumentParser(description='Process .fna files or directories containing them.')
parser.add_argument('paths', type=str, nargs='+',
                    help='The path(s) to .fna files or directories containing .fna files')

# Parse the arguments
args = parser.parse_args()

# Process the arguments to get a list of files
Files = process_arguments(args.paths)

def natural_sort_key(s):
    return [int(text) if text.isdigit() else text.lower() for text in re.split('([0-9]+)', s)]

Files = sorted(Files, key=natural_sort_key)

dirFile = args.paths[0]
# dirFile = os.path.split(Files[0])[0]


tmpName = re.search(r'(preTX_)?SF-(3T|T|3)#?(?:[1-6])?', dirFile)
if tmpName:
	fName = "Lib-" + tmpName.group(0) + ".fna"
else:
	fName = "Lib.fna"
print(fName)

# 3. Shell Output with chosen files, directory, settings, ...
startTime = datetime.now()	# Script starting time
outputHeader = ('##########################\n# Create Library v' + version + ' JD #\n##########################',
				'Script started at: ' + startTime.strftime('%Y-%m-%d %H:%M:%S') + '\n',
				'Fixed CD: ' + str(userFixedCD),
				'Type I Error: ' + str(userType1error),
				'Stringents for CD only: ' + str(userUseStrinLen),
				'Save Path: ' + dirFile + '/' + fName)
print('\n'.join('{}'.format(x) for x in outputHeader))
print('Execution of Script can be aborted by pressing \'Ctrl + C\'.\n')
print('---------------------------------')
# writeStatistics = open(dirFile + '/Statistics_' + startTime.strftime('%Y-%m-%d_%H-%M-%S') + '.txt', 'w')
writeStatistics = open(os.path.join(dirFile, 'Statistics_' + startTime.strftime('%Y-%m-%d_%H-%M-%S') + '.txt'), 'w')
writeStatistics.write('\r\n'.join('{}'.format(x) for x in outputHeader))

# 4. Main Routine
# 4.1 Reading of all samples
infoFileNr = 0
infoStringent = 0
dictSeqPool = {}			# This directory saves all sequences (and its reads and distances) of related samples
outputShell = ['\nFiles included:']
for File in Files:	# allFiles contains the sublists of libraryLine, e.g. [Sample1.1, Sample1.2]
	
	#4.1 Shell Output
	infoFileNr += 1
	fileName = os.path.split(File)[1]
	
	outputShell.append('   * ' + fileName)
	print(' -> Reading samples: ' + fileName + ' (File ' + str(infoFileNr) + ' of ' + str(len(Files)) + ')', end='\r')
	
	# 4.2 Load all sequences of related Samples in a dictionary
	# with open(File) as f:
	with open(File, 'r', encoding='utf-8') as f:
		for line in f:
			if line.startswith('Sequence'):	# ... skip the header line ...
				continue
			lineSplit = line.split()	# split the lines by whitespace (because the structure is e.g. 'AATTCC 3 2')
			if lineSplit[0] not in dictSeqPool:
				dictSeqPool[lineSplit[0]] = [int(lineSplit[1]), int(lineSplit[2]), 0] #key = Sequence, Values: 0 = Reads, 1 = Distance, 2 = Group
				if int(lineSplit[2]) == 0:
					infoStringent += 1
			else:
				dictSeqPool[lineSplit[0]][0] += int(lineSplit[1])	# otherwise add the read count to the existing sequence

# 4.3 Calculation of the Cluster Distance
if userFixedCD == False:
	if userUseStrinLen == True:
		cDistance = clustDist(infoStringent)
	else:
		cDistance = clustDist(len(dictSeqPool))
else:
	cDistance = userFixedCD

print(' -> Reading samples: Done                                        ')

outputShell.append(' -> Used Cluster Distance (CD) for Sample Set: ' + str(cDistance))
if userUseStrinLen == True:
	print(' -> # of stringent sequences: ' + str(infoStringent) + '     ')
print(outputShell[1+infoFileNr])

# 4.4 Convert dictSeqPool into a List ('listSeqPool') and Sort
listSeqPool = []
for key, value in dictSeqPool.items():
	listSeqPool.append([key, value[0], value[1], value[2]]) #0 = Sequence, 1 = Reads, 2 = Distance, 3 = Group

# 4.5 Sorting of listSeqPool: 1st criterium: Distance (ascending, attribute 2), 2nd criterium: Reads (descending, attribute 1)
listSeqPool = sorted(listSeqPool, key=itemgetter(1), reverse=True)	# To achieve our sorting criteria, we need to sort the 2nd first (Reads, desc.)
listSeqPool = sorted(listSeqPool, key=itemgetter(2), reverse=False)	# And now sort for the 1st criterium (Distance, asc)
		
# 4.6 Grouping
listSeqPoolLength = len(listSeqPool)
groupNr = 1		# Variable for setting the group number
infoSeqNr = 0	# Variable for tracking Progress
print(' -> Creating Library: {0:.1f}'.format(0) + '%', end='\r')	# Progress Output
for i in listSeqPool:	# iterate through every sequence in the list 'listSeqPool'
			
	# 4.6.1 Shell Output
	infoSeqNr += 1			# Increase progress variable
	if listSeqPoolLength > 1000:	# Show Progress for Files with > 1000 sequences
		if infoSeqNr % (round(0.001*listSeqPoolLength,0)) == 0:	# Progress Output
			print(' -> Creating Library: {0:.1f}'.format(round(100*infoSeqNr/listSeqPoolLength,1)) + '%', end='\r')	# Progress Output
			
	# 4.6.2 Routine
	if i[3] != 0:		# if the sequence belongs to a group already ...
		continue									# ...skip this sequence
	i[3] = groupNr		# otherwise assign the current group number to it
	for x in listSeqPool:	# now iterate with the current sequence again through every sequence in dictFile
		if x[3] != 0:	# here again, ignore sequences that already belong to a group
			continue
		ldist = regex.match(r'(?e)(' + i[0] + '){e<=' + str(cDistance) + '}', x[0], flags=regex.IGNORECASE)	# if the sequence doesn't have a group yet, match the i and x sequence
																											# it can only be matched if the errors are <= determined cDistance
		if ldist:																							# so if it can be matched, they will be grouped
			x[3] = groupNr			# assign the same group number for the 'x' sequence like for our parent 'i' sequence
	groupNr += 1					# afterwards (iterated through all 'x' sequences), the groupNr variable can be increased by 1

# 4.7 Create Sequence Replacing Dictionary ('dictLibrary')
dictLibrary = {}	# keys = all sequences of the sample, value = sequence to be grouped to
for i in range(1,groupNr):
	# 4.7.1 Load one group into a temporary list ('listTemp')
	listTemp = []
	for x in listSeqPool:	# Iterate through all sequences...
		if x[3] == i:	# ... if the group value of the sequence 'x' is the same as our current groupNr 'i'...
			listTemp.append([x[0], int(x[1]), int(x[2]), int(x[3])])	# ... append it to 'listTemp' with all values
	
	# 4.7.2 Sort listTemp: 1st criterium: Distance (ascending, attribute 2), 2nd criterium: Reads (descending, attribute 1)
	listTemp = sorted(listTemp, key=itemgetter(1), reverse=True)	# Again we have to sort for the reads first
	listTemp = sorted(listTemp, key=itemgetter(2), reverse=False)	# And then for the distance
	
	# 4.7.3 Set all sequences of this group as keys in dictLibrary and assign the sequences that has the lowest Distance and highest Reads as their value
	for x in listTemp:
		dictLibrary[x[0]] = [listTemp[0][0], listTemp[0][2], i]
			
	# 4.7.4 DEBUGGING OUTPUT OF GROUP LIST
	#if i == 1:	# Group 1 only
		#print('\n'.join('{}'.format(x) for x in listTemp))
		#print('\n'.join('{} {}'.format(key, value) for key, value in dictLibrary.items()))

print (' -> Creating Library: Done   ')

writeStatistics.write('\r\n'.join('{}'.format(x) for x in outputShell) + '\r\n')
# Write Library File as .fna
# writeFile = open(dirFile + '/' + fName, 'w')		# Create and Open the File
# writeFile = open(os.path.join(dirFile, fName), 'w')		# Create and Open the File
# writeFile.write('Sequence ClusteredTo Distance Library\r\n' +											# Add Header to File
				# '\r\n'.join('{} {} {} {}'.format(x,y[0],y[1],y[2]) for x,y in dictLibrary.items()) +	# Add all Sequences and Reads (seperated by whitespace) of dictLibrary
				# '\r\n')															# Last line break to ensure functionality of other scripts
# writeFile.close()	

with open(os.path.join(dirFile, fName), 'w', newline=None) as writeFile:		# Create and Open the File
	writeFile.write('Sequence ClusteredTo Distance Library\n')					# Add Header to File
	writeFile.write('\n'.join('{} {} {} {}'.format(x,y[0],y[1],y[2]) for x,y in dictLibrary.items()) + '\n') # Add all Sequences and Reads (seperated by whitespace) of dictLibrary


# 7. Final Shell Output
# Get Running Time
runTime = runningTime(startTime, datetime.now())

# Generate Footer information
outputFooter = ('\n##############\n# Statistics #\n##############',
				'Script finished at: ' + datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
				'Running time: ' + runTime)

# Print to Shell
print('\n'.join('{}'.format(x) for x in outputFooter))

# Write to statistics file
writeStatistics.write('\r\n'.join('{}'.format(x) for x in outputFooter))
writeStatistics.close()

input("\nPress \'Enter\' to close ...")