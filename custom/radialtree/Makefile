# $Id: Makefile,v 1.1 2006/09/28 12:42:32 frabcus Exp $
# Compile the minwhirl Java applet

# The Public Whip, Copyright (C) 2006 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

# Make Java applet
radcls.jar: src/*.java
	/usr/local/jdk1.3.1_17/bin/javac -d src/ src/*.java
	cd src;	/usr/local/jdk1.3.1_17/bin/jar cvf ../radcls.jar radialtree/*.class *.class


