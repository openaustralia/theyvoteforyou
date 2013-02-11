<?php
# $Id: constituencies.inc,v 1.17 2010/05/05 22:32:34 publicwhip Exp $

# The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

function normalise_constituency_name($name, $house = null, $parl = null)
{
    global $pwpdo;
    if ($house && ($house == 'scotland')) {
        // For Scotland, the " and " version is canonical:
        $name = str_replace("&amp;", "and", $name);
        $name = str_replace("&", "and", $name);
        $name = str_replace("  ", " ", $name);
        $name = trim($name);
    } else {
        // Otherwise use &amp; everywhere (as in the DB for everywhere except Scotland)
        $name = str_replace("&amp;", "&", $name);
        $name = str_replace(" and ", " & ", $name);
        $name = str_replace("&", "&amp;", $name);
        $name = str_replace("&amp;#39;", "&#39;", $name);
        $name = str_replace("  ", " ", $name);
        $name = trim($name);
    }
    if (substr($name, 0, 5) == 'ynys ') {
        $name = 'ynys m&ocirc;n';
    }

    $placeholders = array();
    $q3ph=array();
    $qsel = "SELECT name, cons_id FROM pw_constituency";
    $qwhere = " WHERE main_name";
    if (strlen($parl) > 0) {
        $qwhere .= ' AND from_date<:date AND :date<to_date ';
        $placeholders[':date'] = $parl;
    }
    $qwhere2 = " AND name LIKE :name";
    if ($house) {
        $qwhere3 = " AND house = :house";
        $q3ph[':house'] = $house;
    }
    $qorder = " ORDER BY to_date DESC LIMIT 1";
    $sth1 = $pwpdo->get_single_row($qsel . $qwhere . $qwhere2 . $qwhere3 . $qorder, array_merge($placeholders,$q3ph,array(':name'=>$name)));
    if ($sth1) {
        return $sth1["name"];
    }

    $and_name = str_replace(" &amp; ", " and ", $name);
    $qwhere2alt = " AND name LIKE :andname";
    $sth1 = $pwpdo->get_single_row($qsel . $qwhere . $qwhere2alt . $qwhere3 . $qorder, array_merge($placeholders,$q3ph,array(':andname'=>$and_name)));
    if ($sth1) {
        return $sth1["name"];
    }

    $qwhere2 = " AND name LIKE :likename";
    $query=$qsel . $qwhere . $qwhere2 . $qorder;
    $sth1 = $pwpdo->get_single_row($query, array_merge($placeholders,array(':likename'=>'%'.$name.'%')));
    if ($sth1) {
        return $sth1["name"];
    }
    return false;

    #$query = "SELECT name FROM pw_constituency  main_name and cons_id = '".$sth1['cons_id']."'";
    #$sth2 = $db->query_onez_row_assoc($query);
    #if ($sth2)
    #    return $sth2["name"];
}
