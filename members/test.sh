#!/bin/bash

while read X
do
    X=${X/&/&amp;}
    grep "\"$X\"" constituencies.xml >/dev/null || echo "not $X"
done

