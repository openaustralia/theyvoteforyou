# $Id: Makefile,v 1.3 2003/09/19 16:06:36 frabcus Exp $
# Used to run the clustering calculation, build the Java applet etc.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

all: mpscatt.jar mpcoords.txt mpsee.png mpseethumb.png 
	cp mpcoords.txt ../website
	cp mpsee.png ../website
	cp mpseethumb.png ../website
	cp mpscatt.jar ../website

# Make file of coordinates of MPs - the perl script calls out
# to octave itself.  It also writes the raw distance metric
# to the database for use.
mpcoords.txt:
	cluster-parliament-static.pl
.PHONY: mpcoords.txt

# Make Java applet
mpscatt.jar: src/*.java
	javac -d . src/*.java
	jar cvf mpscatt.jar *.class
	rm *.class

# Test view the cluster
test: mpcoords.txt mpscatt.jar
	java -classpath mpscatt.jar mpframe mpcoords.txt

# Static graphic of cluster
mpsee.png: mpcoords.txt mpscatt.jar
	java -classpath mpscatt.jar mpframe mpcoords.txt mpsee.png 533 400
mpseethumb.png: mpcoords.txt mpscatt.jar
	java -classpath mpscatt.jar mpframe mpcoords.txt mpseethumb.png 150 150

