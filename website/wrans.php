<?php include "cache-begin.inc"; ?>
<?php 
    # $Id: wrans.php,v 1.1 2003/11/30 16:55:27 frabcus Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    include "db.inc";
    include "parliaments.inc";
    $db = new DB(); 

    $path = "/home/francis/pwdata/pwscrapedxml/wrans/";

#    $date = db_scrub($_GET["date"]);

#    $show_all = false;
#    if ($_GET["showall"] == "yes")
#        $show_all = true;

    $title = html_scrub("Written Answers $date");
    include "header.inc";
    
    $xmlfile = $path . "answers2003-11-17.xml";
    $xsltfile = "wrans.xslt";

    $xsltproc = xslt_create();
    xslt_set_encoding($xsltproc, 'ISO-8859-1');
    $html = xslt_process($xsltproc, $xmlfile, $xsltfile, NULL);

    if (empty($html)) {
       die('XSLT processing error: '. xslt_error($xsltproc));
    }
    xslt_free($xsltproc);
    print $html;
?>

<?php include "footer.inc" ?>
<?php include "cache-end.inc"; ?>
