#############################################
# FASTQ Convert v1.0 JD 2016/11/29 - Docker #
#############################################
# open the script in the Docker container like this 
# python your_script.py /path/in/container/data/raw_data.fastq

# 0. Load modules
import sys, os

# 1. User Interaction
if len(sys.argv) > 1:
    fastqFile = sys.argv[1]
else:
    raise ValueError("Please provide the FASTQ file path as an argument.")
    
print('Converting to FASTA\nInitializing...')

def file_length(filename):
    with open(filename) as f:
        for i, lines in enumerate(f):
            pass
    return i + 1
# Determination
fileLength = file_length(fastqFile) # Length
currLine = 0 # variable for progress

readSeq = False
seq = ''
fastaFile = []

with open(fastqFile) as f:
	for line in f:
		currLine += 1			# Progress variable
		#if currLine < 70:
		#	print(line)
		if fileLength > 10000:	# Show Progress for Files with > 10000 lines
			if currLine % (round(0.0001*fileLength,0)) == 0:	# Progress Output
				print ('Progress: {0:.2f}'.format(round(100*currLine/fileLength,2)) + '%', end='\r')	# Progress Output
		if readSeq == True:
			if line[:1] == '+':
				fastaFile.append(seq)
				readSeq = False
				seq = ''
			else:
				if line[:1] != '@':
					seq += line.rstrip('\n')
		if line[:1] == '@':
			readSeq = True

print('\nExporting...')
			
fileName = os.path.split(fastqFile)[1]
fileExport = os.path.split(fastqFile)[0] + "/" + fileName[:fileName.find(".fastq")] + ".fna"

# Open the file for writing with Windows line endings
with open(fileExport, 'w') as writeHandle:
    for index, item in enumerate(fastaFile):
        writeHandle.write('>Sequence' + str(index+1) + '\r\n' + item + '\r\n')
	
print('\n' + str(len(fastaFile)) + ' sequences converted.')
input("\nPress \'Enter\' to close ...")