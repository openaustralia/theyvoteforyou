This is used for migration of early wrans gids on Public Whip to those
finally used on TheyWorkForYou.com

The wrans.php file uses wransmap.txt in website/legacy to do a redirect.  

The two files in this folder sphinx-wrans.txt and baked-wrans.txt are
the raw data I used to make wransmap.txt -- they give a map from gid to
House of Commons question number, on each of the two servers (sphinx for
Public Whip, baked for TheyWorkForYou).  The script "build" does the
conversion.
