<?php

include "xquery.inc";
include "protodecode.inc";

function wrans_search($prettysearch)
{
    $words = split(" ", $prettysearch);
    $ids = null;
    foreach ($words as $word)
    {
        $wordids = array_unique(DecodeWord($word));
        if ($ids != null)
            $ids = array_intersect($wordids, $ids);
        else
            $ids = $wordids;
    }
    return $ids;
}

function wrans_recent_popular($count)
{
    include "config.inc";
    
    $rh = fopen($xmltoppath . '/wrans-recent-popular.txt', 'r');
    $resuilt = '';
    $ids = array();
    for ($i = 0; $i < $count; ++$i)
    {
        $id = trim(fgets($rh));
        array_push($ids, $id);
    }
    fclose($rh);
    return $ids;
}

?>
