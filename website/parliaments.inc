<?php

# $Id: parliaments.inc,v 1.22 2010/05/10 06:47:29 publicwhip Exp $
# This data is duplicated in loader/PublicWhip/Parliaments.pm

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

# The id is unique forever - so if there were two parliaments in one
# year, the first would be id'd after the year, and we'd have to
# give the scond an id with the month in as well.  The name can change
# (as it is not in URLs), so can be any clarifying pretty description.
$parliaments = array(
    '2010' => array('from' => '2010-05-06', 'to' => '9999-12-31', 'name' => '2010-present,&nbsp;Westminster'),
    '2005' => array('from' => '2005-05-05', 'to' => '2010-04-12', 'name' => '2005-2010,&nbsp;Westminster'),
    '2001' => array('from' => '2001-06-07', 'to' => '2005-04-11', 'name' => '2001-2005,&nbsp;Westminster'),
    '1997' => array('from' => '1997-05-01', 'to' => '2001-05-14', 'name' => '1997-2001,&nbsp;Westminster'),
    'S1' => array('from' => '1999-05-12', 'to' => '2003-03-31', 'name' => 'Scottish&nbsp;Parliament&nbsp;Session&nbsp;1&nbsp;(1999-2003)'),
    'S2' => array('from' => '2003-05-07', 'to' => '2007-04-02', 'name' => 'Scottish&nbsp;Parliament&nbsp;Session&nbsp;2&nbsp;(2003-2007)'),
    'S3' => array('from' => '2007-05-09', 'to' => '2011-03-23', 'name' => 'Scottish&nbsp;Parliament&nbsp;Session&nbsp;3&nbsp;(2007-present)'),
    'S4' => array('from' => '2011-03-24', 'to' => '9999-12-31', 'name' => 'Scottish&nbsp;Parliament&nbsp;Session&nbsp;3&nbsp;(2011-present)')
);

# These are parliamentary sessions (i.e. years) - nothing to do with
# PHP or web sessions or anything like that.
$parlsessions = array(
	'2002' => array('from' => '2002-11-13', 'to' => '2003-11-20', 'name' => '2002/2003'),
);
function parliament_count()
{
    global $parliaments;
    return count($parliaments);
}

function date_to_parliament($date)
{
    global $parliaments;

    foreach ($parliaments as $id => $parliament)
    {
        if ($parliament['from'] <= $date && $date <= $parliament['to'])
            return $id;
    }
    return "unknown";
}

function parliament_name($id)
{
    global $parliaments;
    return $parliaments[$id]['name'];
}

function parliament_date_from($id)
{
    global $parliaments;
    return $parliaments[$id]['from'];
}

function parliament_date_to($id)
{
    global $parliaments;
    return $parliaments[$id]['to'];
}

# possibly dead function
function year_range($from, $to)
{
    $y1 = substr($from, 0, 4);
    $y2 = substr($to, 0, 4);
    $ret = $y1;
#    if ($y1 <> $y2)
    {
        $ret .= "-";
        if ($y2 <> "9999")
            $ret .= $y2;
        else
            $ret .= date("Y");
    }
    return $ret;
}

function parlsession_name($id)
{
    global $parlsessions;
    return $parlsessions[$id]['name'];
}

function parlsession_date_from($id)
{
    global $parlsessions;
    return $parlsessions[$id]['from'];
}

function parlsession_date_to($id)
{
    global $parlsessions;
    return $parlsessions[$id]['to'];
}

function whipless_party($party) {
    return $party == "XB" || 
            $party == "Other" || 
            substr($party, 0, 3) == "Ind" || 
            $party == "None" ||
            $party == "CWM" || 
            $party == "DCWM";
}