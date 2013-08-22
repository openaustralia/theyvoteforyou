<?php
# $Id: election2007questions.inc,v 1.8 2007/10/04 14:46:55 publicwhip Exp $

# The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

# news articles linked to in the election2007 page

$questlistmapsraw = array(

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


array("issue"=>"iraq",
      "policydir"=>"policy-for",
      "date"=>"2007-06-11",
      "divisionno"=>"135",
      "mpvote"=>"no",
      "mpposition"=>"vote against",
      "question"=>"the principle of an independent inquiry
                to review the way in which the responsibilities of Government
                were discharged in relation to Iraq"),

array("issue"=>"iraq",
      "policydir"=>"policy-for",
      "date"=>"2006-10-31",
      "divisionno"=>"330",
      "mpvote"=>"no",
      "mpposition"=>"vote against",
      "question"=>"there being a select committee
                to review the way in which the responsibilities of Government
                were discharged in relation to Iraq?"),

array("issue"=>"iraq",
      "policydir"=>"policy-for",
      "date"=>"2007-06-11",
      "divisionno"=>"136",
      "mpvote"=>"aye",
      "mpposition"=>"vote for",
      "question"=>"recogizing that for a further inquiry into Iraq would
                would divert attention
                whilst the whole effort of the effort of the Government
                and the armed forces was directed towards improving the condition of Iraq"),

array("issue"=>"iraq",
      "policydir"=>"policy-for",
      "date"=>"2006-10-31",
      "divisionno"=>"331",
      "mpvote"=>"aye",
      "mpposition"=>"vote for",
      "question"=>"recognizing that for a further inquiry into Iraq would
                would divert attention
                whilst the whole effort of the effort of the Government
                and the armed forces was directed towards improving the condition of Iraq"),



// ... Trident
array("issue"=>"trident",
      "policydir"=>"policy-for",
      "date"=>"2007-03-14",
      "divisionno"=>"77",
      "mpvote"=>"aye",
      "mpposition"=>"vote for",
      "question"=>"extending the life of Trident while remaining unconvinced of the need for an early
                decision to find a replacement"),

array("issue"=>"trident",
      "policydir"=>"policy-for",
      "date"=>"2007-03-14",
      "divisionno"=>"78",
      "mpvote"=>"no",
      "mpposition"=>"vote against",
      "question"=>"authorizing the Government to replace the Trident nuclear weapons system"),

// ... Smoking ban
array("issue"=>"smoking",
      "policydir"=>"policy-for",
      "date"=>"2006-02-14",
      "divisionno"=>"166",
      "mpvote"=>"no",
      "mpposition"=>"vote against",
      "question"=>"the Third Reading of the Act banning smoking in all indoor public places"),

array("issue"=>"smoking",
      "policydir"=>"policy-for",
      "date"=>"2006-02-14",
      "divisionno"=>"164",
      "mpvote"=>"no",
      "mpposition"=>"vote for",
      "question"=>"allowing private clubs to apply to the Local Authority
                for an exemption to the ban on smoking in all indoor public places"),


// ... FOI Amendment
array("issue"=>"foia",
      "policydir"=>"policy-for",
      "date"=>"2007-05-18",
      "divisionno"=>"121",
      "mpvote"=>"no",
      "mpposition"=>"vote against",
      "question"=>"limiting the proposed exemption from the Freedom of Information Act
                to matters relating to the personal affairs of a constituent"),

array("issue"=>"foia",
      "policydir"=>"policy-for",
      "date"=>"2007-05-18",
      "divisionno"=>"123",
      "mpvote"=>"aye",
      "mpposition"=>"vote for",
      "question"=>"the Law to exempt Parliament and all MPs from
                the Freedom of Information Act"),

array("issue"=>"foia",
      "policydir"=>"policy-for",
      "date"=>"2007-05-18",
      "divisionno"=>"120",
      "mpvote"=>"no",
      "mpposition"=>"vote for",
      "question"=>"preventing the Freedom of Information Act from applying to
                correspondence between an MP and any Government department"),

array("issue"=>"foia",
      "policydir"=>"policy-for",
      "date"=>"2007-05-18",
      "divisionno"=>"122",
      "mpvote"=>"aye",
      "mpposition"=>"vote for",
      "question"=>"closing the debate on the Law which would have exempted MPs from
                the Freedom of Information Act knowing that the next vote on it would pass"),

);



$questlistmaps = array();

function swapvals($questlistmap, $ss)
{
    return array("issue"=>$questlistmap["issue"],
                 "policydir"=>$ss[$questlistmap["policydir"]],
                 "date"=>$questlistmap["date"],
                 "divisionno"=>$questlistmap["divisionno"],
                 "mpvote"=>$ss[$questlistmap["mpvote"]],
                 "mpposition"=>$ss[$questlistmap["mpposition"]],
                 "question"=>$questlistmap["question"]);
}

$swapXvoteP = array("policy-for"=>"policy-against", "no"=>"aye", "aye"=>"no", "vote against"=>"vote for", "vote for"=>"vote against");
$swapXabst = array("policy-for"=>"policy-for", "no"=>"absent", "aye"=>"absent", "vote against"=>"not turn up to vote for", "vote for"=>"not vote against");
$swapXabstP = array("policy-for"=>"policy-against", "no"=>"absent", "aye"=>"absent", "vote against"=>"not turn up to vote against", "vote for"=>"not turn up to vote for");

foreach ($questlistmapsraw as $questlistmap)
{
    $questlistmaps[] = $questlistmap;
    $questlistmaps[] = swapvals($questlistmap, $swapXvoteP);
}
foreach ($questlistmapsraw as $questlistmap)
{
    $questlistmaps[] = swapvals($questlistmap, $swapXabst);
    $questlistmaps[] = swapvals($questlistmap, $swapXabstP);
};

$questlist = array();
foreach ($questlistmaps as $questlistmap)
    $questlist[] = array($questlistmap["issue"], $questlistmap["policydir"],
                            $questlistmap["date"].'#'.$questlistmap["divisionno"],
                            $questlistmap["mpvote"], $questlistmap["mpposition"],
                            "Why did XXXX VVVV ".$questlistmap["question"]."?");


#print "<pre>";print_r($questlist); exit;


