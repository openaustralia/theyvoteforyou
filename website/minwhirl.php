<?php $title = "Ministerial whirl"; include "header.inc" 
# $Id: minwhirl.php,v 1.2 2004/11/20 00:16:48 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.
?>

<p><span class="ptitle">Instructions: </span> Wait for applet to load.  
Buttons on the bottom shift the date forward and 
backward by days, months, or to the next reshuffle.
Colours are zoned according to the Ministeries.
Distance from the centre is the level of power.
Click on a name to highlight all the ministers in a department.
Click on the same name again to see the ministerial biography.
 </p>

<p><span class="ptitle">Not working?</span>  If you are able, download <a href="http://www.java.com">Sun's Java
software</a>.  On Windows, the old unsupported Microsoft versions of
Java will not do.</p>

<!--<center>
<APPLET  CODE = "radapplet.class"  WIDTH = "700" HEIGHT = "550">
    <PARAM NAME = CODE VALUE = "radapplet.class" >
    <PARAM NAME = archive VALUE = "radcls.jar" >
    <PARAM NAME="type" VALUE="application/x-java-applet;version=1.4">
    <PARAM NAME = "ministers" VALUE="http://www.mythic-beasts.com/~julian/ministers.xml">
    <PARAM NAME = "blairimg" VALUE="http://www.mythic-beasts.com/~julian/10047.jpg">
    <PARAM NAME = "startdate" VALUE="1997-05-02">
    <PARAM NAME = "framemseconds" VALUE="50">
Sun Java 1.4 or above required
</APPLET>
</center>
-->

<p align=center>

<!--"CONVERTED_APPLET"-->
<!-- HTML CONVERTER -->
<SCRIPT LANGUAGE="JavaScript"><!--
    var _info = navigator.userAgent; 
    var _ns = false; 
    var _ns6 = false;
    var _ie = (_info.indexOf("MSIE") > 0 && _info.indexOf("Win") > 0 && _info.indexOf("Windows 3.1") < 0);
//--></SCRIPT>
    <COMMENT>
        <SCRIPT LANGUAGE="JavaScript1.1"><!--
        var _ns = (navigator.appName.indexOf("Netscape") >= 0 && ((_info.indexOf("Win") > 0 && _info.indexOf("Win16") < 0 && java.lang.System.getProperty("os.version").indexOf("3.5") < 0) || (_info.indexOf("Sun") > 0) || (_info.indexOf("Linux") > 0) || (_info.indexOf("AIX") > 0) || (_info.indexOf("OS/2") > 0) || (_info.indexOf("IRIX") > 0)));
        var _ns6 = ((_ns == true) && (_info.indexOf("Mozilla/5") >= 0));
//--></SCRIPT>
    </COMMENT>

<SCRIPT LANGUAGE="JavaScript"><!--
    if (_ie == true) document.writeln('<OBJECT
    classid="clsid:8AD9C840-044E-11D1-B3E9-00805F499D93" WIDTH = "750" HEIGHT = "550"  codebase="http://java.sun.com/products/plugin/autodl/jinstall-1_4-windows-i586.cab#Version=1,4,0,0"><NOEMBED><XMP>');
    else if (_ns == true && _ns6 == false) document.writeln('<EMBED \
	    type="application/x-java-applet;version=1.4" \
            CODE = "radapplet.class" \
            ARCHIVE = "minwhirl/radcls.jar" \
            WIDTH = "750" \
            HEIGHT = "550" \
            ministers = "/data/ministers.xml" \
            blairimg = "http://www.publicwhip.org.uk/minwhirl/blair.jpg" \
            startdate = "1997-05-02" \
            framemseconds = "50" \
	    scriptable=false \
	    pluginspage="http://java.sun.com/products/plugin/index.html#download"><NOEMBED><XMP>');
//--></SCRIPT>
<APPLET  CODE = "radapplet.class" ARCHIVE = "minwhirl/radcls.jar" WIDTH = "750" HEIGHT = "550"></XMP>
    <PARAM NAME = CODE VALUE = "radapplet.class" >
    <PARAM NAME = ARCHIVE VALUE = "minwhirl/radcls.jar" >
    <PARAM NAME="type" VALUE="application/x-java-applet;version=1.4">
    <PARAM NAME="scriptable" VALUE="false">
    <PARAM NAME = "ministers" VALUE="/data/ministers.xml">
    <PARAM NAME = "blairimg" VALUE="http://www.publicwhip.org.uk/minwhirl/blair.jpg">
    <PARAM NAME = "startdate" VALUE="1997-05-02">
    <PARAM NAME = "framemseconds" VALUE="50">
SSun Java 1.4 or above required
</APPLET>
</NOEMBED>
</EMBED>
</OBJECT>

<!--"END_CONVERTED_APPLET"-->

<p>More of the same?  <a href="mpsee.php">Try our map of MP votes</a>

<?php include "footer.inc" ?>
