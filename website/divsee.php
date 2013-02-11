<?php require_once "common.inc";
# $Id: divsee.php,v 1.2 2006/02/17 19:56:13 publicwhip Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

    $title = "Division map"; pw_header()
?>

<p>For your convenience, this is a tool for interactively navigating the space
of divisions clustered by how MPs voted in them.  We've taken just the votes in
every division, done some maths, and plotted a map.  The axes are made
automatically by the maths.  <a href="#details">Read more about this below</a>.
</p>

<p><span class="ptitle">Usage instructions:</span> Click and drag the mouse
pointer in the image to drag, zoom, or select from the space.  (Click on the
radio buttons at the bottom marked "Drag", "Zoom", or "Select" to determine the
mode.)  Zooming happens if you drag the mouse pointer right or left.  The panel
on the right shows the list of divisions.  Selected divisions are highlighted in
white in the image.  Warning: when you select from the image with the circle
pointer, you may get more than one division, and you will have to scroll
through the list to see them all.  </p>  

<p><span class="ptitle">Not working?</span>  If you are able, download <a href="http://www.java.com">Sun's Java
software</a>.  On Windows, the old unsupported Microsoft versions of Java will
not do.  Alternatively, get a taste with a static <a
href="votemap/divsee.png">screenshot</a>,
</p>

<?php
function applet($year)
{
?>
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
    if (_ie == true) document.writeln('<OBJECT classid="clsid:8AD9C840-044E-11D1-B3E9-00805F499D93" WIDTH = "700" HEIGHT = "400"  codebase="http://java.sun.com/products/plugin/autodl/jinstall-1_4-windows-i586.cab#Version=1,4,0,0"><NOEMBED><XMP>');
    else if (_ns == true && _ns6 == false) document.writeln('<EMBED \
	    type="application/x-java-applet;version=1.4" \
            CODE = "mpapplet.class" \
            ARCHIVE = "mpscatt.jar" \
            WIDTH = "700" \
            HEIGHT = "400" \
            posfile ="divcoords<?php echo $year?>.txt" \
	    scriptable=false \
	    pluginspage="http://java.sun.com/products/plugin/index.html#download"><NOEMBED><XMP>');
//--></SCRIPT>
<APPLET  CODE = "mpapplet.class" ARCHIVE = "mpscatt.jar" WIDTH = "700" HEIGHT = "400"></XMP>
    <PARAM NAME = CODE VALUE = "mpapplet.class" >
    <PARAM NAME = ARCHIVE VALUE = "mpscatt.jar" >
    <PARAM NAME="type" VALUE="application/x-java-applet;version=1.4">
    <PARAM NAME="scriptable" VALUE="false">
    <PARAM NAME = "posfile" VALUE="divcoords<?php echo $year?>.txt">
Sun Java 1.4 or above required
</APPLET>
</NOEMBED>
</EMBED>
</OBJECT>

<!--"END_CONVERTED_APPLET"-->
<?php
    }
    print "<h2>Division map</h2>\n";
    applet("");
?>

</p>

<h2><a name="details">What is cluster analysis?</a></h2>

<p>There's an explanation on the <a href="mpsee.php">MP voting record clustering</a> page.</p>

<?php pw_footer() ?>

