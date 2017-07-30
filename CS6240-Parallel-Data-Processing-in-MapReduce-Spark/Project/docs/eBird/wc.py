l = []

with open("columns", "r") as f:
	for line in f:
		l = line.split(",")

print len(l)