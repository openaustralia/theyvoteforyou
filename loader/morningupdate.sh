#!/usr/bin/env bash
# This file should be run daily after the parlparse XML for the day is ready.
./load.pl divsxml check

./calc_caches.php
