set xdata time;
set timefmt "%Y-%m-%d";
set xrange ["2001-06-21":"2006-07-20"];
set format x "%b %y"
set xlabel "Date"
set ylabel "Written Answers / month"
#set y2label "Nigel Evans"
#set y2tics
set terminal png size 1000,500
plot "wransdates" using 2:($1) title 'Written Answers rate in House of Commons' 
#with lines
#, "wransdates-evans" using 2:1 title 'Nigel Evans' axes x1y1 with lines

#f(x) = a*x + b
#fit f(x) "wransdates" using 2:1 

