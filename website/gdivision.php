
<html>
<body>

<?php
function getwmotionfname($date, $div_no)
{
	$nodashdate = preg_replace("/-/", "", $date);
	$motionfname = "MotionT${nodashdate}d${div_no}";
	return $motionfname;
}


function getwmotiontext($motionfname, $motion, $hasrighttoedit)
{
// the location of the wiki pages
$wikipagesdir = "/home/julian/wiki/data/text/";
// hasright to edit should be for logged on dream mps


	$wikmfname = $wikipagesdir.$motionfname;

	// if no file, then generate one
	if (!is_file($wikmfname))
	{
		$fout = fopen($wikmfname, "w");
		fputs($fout, "= MOTION =\n\n");
		fputs($fout, "<p>UNCORRECTED Procedural text extracted from the debate,".
					 "so you can try to work out what 'aye' (for the motion) and 'no' (against the motion) meant.".
					 "This is for guidance only, irrelevant text may be shown, crucial text may".
					 "be missing.</p>\n\n");
		fputs($fout, $motion);
		fputs($fout, "\n\n= COMMENTS =\n\n");
		fclose($fout);
		chmod($wikmfname, 0660);
	}

	$tail = "\n";
	if ($hasrighttoedit)
    	$tail = "<p>Edit and improve this text by going to the <a href=\"http://www.goatchurch.org.uk/cgi-bin/moin.cgi/$motionfname?action=edit\">Motion Text Wiki</a>.</p>\n";

	// Get the file between the text lines "MOTION" and "COMMENTS"
	$fin = fopen($wikmfname, "r");
	if (feof($fin))
		return $motion."<p>(Warning: Motion text wiki page is blank)</p>\n".$tail;
	$fline1 = trim(fgets($fin));
	if (strcmp($fline1, "= MOTION =") != 0)
		return $motion."<p>(Warning: First line of Motion text wiki is not \"= MOTION =\")</p>\n".$tail;

	// go till the "COMMENTS" line
	$flines = array();
	$flline = "";
	while (strcmp($flline, "= COMMENTS =") != 0)
	{
		if (feof($fin))
			return $motion."<p>(Warning: No line of Motion text wiki reads \"= COMMENTS =\")</p>\n".$tail;
		$flines[] = $flline;
		$flline = trim(fgets($fin));
	}
	return implode("", $flines).$tail;
}
?>


<?php
    $date = $_GET["date"];
    $div_no = $_GET["number"];

	// this comes from the fact that it's a dream mp person
	$hasrighttoedit = true;

	$motion = "<p>(((The default database motion text on date $date div no $div_no<br> read from the database)))</p>";

    print "<h2><a name=\"motion\">Motion</a></h2> ";

	// get over-riding text
	$motionfname = getwmotionfname($date, $div_no);
	$gmotion = getwmotiontext($motionfname, $motion, $hasrighttoedit);
    print "<div class=\"motion\">\n$gmotion</div>\n";
?>

</body>
</html>


