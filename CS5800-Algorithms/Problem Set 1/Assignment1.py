"""
This function converts the given integer to binary number and returns its string representation.

:param x - integer 
:returns - The result of the integer to binary number as a string.
"""
def int_to_binary_string(x):
	s = ''
	if x == 0:
		s = "0"
	while x:
		s = str(x & 1) + s
		x >>= 1
	return s

"""
This function computes modular exponentiation of the expression (a ^ x) mod n.

:param a - a term of the above expression  
:param x - x term of the above expression
:param n - n term of the above expression
:returns - The result of the modular exponentiation on the expression (a ^ x) mod n.
"""
def mod_exp(a, x, n):
	s = int_to_binary_string(x)
	#Output of integer to binary string
	print s

	exp = a % n
	result = 1

	for i in reversed(s):
		if(i == '1'):
			result = (result * exp) % n
		#Output of the iteration
		print exp
		exp = (exp * exp) % n
	#Returning the final result
	return result

#Taking user input
a, x, n = raw_input().split();

#Converting input string to int
a = int(a)
x = int(x)
n = int(n)

#Function call to compute modular exponentiation
print mod_exp(a, x, n)