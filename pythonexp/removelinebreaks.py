import sys

# this filter removes trailing angle brackets and linefeeds that break up tags


# in and out files for this filter
filein = "hocdaydebate2000-11-07.htm"
fileout = "f1hocdaydebate2000-11-07.htm"


fin = open(filein);
finr = fin.read()
fin.close()

fout = open(fileout, "w");

nline = 0
bInAngleBrack = 0
bInQuotes = 0
bInParameter = 0

i = 0
for c in finr:
	i = i + 1
	if c == '<':
		if bInParameter:
			print "bracket < in parameter quotes (okay) line %d" % nline
		elif bInQuotes:
			print "bracket < in quotes (okay) line %d" % nline
			print finr[i-50:i+50]
		elif bInAngleBrack:
			print "bracket < in bracket on line %d" % nline
   		else:
			bInAngleBrack = 1;

	elif c == '>':
		if bInParameter:
			print "bracket > in parameter quotes (okay) line %d" % nline
		elif bInQuotes:
			print "bracket > in quotes (okay) line %d" % nline;
		elif bInAngleBrack:
			bInAngleBrack = 0;
		else:
			print "floating bracket > on line %d" % nline

	elif c == '"':
		if bInParameter:
			bInParameter = 0;
		elif bInAngleBrack:
			bInParameter = 1;
		elif bInQuotes:
			bInQuotes = 0;
		else:
			bInQuotes = 1;

	# it's all about knowing when to discard a linefeed
	if bInAngleBrack and (c == '\n'):
		if bInParameter:
			print " removing linefeed in parameter on line %d" % nline
		else:
			print " removing linefeed in bracket on line %d" % nline

	elif c != '\r':
		fout.write(c);
		if c == '\n':
			if bInQuotes:
				print " killing quote state at end of line %d" % nline
				bInQuotes = 0;
			nline = nline + 1;

#endfor k in file
if bInQuotes or bInAngleBrack or bInParameter:
	print "File ended without closing bracketing";
print " nlines ", nline

fout.close()



