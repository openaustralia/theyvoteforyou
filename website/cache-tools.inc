<?php
# $Id: cache-tools.inc,v 1.1 2004/06/15 10:26:56 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.


function print_account_navbar() {
    ?><a title="Login or change settings" href="<?=$toppath?>account/settings.php"><?php
    if (user_isloggedin()) {
        global $user_name;
        print $user_name . "'s account";
    } else {
        print "Login";
    }
    ?>
    </a>
    <?php
}

function cache_delete($file_stub, $cache_params) {
    $cache_dir = "/home/francis/pwcache/" . substr(str_replace("/", "-", $_SERVER["SCRIPT_NAME"]),1);
    $cache_dir = str_replace("account-", "", $cache_dir);
    $cache_dir = str_replace(strrchr($cache_dir, "-"), "-" . $file_stub, $cache_dir);

    $cache_file = $cache_dir . "/" . $cache_params . ".html";


    foreach (glob($cache_file) as $filename) {
        #print "delete $filename\n<p>";
        unlink($filename);
    }

    #if (file_exists($cache_file))
#        unlink($cache_file);
}

?>
