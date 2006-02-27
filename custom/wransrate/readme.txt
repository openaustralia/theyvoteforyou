wransdates made using query:

mysql -e "select count(*), hdate from hansard where major = 3 and minor = 1 group by hdate order by hdate;" >wrandates

