# User defined settings ------------
userPoolsize = 85483 # mCherry: 155648, Cerulean: 85483 
userType1error = 0.025 	# Setting for the calculation of the clustering distance
						# It stands for the maximum percentage of sequences (from all sequences) that can be falsely clustered together (= Type I error)
						
####################################
######## Don't Change Below ########
####################################
import math

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

def clustDist (sequences):
	comparisons = ((sequences**2)-sequences)/2	# calculates the number of comparisons (subtracting double comparisons [e.g. A<->B & B<->A] and self comparisons [e.g. A<->A])
	# 4.3.2 Now determine the highest Cluster Distance which is possible for the given type 1 Error (userType1error)
	for x in range(0,17):	# max range again NOT included, that's why it's 17 instead of 16
		prob = dbinom(16,x,0.75)*comparisons	# multiply the probability of integral (0, x) with the amount of comparisons to receive an estimation how much sequences are statistically likely
		if prob > userType1error*sequences:		# if this amount is higher than the given type 1 Error times the number of total sequences...
			cDistance = x-1		# ... return the cluster distance (cDistance), which has to be x-1 because for the current x the prob is too high for the first time
			break				# ... and exit the loop
	return cDistance

# 4.3 Calculation of the Cluster Distance
if userPoolsize == 1:
	userPoolsize = 2
cDistance = clustDist(userPoolsize)
print(' -> Recommended Deviation Threshold: ' + str(cDistance))

input("\nPress \'Enter\' to close ...")