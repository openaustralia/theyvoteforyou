<?php
# $Id: election2007articles.inc,v 1.1 2007/10/04 12:07:13 publicwhip Exp $

# The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

# news articles linked to in the election2007 page

$newsarticles = array(

"iraq2006telegraph" => 
array("publisher"=>"The Telegraph",
      "title"=>"Blair rules out Iraq inquiry before vote",
      "date"=>"2006-11-01",
      "url"=>"http://www.telegraph.co.uk/news/main.jhtml?xml=/news/2006/10/31/ninquiry31.xml"), 


);


function StrArticle($newsarticle)
{
    # we have the option to mark up date as pretty date
    return '<a href="'.$newsarticle["url"].'" class="newslink">'.$newsarticle["title"].'</a> <b>'.$newsarticle["publisher"].'</b> ('.$newsarticle["date"].')';
}


