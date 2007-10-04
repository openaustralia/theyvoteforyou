<?php
# $Id: election2007questions.inc,v 1.2 2007/10/04 13:35:13 goatchurch Exp $

# The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

# news articles linked to in the election2007 page

$questlistmaps = array(

// ... Legislative and Regulatory Reform Bill
array("issue"=>"lrrb",
      "policydir"=>"policy-for",
      "date"=>"2006-05-15",
      "divisionno"=>"232",
      "mpvote"=>"no",
      "mpposition"=>"vote against",
      "question"=>"requiring the Government to act \"reasonably\" when altering the
                law to reduce regulatory burdens?"),

array("issue"=>"lrrb",
      "policydir"=>"policy-for",
      "date"=>"2006-05-16",
      "divisionno"=>"237",
      "mpvote"=>"no",
      "mpposition"=>"vote against",
      "question"=>"the ability of a minority of MPs to decide that a proposed change in
                the law was not uncontroversial enough to bypass the usual procedures of
                Parliament?"),

array("issue"=>"lrrb",
      "policydir"=>"policy-for",
      "date"=>"2006-05-16",
      "divisionno"=>"235",
      "mpvote"=>"no",
      "mpposition"=>"vote against",
      "question"=>"requiring the Government to produce an annual report
                on the benefits of the changes it had made to to the law outside the usual procedures of Parliament"),

array("issue"=>"lrrb",
      "policydir"=>"policy-for",
      "date"=>"2006-05-16",
      "divisionno"=>"240",
      "mpvote"=>"no",
      "mpposition"=>"vote against",
      "question"=>"requiring the Government to take notice of the of the view of a
                select committee when it decided that a proposed change to the law
                was not proportional, balanced and consistent with policy objectives"),

array("issue"=>"lrrb",
      "policydir"=>"policy-for",
      "date"=>"2006-05-16",
      "divisionno"=>"238",
      "mpvote"=>"no",
      "mpposition"=>"vote against",
      "question"=>"Government Ministers being able to confer law-making powers to
                people who were not accountable to Parliament"),
);                         

$questlistraw = array();

foreach ($questlistmaps as $questlistmap)
    $questlistraw[] = array($questlistmap["issue"], $questlistmap["policydir"],
                            $questlistmap["date"].'#'.$questlistmap["divisionno"],
                            $questlistmap["mpvote"], $questlistmap["mpposition"],
                            "Why did XXXX VVVV ".$questlistmap["question"]."?");


/// ... Iraq
$questlistraw[] = array("iraq", "policy-for", "2007-06-11#135", "no", "vote against", "Why did XXXX VVVV
                the principle of an independent inquiry
                to review the way in which the responsibilities of Government
                were discharged in relation to Iraq?");

$questlistraw[] = array("iraq", "policy-for", "2007-10-31#330", "no", "vote against", "Why did XXXX VVVV
                there being a select committee
                to review the way in which the responsibilities of Government
                were discharged in relation to Iraq?");

$questlistraw[] = array("iraq", "policy-for", "2007-06-11#136", "aye", "vote for", "Why did XXXX VVVV
                the recognition that for a further inquiry into Iraq would
                would divert attention
                whilst the whole effort of the effort of the Government
                and the armed forces was directed towards improving the condition of Iraq?");

$questlistraw[] = array("iraq", "policy-for", "2007-10-31#331", "aye", "vote for", "Why did XXXX VVVV
                the recognition that for a further inquiry into Iraq would
                would divert attention
                whilst the whole effort of the effort of the Government
                and the armed forces was directed towards improving the condition of Iraq?");


// ... Trident
$questlistraw[] = array("trident", "policy-for", "2007-03-14#77", "aye", "vote for", "Why did XXXX VVVV
                extending the life of Trident while remaining unconvinced of the need for an early
                decision to find a replacement?");

$questlistraw[] = array("trident", "policy-for", "2007-03-14#78", "no", "vote against", "Why did XXXX VVVV
                authorizing the Government to replace the Trident nuclear weapons system?");

// ... Smoking ban
$questlistraw[] = array("smoking", "policy-for", "2006-02-14#166", "no", "vote against", "Why did XXXX VVVV
                the third reading of the Act banning smoking in all indoor public places?");

$questlistraw[] = array("smoking", "policy-for", "2006-02-14#164", "no", "vote for", "Why did XXXX VVVV
                allowing private clubs to apply to the Local Authority
                for an exemption to the ban on smoking in all indoor public places?");

// ... FOI Amendment
$questlistraw[] = array("foia", "policy-for", "2007-05-18#121", "no", "vote against", "Why did XXXX VVVV
                limiting the proposed exemption from the Freedom of Information Act
                to matters relating to the personal affairs of a constituent?");

$questlistraw[] = array("foia", "policy-for", "2007-05-18#123", "aye", "vote for", "Why did XXXX VVVV
                the Law which would have exempted Parliament and all MPs from
                the Freedom of Information Act?");

$questlistraw[] = array("foia", "policy-for", "2007-05-18#120", "no", "vote for", "Why did XXXX VVVV
                preventing the Freedom of Information Act from applying to
                correspondence between an MP and any Government department?");

$questlistraw[] = array("foia", "policy-for", "2007-05-18#122", "aye", "vote for", "Why did XXXX VVVV
                closing the debate on the Law which would have exempted MPs from
                the Freedom of Information Act knowing that the next vote on it would pass?");

);


