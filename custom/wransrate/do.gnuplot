set xdata time;
set timefmt "%Y-%m-%d";
set xrange ["2001-06-21":"2005-10-11"];
set format x "%b %y"
set xlabel "Date"
set ylabel "Written Answers / day"
set terminal png
plot "wransdates" using 2:1 title 'Written Answers rate in House of Commons';

#f(x) = a*x + b
#fit f(x) "wransdates" using 2:1 

