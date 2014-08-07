wransdates made using query:

mysql -e "select count(*), hdate, substr(hdate, 1, 7) from hansard where major = 3 and minor = 1 group by hdate order by hdate;" >wransdates

mysql -e "select count(*), hdate, substr(hdate, 1, 7) from hansard where major = 3 and minor = 1 and speaker_id in (x) group by hdate order by hdate;" >wransdates

