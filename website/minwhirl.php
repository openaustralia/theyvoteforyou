<?php $title = "Ministerial whirl"; include "header.inc" 
# $Id: minwhirl.php,v 1.4 2004/12/01 17:09:54 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.
?>

<p>See how Tony Blair's government has changed from day to day, month to
month, reshuffled to reshuffle by clicking on the buttons at the bottom
of the Java applet.  

<p>The colours are zoned by government department, and the distance from
the centre signifies seniority, with the cabinet occupying the inner
layer.  

<b>Click on a name</b> once to find the department that person is in.  

<b>Click in the same name a second time</b> to review that person's career in
government.  

<p><span class="ptitle">Not working?</span>  Wait for the applet below
to load.  If you are able, download <a href="http://www.java.com">Sun's
Java software</a>.  On Windows, the old unsupported Microsoft versions
of Java will not do.</p>

<p><a href="#details">Read more about this below</a>.


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
            ARCHIVE = "radcls.jar" \
            WIDTH = "750" \
            HEIGHT = "550" \
            ministers = "/data/ministers.xml" \
            blairimg = "minwhirl/blair.jpg" \
            startdate = "1997-05-02" \
            framemseconds = "50" \
	    scriptable=false \
	    pluginspage="http://java.sun.com/products/plugin/index.html#download"><NOEMBED><XMP>');
//--></SCRIPT>
<APPLET  CODE = "radapplet.class" ARCHIVE = "radcls.jar" WIDTH = "750" HEIGHT = "550"></XMP>
    <PARAM NAME = CODE VALUE = "radapplet.class" >
    <PARAM NAME = ARCHIVE VALUE = "radcls.jar" >
    <PARAM NAME="type" VALUE="application/x-java-applet;version=1.4">
    <PARAM NAME="scriptable" VALUE="false">
    <PARAM NAME = "ministers" VALUE="/data/ministers.xml">
    <PARAM NAME = "blairimg" VALUE="minwhirl/blair.jpg">
    <PARAM NAME = "startdate" VALUE="1997-05-02">
    <PARAM NAME = "framemseconds" VALUE="50">
SSun Java 1.4 or above required
</APPLET>
</NOEMBED>
</EMBED>
</OBJECT>

<!--"END_CONVERTED_APPLET"-->

<h2><a name="details">Background</a></h2>

<p>This applet is a visualization of the XML file <a
href="/data/ministers.xml">ministers.xml</a>, which the Publicwhip
central computer updates every twelve hours by scanning the
Parliamentary webpage
<a href="http://www.parliament.uk/directories/hciolists/hmg.cfm">Her
Majesty's Government</a> for changes.  We have kept all versions of
<a href="http://cvs.sourceforge.net/viewcvs.py/publicwhip/publicwhip/rawdata/chggpages/govposts/">
this page</a> back to June 2004, which is about when we first thought of
this idea.  Earlier information was kindly sent to us by the House of
Commons library in several emails.  The source code for this little
program is in the
<a
href="http://cvs.sourceforge.net/viewcvs.py/publicwhip/publicwhip/">SourceForge
CVS</a> under custom/radialtree, and is protected by the General Public
License.  

<p>If you have any easy to implement suggestions for improvements while the
code is still fresh in our minds, please email the team.  We've already
thought about using pictures instead of names, but they don't fit on the
page and are much more unrecognizable than names.  


<p>More of the same?  <a href="mpsee.php">Try our map of MP
votes</a></p>

<?php include "footer.inc" ?>
