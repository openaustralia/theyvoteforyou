<?php

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

?>

