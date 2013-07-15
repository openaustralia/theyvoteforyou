<?php

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.
?>

</div><!-- end main content -->
</div><!-- end whitebox-->
<div id="bluebox">
    <div class="widewidth">
        <div class="col1-2"><h3>About the Project</h3>

            <p>
                The Public Whip is brought to you by the not-for-profit <a href="http://www.openaustraliafoundation.org.au/">OpenAustralia Foundation</a>. It is an adaption
                of the <a href="http://www.publicwhip.org.uk/">UK site</a> original created in 2003 by Francis Irving and Julian Todd.
            </p>

            <p>
                If you'd like to talk to us about the project, please
                <a href="mailto:contact@openaustraliafoundation.org.au">email us</a>.
            </p>
        </div>
        <div class="col3"><h3>The Whip on the Web</h3>
            <ul class="social">
                <li class="wp"><a href="https://www.openaustraliafoundation.org.au/blog/">OpenAustralia Foundation Blog</a></li>
                <li class="tw"><a href="http://twitter.com/openaustralia">Twitter</a></li>
                <!-- <li class="fb"><a href="http://www.facebook.com/pages/Public-Whip/199268083464697">Facebook</a></li> -->
            </ul>
        </div>
        <div class="clear"></div>
    </div>
    <?php
    if (true===function_exists('advertisement')) {
    advertisement('footer');
    }
    ?>
</div><!--end bluebox-->
<div id="footer">
    <div class="widewidth">
        <!-- the footer section -->
        <!-- old footer links <a title="Frequently asked questions" href="<?php echo $toppath?>faq.php#whatis">About us</a>
<a title="Send comments, problems or suggestions" href="/email.php">Contact us</a>
<a title="Fodder for your spreadsheet" href="/project/data.php">Data feeds</a>
<a title="Public Whip is open source software" href="/project/code.php">Source code</a>
<a title="Divisions in your news reader" href="/faq.php#rss">RSS</a>
<a title="Details on the free license for this data" href="/faq.php#legal">Legal information</a>-->
        <div>
            Other projects by us that you might find interesting:
        </div>
        <div>
            <a href="http://www.openaustralia.org">OpenAustralia</a>, <a href="http://www.electionleaflets.org.au">Election Leaflets</a>, <a href="http://www.righttoknow.org.au">Right To Know</a> and <a href="http://www.planningalerts.org.au">Planning Alerts</a>.
        </div>
        <div class="legal">
            The Public Whip is a not-for-profit, open source, project. Get the
            <a href="https://github.com/openaustralia/publicwhip/">source code</a>.
        </div>

    </div>
    <div class="clear"></div>
</div><!-- end footer-->
<?php if (extension_loaded('newrelic')) {
    echo newrelic_get_browser_timing_footer();
} ?>
</body>
</html>
