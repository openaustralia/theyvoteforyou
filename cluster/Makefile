# $Id: Makefile,v 1.2 2003/09/17 14:27:42 frabcus Exp $
# Used to run the clustering calculation, build the Java applet etc.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

all: mpscatt.jar mpcoords.txt mpsee.png mpseethumb.png db
	cp mpsee.png ../website
	cp mpseethumb.png ../website
	cp mpscatt.jar ../website
.PHONY: all

# Make Java applet
mpscatt.jar: src/*.java
	javac -d . src/*.java
	jar cvf mpscatt.jar *.class
	rm *.class

# Make distance matrix file
DN.m:
	rm -f DN.m
	./octavein.pl > DN.m
.PHONY: DN.m

# Make file of coordinates of MPs
mpcoords.txt: DN.m
	octave --silent mds.m

# Copy into database table
db: mpcoords.txt
	cat mpcoords.txt | ./mpcoords2db.pl > ../website/mpcoords-eigen.inc

# Test view the cluster
test: mpcoords.txt mpscatt.jar
	java -classpath mpscatt.jar mpframe mpcoords.txt

# Static graphic of cluster
mpsee.png: mpcoords.txt mpscatt.jar
	java -classpath mpscatt.jar mpframe mpcoords.txt mpsee.png 533 400
mpseethumb.png: mpcoords.txt mpscatt.jar
	java -classpath mpscatt.jar mpframe mpcoords.txt mpseethumb.png 150 150

