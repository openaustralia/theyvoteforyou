<?php

# $Id: parliaments.inc,v 1.3 2003/10/03 21:46:10 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

# The id is unique forever - so if there were two parliaments in one
# year, the first would be id'd after the year, and we'd have to
# give the scond an id with the month in as well.  The name can change
# (as it is not in URLs), so can be any clarifying pretty description.
$parliaments = array(
    '2001' => array(from => '2001-06-07', to => '9999-12-31', name => '2001'),
    '1997' => array(from => '1997-05-01', to => '2001-05-14', name => '1997'),
);

function this_parliament()
{
    return 2001;
}

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
    return "Unknown";
}

function parliament_name($id)
{
    if ($id == "")
        $id = this_parliament();
    global $parliaments;
    return $parliaments[$id]['name'];
}

function parliament_date_from($id)
{
    if ($id == "")
        $id = this_parliament();
    global $parliaments;
    return $parliaments[$id]['from'];
}

function parliament_date_to($id)
{
    if ($id == "")
        $id = this_parliament();
    global $parliaments;
    return $parliaments[$id]['to'];
}


function year_range($from, $to)
{
    $y1 = substr($from, 0, 4);
    $y2 = substr($to, 0, 4);
    $ret = $y1;
    if ($y1 <> $y2)
    {
        $ret .= "-";
        if ($y2 <> "9999")
            $ret .= $y2;
    }
    return $ret;
}

?>


