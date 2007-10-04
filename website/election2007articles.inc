<?php
# $Id: election2007articles.inc,v 1.2 2007/10/04 12:41:37 goatchurch Exp $

# The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

# news articles linked to in the election2007 page

$newsarticles = array(

"iraq2006telegraph" =>
  array("publisher"=>"The Telegraph",
        "title"=>"Blair rules out Iraq inquiry before vote",
        "date"=>"1 November 2006",
        "url"=>"http://www.telegraph.co.uk/news/main.jhtml?xml=/news/2006/10/31/ninquiry31.xml"),

"iraq2006bbc" =>
  array("publisher"=>"BBC News",
        "title"=>"Iraq inquiry call rejected",
        "date"=>"1 November 2006",
        "url"=>"http://news.bbc.co.uk/2/hi/uk_news/scotland/6096098.stm"),

"iraq2006sun" =>
  array("publisher"=>"The Sun",
        "title"=>"Blair sees off Iraq inquiry call",
        "date"=>"31 October 2006",
        "url"=>"http://www.thesun.co.uk/article/0,,2-2006500444,00.html"),

"iraq2007bbc" =>
  array("publisher"=>"BBC News",
        "title"=>"Tories urge Iraq inquiry support",
        "date"=>"11 June 2007",
        "url"=>"http://news.bbc.co.uk/2/hi/programmes/bbc_parliament/6741335.stm"),

"iraq2007ap" =>
  array("publisher"=>"Associated Press",
        "title"=>"Parliament rejects Iraq war decision probe",
        "date"=>"11 June 2007",
        "url"=>"http://www.usatoday.com/news/world/2007-06-11-britain-iraq_N.htm"),

"iraq2007sun" =>
  array("publisher"=>"The Sun",
        "title"=>"Gord: No early exit from Iraq",
        "date"=>"12 June 2007",
        "url"=>"http://www.thesun.co.uk/article/0,,2-2007270137,00.html"),

);


function StrArticle($newsarticle)
{
    # we have the option to mark up date as pretty date
    return '<a href="'.$newsarticle["url"].'" class="newslink">'.$newsarticle["title"].'</a> <b>'.$newsarticle["publisher"].'</b> ('.$newsarticle["date"].')';
}


