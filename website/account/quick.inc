<?php

if (!function_exists("user_isloggedin"))
{
    unset($LOGGED_IN);
    include "/home/francis/.pwdb.inc";

    function user_isloggedin() {
            global $user_name,$id_hash,$hidden_hash_var,$LOGGED_IN;

            $user_name=mysql_escape_string($_COOKIE["user_name"]);
            $id_hash=mysql_escape_string($_COOKIE["id_hash"]);

            //have we already run the hash checks? 
            //If so, return the pre-set var
            if (isset($LOGGED_IN)) {
#                print "isset ";
 #               if ($LOGGED_IN)
  #                  print "logged in";
                return $LOGGED_IN;
            }
            if ($user_name && $id_hash) {
                    $hash=md5($user_name.$hidden_hash_var);
                    if ($hash == $id_hash) {
                            $LOGGED_IN=true;
                            return true;
                    } else {
                            $LOGGED_IN=false;
                            return false;
                    }
            } else {
                    $LOGGED_IN=false;
                    return false;
            }
    }
}

?>
