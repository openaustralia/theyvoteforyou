<?php

# $Id: wordfreq.php,v 1.1 2004/01/26 10:04:58 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

/*
	Improvements to-do.  
	
	Need to list more than one word in a box for the search, eg "tax+taxation+taxes"
	
	Find a way to break down the graphs into batches of weeks and months.  
	There should be an app for a date class which can separate these out.  
	
	Use some kind of dynamic html to unroll or roll month groupings.  
	
	Breakdown of each day into debate chunks which have separate links.  
	The wordcount bar will have little gaps in it to signify these breaks, 
	so you can click on the longest of them to go straight to the right 
	point in the day.  
	
	Include the "*" word type, which counts the total number of words said 
	during that day or debate.  This would be graphed to a different scale.  
	
	We should also be able to graph how much an MP is speaking per day 
	or debate (once we have those chunks parsed out) 
	so that you can see where your MP is speaking the most and 
	be able to go straight to the places where he is making 
	the most activity so that you can see and respond to it.  
*/  

?>


<?php
    include "db.inc";

    # word to search on.  
    for ($i=1;$i<5;$i++)
    {
    	$word = db_scrub($_GET["word$i"]);
    	if ($word != "")
     		$words[$i - 1] = $word;
    	else
     		break; 
    }
    $title = "Word frequency anaylsis";
    include "header.inc";

    print "<br>";
?>

<p>Instructions: Type words you want to look for into the 
boxes (you can leave one or two boxes blank), and press the 
button.  
This will give you a visual display of the frequency they 
are spoken each day in the House of Commons.  
For example, try "death" and "taxes".  
<form name="words">
<input name="word1" type="text"/>
<input name="word2" type="text"/>
<input name="word3" type="text"/>
<input name="" type="submit"/>
</form>
</p>

           
<?php  
    print "<br>";
    
	# find the days 
    $dbd = new DB(); 
	//$dbd->query("select day_date from pw_cache_wordfreq group by day_date order by day_date"); 
	$dbd->query("select day_date, first_page_url from pw_hansard_day group by day_date order by day_date"); 
    
    # clear the wordcount array
    $ref = "ref"; 
    while ($row = $dbd->fetch_row())
    {
		$barchart[$row[0]][$ref] = $row[1]; 
	    for ($i=0;$i<count($words);$i++) 
		{    
			$barchart[$row[0]][$i] = 0; 
		}
	}
?>

<?php  
  if (count($words) > 0)
  {    
	print "<hr class=\"topline\">";
	
    # we will need a separate max for total words.      
    $maxf = 1; 
    for ($i=0;$i<count($words);$i++) 
	{    
	    # fill the word count array and find max
    	$dbw = new DB(); 
		$dbw->query("select day_date, count from pw_cache_wordfreq where word=\"$words[$i]\"");
    
    	while ($row = $dbw->fetch_row())
	    {
    	    $barchart[$row[0]][$i] = $row[1];
	        if ($maxf < $row[1])
    	    	$maxf = $row[1]; 
	    }
	}
	    
    # round up to nearest hundred
    $hundred = 100; 
    $maxfh = ((int)(($maxf + $hundred - 1) / $hundred)) * $hundred; 
    
    # find height of bar 
    $bheight = (int)(16 / count($words)); 
    $twidth = 800; 
    
	# print the key 	    
    print "<table>"; 
    for ($i=0;$i<count($words);$i++) 
	{
        $width = 100; 
		print "<tr><td>\"" . html_scrub($words[$i]) . "\"</td>"; 
		print "<td><img src=\"row$i.png\" width=\"$width\" height=\"$bheight\"/></td></tr>"; 
	}
    print "</table>"; 
		
	# print the headings of the table.      
    print "<table><tr class=\"headings\"><td>Date</td><td>Chart</td>"; 
    for ($i=0;$i<count($words);$i++) 
	{
		print "<td>" . html_scrub($words[$i]) . "</td>"; 
	}
    print "</tr>\n";
    
    $c = 0;
    $prettyrow = 0;
    
    foreach ($barchart as $date => $chart)
    {
        $c++;
        $prettyrow = pretty_row_start($prettyrow);
        
		# this should be hyperlinked  
		print "<td><a href=\"$chart[$ref]\">$date</a></td>"; 

		print "<td><table class=\"bars\">"; 		
	    for ($i=0;$i<count($words);$i++) 
		{
	        $width = (int)($chart[$i] * $twidth / $maxfh); 
			print "<tr><td><img src=\"row$i.png\" width=\"$width\" height=\"$bheight\"/></td></tr>"; 
		}
		print "</table></td>"; 		
		
	    for ($i=0;$i<count($words);$i++) 
		{
			print "<td>$chart[$i]</td>"; 
		}
		print "</tr>\n";
    }
    print "</table>\n";
  }
?>

<?php include "footer.inc" ?>
