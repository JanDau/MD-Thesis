###################################
# MST v1.1 JD 2016/12/02 - Docker #
###################################

orig = "ATCTATCCAGAAATCCTCTTTGCGACGGGAGACTAACCTTTTGATCT"



import regex, csv, os, sys
# from tkinter.filedialog import askopenfilename	# GUI for file selection


# User Interaction
# root = tkinter.Tk() 	# Initialize
# root.withdraw()			# Hide window
# usrFile = askopenfilename(defaultextension='.fna', filetypes=[('.fna Files', '.fna')], title='Choose .fna file')	# GUI for Choosing Files

# Docker edit ---
if len(sys.argv) == 2 and os.path.isfile(sys.argv[1]):
    usrFile = sys.argv[1]
else:
    raise ValueError("Either no file argument provided or the file does not exist.")
# ---------------

dictErrors = {i:[0,0,0] for i,e in enumerate(range(47))} # Sub, Ins, Del
debugMode = False # True/False
debugID = 13
listComp = [0,0,0] # Sub, Ins, Del
listOut = [] # 0:Sequence 1:Reads 2:Distance 3:DistRef 4:Err1 5:Err2 6:Err3 7:Err4 8:Err5 9:Err6 10:Err7 11:Err8 12:Err9

listFile = []
with open(usrFile) as f:
	for line in f:
		if line.startswith('Sequence'):
			continue
		lineSplit = line.split()
		listFile.append(lineSplit[0])
		listOut.append([lineSplit[0], lineSplit[1], lineSplit[2], 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])

listFileLen = len(listFile)
listSkipped = []

for i in range(0,listFileLen):
	#if i>805:
	#	print(i)
	
	doSkip = False
	useVar = False
	
	if i % (round(0.001*listFileLen,0)) == 0:	# Progress Output
		print ('Progress: {0:.1f}'.format(round(100*i/listFileLen,2)) + '%', end='\r')	# Progress Output
	
	for x in range(1,10): # test for the minimum amount of changes necessary (up to 9)
		ldist = regex.match(r'(?e)(' + orig + '){e<=' + str(x) + '}', listFile[i], flags=regex.IGNORECASE)
		ldistVar = regex.match(r'(?e)(' + listFile[i] + '){e<=' + str(x) + '}', orig, flags=regex.IGNORECASE)

		if ldist:
			if ldistVar:
				if sum(ldistVar.fuzzy_counts) < sum(ldist.fuzzy_counts) and (len(listFile[i])-ldistVar.fuzzy_counts[2]) >= len(orig):
					#print("ldistVar", ldistVar.fuzzy_counts)
					if (debugMode == True and i == debugID):
						print(ldist, ldistVar)
					useVar = True
					break
				else:
					#print("ldist", ldist.fuzzy_counts)
					break
			else:
				#print("ldist", ldist.fuzzy_counts)
				break
		else:
			if ldistVar:
				if (len(listFile[i])-ldistVar.fuzzy_counts[2]) == len(orig):
					#print("ldistVar", ldistVar.fuzzy_counts)
					useVar = True
					break
			else:
				if x == 9:
					doSkip = True
				else:
					continue
	
	if doSkip == True:
		#print('Skipped: ' + str(i))
		listSkipped.append(i)
		listOut[i][3] = 99
		continue
	
	if useVar == True:
		ldist = ldistVar
		int_sub = ldist.fuzzy_counts[0]
		int_ins = ldist.fuzzy_counts[2]
		int_del = ldist.fuzzy_counts[1]
		if (debugMode == True and i == debugID):
			print("Var genutzt")
			print("Anstelle von " + str(int_sub) + ' Subs, ' + str(int_ins) + ' Ins, ' + str(int_del) + ' Dels')
	else:
		int_sub = ldist.fuzzy_counts[0]
		int_ins = ldist.fuzzy_counts[1]
		int_del = ldist.fuzzy_counts[2]
	
	#for a, item in enumerate(listComp):
	#	listComp[a] += ldist.fuzzy_counts[a]
	listComp[0] += int_sub
	listComp[1] += int_ins
	listComp[2] += int_del
	
	
	if (debugMode == True and i == debugID):
		print("01234567891123456789212345678931234567894123456")
		print(orig,"Original")
		print(listFile[i],"Variable")
		print(str(int_sub) + ' Subs, ' + str(int_ins) + ' Ins, ' + str(int_del) + ' Dels')

	errors = sum(ldist.fuzzy_counts) # subs, ins, dels
	listOut[i][3] = errors

	#for x in range(0, len(orig)):
	errTemp = []
	x = 0
	while x < len(orig):
		#if (debugMode == True and i == debugID):
		#	print(x)
		if x >= len(listFile[i]):
			if (debugMode == True and i == debugID):
						print("Deletion an x=" + str(x))
			errTemp.append("del(" + str(x+1) + "," + orig[x] + ")")
			dictErrors[x][2] += 1
			int_del -= 1
			listFile[i] = listFile[i][:x] + orig[x]
			continue
		if (orig[x] != listFile[i][x]):
			if(int_sub > 0):	#	orig[x+1:]		listFile[i][x+1:] 
				testSub = regex.match(r'(?e)(' + orig[x+1:] + '){d<=' + str(int_del) + ',i<=' + str(int_ins) + ',s<=' + str(int_sub-1) + '}', listFile[i][x+1:], flags=regex.IGNORECASE)
				if testSub:
					if (debugMode == True and i == debugID):
						print("Substitution an x=" + str(x))
					errTemp.append("sub(" + str(x+1) + "," + orig[x] + ">" + listFile[i][x] + ")")
					dictErrors[x][0] += 1
					int_sub -= 1
					listFile[i] = listFile[i][:x] + orig[x] + listFile[i][x+1:]
					continue
			if(int_ins > 0): 	#	orig[x:]		listFile[i][x+1:] 
				testIns = regex.match(r'(?e)(' + orig[x:] + '){d<=' + str(int_del) + ',i<=' + str(int_ins-1) + ',s<=' + str(int_sub) + '}', listFile[i][x+1:], flags=regex.IGNORECASE)
				if testIns:
					if (debugMode == True and i == debugID):
						print("Insertion an x=" + str(x))
					errTemp.append("ins(" + str(x) + "_" + str(x+1) + "," + listFile[i][x] + ")")
					dictErrors[x][1] += 1
					int_ins -= 1
					listFile[i] = listFile[i][:x] + listFile[i][x+1:]
					continue
			if(int_del > 0):	#	orig[x+1:]		listFile[i][x:]
				testDel = regex.match(r'(?e)(' + orig[x+1:] + '){d<=' + str(int_del-1) + ',i<=' + str(int_ins) + ',s<=' + str(int_sub) + '}', listFile[i][x:], flags=regex.IGNORECASE)
				if testDel:
					if (debugMode == True and i == debugID):
						print("Deletion an x=" + str(x))
					errTemp.append("del(" + str(x+1) + "," + orig[x] + ")")
					dictErrors[x][2] += 1
					int_del -= 1
					#listFile[i] = listFile[i][:x] + "-" + listFile[i][x:]
					listFile[i] = listFile[i][:x] + orig[x] + listFile[i][x:]
					continue
		else:
			x += 1
	#print(x,str(int_sub) + ' Subs, ' + str(int_ins) + ' Ins, ' + str(int_del) + ' Dels')
	if (int_sub != 0 or int_ins != 0 or int_del != 0):
		print("Offene Fehler für: " + str(i) + " mit: " + str(int_del+int_sub+int_ins))
		print(str(int_sub) + ' Subs, ' + str(int_ins) + ' Ins, ' + str(int_del) + ' Dels')
		if (listFile[i][:len(orig)] == orig):
			print("Ignoriert, da Sequenzen 100% identisch")
			listComp[0] -= int_sub
			listComp[1] -= int_ins
			listComp[2] -= int_del
		
	if (listFile[i][:len(orig)] != orig):
		print("Nicht 100% Korrektur für: " + str(i))
	if (debugMode == True and i == debugID):
		print("01234567891123456789212345678931234567894123456")
		print(orig,"Original")
		print(listFile[i],"Corrected")
		break
	
	# Übertragen von errTemp in listOut
	for index, item in enumerate(errTemp):
		#print(index,item)
		listOut[i][4+index] = item

print ('Progress: 100.0%', end='\r')	# Progress Output
print('\nSequences with a distance >9:', ', '.join(map(str, listSkipped)))

w = open(os.path.split(usrFile)[0] + '/MST_' + os.path.split(usrFile)[1],'w')
w.write('Sequence Reads Distance DistRef Err1 Err2 Err3 Err4 Err5 Err6 Err7 Err8 Err9\r\n')
for i in range(0, len(listOut)):
	tempStr = ''
	for x in range(0,12):
		tempStr += str(listOut[i][x]) + ' '
	tempStr += str(listOut[i][12]) + '\r\n'
	w.write(tempStr)
w.close()

input("\nPress \'Enter\' to close ...")