# $Id: Makefile,v 1.2 2007/10/04 14:50:49 frabcus Exp $
# Compile the minwhirl Java applet

# The Public Whip, Copyright (C) 2006 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

# Make Java applet
radcls.jar: src/*.java
	# Use target of JDK 1.1 for compatibility with old applet viewers
	javac -target 1.1 -source 1.3 -d src/ src/*.java
	cd src;	jar cvf ../radcls.jar radialtree/*.class *.class


