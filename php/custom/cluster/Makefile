# $Id: Makefile,v 1.4 2007/07/19 20:47:26 frabcus Exp $
# Used to run the votemaping calculation, build the Java applet etc.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

all: mpscatt.jar mpcoords mpsee-1997.png mpsee-2001.png mpseethumb.png 
	cp mpcoords-1997.txt ../website/votemap
	cp mpcoords-2001.txt ../website/votemap
	cp mpsee-1997.png ../website/votemap
	cp mpsee-2001.png ../website/votemap
	cp mpseethumb.png ../website/votemap
	cp mpscatt.jar ../website

# Make file of coordinates of MPs - the perl script calls out
# to octave itself.  It also writes the raw distance metric
# to the database for use.
mpcoords:
	perl cluster-parliament-static.pl
.PHONY: mpcoords

# Make Java applet
mpscatt.jar: src/*.java
	# Use target of JDK 1.1 for compatibility with old applet viewers
	javac -target 1.1 -source 1.3 -d src/ src/*.java
	cd src;	jar cvf ../mpscatt.jar *.class

	#/usr/local/jdk1.3.1_17/bin/javac -d src/ src/*.java
	#cd src;	/usr/local/jdk1.3.1_17/bin/jar cvf ../mpscatt.jar *.class

# And version with PNG writing in it
mpframe.jar: src/*.java mpscatt.jar
	javac -Xlint:deprecation -cp src/ -d src1.4/ src1.4/*.java
	cd src;    jar cvf ../mpframe.jar *.class
	cd src1.4; jar uvf ../mpframe.jar *.class

# Test view the votemap
test: mpcoords-1997.txt mpscatt.jar
	java -classpath mpscatt.jar mpframe mpcoords-1997.txt

# Static graphic of votemap
mpsee-2001.png: mpcoords-2001.txt mpscatt.jar
	java -classpath mpscatt.jar mpframe mpcoords-2001.txt mpsee-2001.png 533 400
mpsee-1997.png: mpcoords-1997.txt mpscatt.jar
	java -classpath mpscatt.jar mpframe mpcoords-1997.txt mpsee-1997.png 533 400
mpseethumb.png: mpcoords-2001.txt mpscatt.jar
	java -classpath mpscatt.jar mpframe mpcoords-2001.txt mpseethumb.png 150 100

