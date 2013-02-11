<?php require_once "common.inc";
# $Id: mpsee.php,v 1.20 2010/05/11 06:43:24 publicwhip Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

    $title = "MP vote map"; pw_header()
?>

<p>For your convenience, this is a tool for 
interactively navigating the space of MPs clustered by 
their voting records.  We've taken just the votes of every MP,
done some maths, and plotted a map.  The axes are made automatically by
the maths.  <a href="#details">Read more about this below</a>.
</p>

<p><span class="ptitle">Usage instructions:</span> Click and drag the
mouse pointer in the image to drag, zoom, or select from the space.  
(Click on the radio buttons at the bottom 
marked "Drag", "Zoom", or "Select" to determine the mode.)  
Zooming happens if you drag the mouse pointer right or left. 
The panel on the right shows the list of MPs.  
Selected names are highlighted in white in the image.  Warning: 
when you select from the image with the circle pointer, 
you may get more than one MP, and you will have to scroll 
through the list to see them all.  </p>  

<p><span class="ptitle">Not working?</span>  If you are able, download <a href="http://www.java.com">Sun's Java
software</a>.  On Windows, the old unsupported Microsoft versions of Java will not do.
Alternatively, get a taste with a static 
<a href="votemap/mpsee-2010.png">2010 screenshot</a>,
<a href="votemap/mpsee-2005.png">2005 screenshot</a>,
<a href="votemap/mpsee-2001.png">2001 screenshot</a> or
<a href="votemap/mpsee-1997.png">1997 screenshot</a> of the clustered MPs.
</p>

<?php
function applet($year)
{
?>
<p align=center>

<!--"CONVERTED_APPLET"-->
<!-- HTML CONVERTER -->
<SCRIPT LANGUAGE="JavaScript"><!--
    var _info = navigator.userAgent; 
    var _ns = false; 
    var _ns6 = false;
    var _ie = (_info.indexOf("MSIE") > 0 && _info.indexOf("Win") > 0 && _info.indexOf("Windows 3.1") < 0);
//--></SCRIPT>
    <COMMENT>
        <SCRIPT LANGUAGE="JavaScript1.1"><!--
        var _ns = (navigator.appName.indexOf("Netscape") >= 0 && ((_info.indexOf("Win") > 0 && _info.indexOf("Win16") < 0 && java.lang.System.getProperty("os.version").indexOf("3.5") < 0) || (_info.indexOf("Sun") > 0) || (_info.indexOf("Linux") > 0) || (_info.indexOf("AIX") > 0) || (_info.indexOf("OS/2") > 0) || (_info.indexOf("IRIX") > 0)));
        var _ns6 = ((_ns == true) && (_info.indexOf("Mozilla/5") >= 0));
//--></SCRIPT>
    </COMMENT>

<SCRIPT LANGUAGE="JavaScript"><!--
    if (_ie == true) document.writeln('<OBJECT classid="clsid:8AD9C840-044E-11D1-B3E9-00805F499D93" WIDTH = "700" HEIGHT = "400"  codebase="http://java.sun.com/products/plugin/autodl/jinstall-1_4-windows-i586.cab#Version=1,4,0,0"><NOEMBED><XMP>');
    else if (_ns == true && _ns6 == false) document.writeln('<EMBED \
	    type="application/x-java-applet;version=1.4" \
            CODE = "mpapplet.class" \
            ARCHIVE = "mpscatt.jar" \
            WIDTH = "700" \
            HEIGHT = "400" \
            posfile ="mpcoords-<?php echo $year?>.txt" \
	    scriptable=false \
	    pluginspage="http://java.sun.com/products/plugin/index.html#download"><NOEMBED><XMP>');
//--></SCRIPT>
<APPLET  CODE = "mpapplet.class" ARCHIVE = "mpscatt.jar" WIDTH = "700" HEIGHT = "400"></XMP>
    <PARAM NAME = CODE VALUE = "mpapplet.class" >
    <PARAM NAME = ARCHIVE VALUE = "mpscatt.jar" >
    <PARAM NAME="type" VALUE="application/x-java-applet;version=1.4">
    <PARAM NAME="scriptable" VALUE="false">
    <PARAM NAME = "posfile" VALUE="mpcoords-<?php echo $year?>.txt">
Sun Java 1.4 or above required
</APPLET>
</NOEMBED>
</EMBED>
</OBJECT>

<!--"END_CONVERTED_APPLET"-->
<?php
    }
    print "<h2>MP vote map 2010 parliament</h2>\n";
    applet("2010");
    print "<h2>MP vote map 2005 parliament</h2>\n";
    applet("2005");
    print "<h2>MP vote map 2001 parliament</h2>\n";
    applet("2001");
    print "<h2>MP vote map 1997 parliament</h2>\n";
    applet("1997");
?>

</p>

<h2><a name="details">What is cluster analysis?</a></h2>

<p>Cluster analysis is a technique used by scientists who have measured 
comparable features of a set of similar objects, and need to group them 
into categories.  The objects can be anything from homonid skulls, to 
beetles, to fossilized grass seeds.  The features can be forebrow size, 
leg length, or spikiness.  Usually, there are very many features which 
are all compared at once.  They are multiplied and reduced down to one 
single <em>dissimilarity measure</em>.  We invent a formula that 
decides, for example, that this skull is 0.97 skull units different to 
that skull, according to our measure.

<p>We can use computational techniques to simulate a spring network between 
all the different skulls in the  collection.  If the two skulls are 
placed too close together, according to the dissimilarity measure, they 
are pushed apart; if they start are too far apart, a force pulls them 
together.  The computer calculates the positions of the skulls in space 
to minimize the strain in the spring network.

<p>If all has gone well, and we have chosen an appropriate dissimilarity 
function, the skulls in the collection will group into clusters which 
probably correspond to one species.  The clusters will be in bigger 
clusters, which may or may not correspond to a genus, and so on.

<p>Since the dissimilarity measure is arbitrarily chosen, and 
experimentally altered to make better results, it takes further proof to 
be sure that the clusters are significant and not a mistake due to the 
way you are measuring at it.

<h2>How is this cluster analysis done?</h2>

<p>We've chosen a dissimilarity measure which depends on the number of 
votes the same way, and the number of votes against one another, between 
two MPs when they both vote in the same division.  If every time two MPs 
vote in the chamber they always vote the same way, their dissimilarity 
measure is zero.  If they always vote on opposite sides, when they both 
vote, their dissimilarity measure is one.  The actual function is: 
[Number of votes on opposite sides] / [Number of divisions in which both 
voted].

<p>Our cluster analysis calculation was done using Multi-Dimensional 
Scaling.  The mathematics behind this is available in many textbooks, 
and  <a href="http://www.ast.cam.ac.uk/~rgm/scratch/statsbook/stmulsca.html">on the web</a>.  The 
calculation itself, as opposed to the proof that this calculation gives 
what you want, is reasonably simple to describe.  Although most people 
won't understand it, it's important to mention it openly in case they do.

<p>It ought to be a rule that the public does not accept any computational 
result unless the computation is itself publicly available.  The 
analogy between computer algorithms whose output has a bearing on, say, 
government policy, and the law, is close.  We do not tolerate being 
subject to laws that are secret and unpublished, regardless of whether 
we understand them; we can hire a lawyer if we don't.  The same should 
be true with computational results which can sometimes hide a great many 
errors and fudge factors that should not be present.

<p>Multidimensional scaling.  First step: write the dissimilarity measure 
as a symmetric matrix: 650 MPs along the top, 650 MPs down the side.  
The dissimilarity measure between MP1 and MP99, say, is the same as the 
dissimilarity measure between MP99 and MP1, which is why it is 
symmetric.  The matrix also has zeros down the diagonal.

<p>Factorize this symmetric matrix into its diagonal form of an orthogonal 
matrix, times a diagonal matrix of eigen values, times the transpose of 
the orthogonal matrix.  This is one of those fundamental matrix 
operations discovered by mathematicians hundreds of years ago, and 
taught in first year college maths degrees.  The first two columns of 
the orthogonal matrix, scaled by the square root of the corresponding 
eigenvalues, are the coordinates of the points in the map.  In practice, 
we can choose any number of dimensions, or columns, to make the clusters 
in multi-dimensional space, but, in this case, two dimensions give a 
good picture.

<h2>What do the axes mean?</h2>

<p>This is the most popular question.

<p>The axes don't mean anything.  Here's why:

<p>The diagram is generated to represent the closeness of the voting 
patterns.  MPs who usually vote the same way are plotted close to one 
another, and MPs who usually vote far apart are plotted further 
distant.  You can reflect this map across a line, or rotate it through 
any angle, and the distances between the points will be no different.  
The meaningful axes you're looking don't necessarily have to be 
horizontal or vertical.  We've kept this orientation of the picture 
because it fits on the screen nicely.

<p>There can also be distortions in the angles between the clusters.  If 
the Tory party voting pattern moved close to Labour, for example, the 
axis between the Labour cluster and the LibDem cluster would rotate 
counter-clockwise to bring the Tories closer to one rather than the other.

<p>I would guess than any meaning you do see in the axes are subjective, 
post-hoc observations.  Distances are important, not the directions.  
You should pay no attention to them.

<p>I am not a believer in those Left-Right/Libertarian-Authoritarian 
political diagrams on which I've seen analysts attempt to plot people's 
political views.  This type of analysis is, I think, more of a tool of 
persuasion than of sociological measure.  The idea that you can nail 
your opinion to some point on a spectrum, and someone else can read out 
your personal set of policies from its location, is worse than 
professional astrology.  Each person's set of preferences will depend on 
personal experience, expertise, reasoning, and hearsay.  We are all so 
different with regards to the input of these factors.  It's not probable 
they would fit into a philosophically pre-determined spectrum.

<p>Perhaps some sort of survey and cluster analysis will suggest a 
different, realistic pattern.  But the measurements will be too 
confounded by the persuasive nature of policy tables having done their 
work already.  Such a survey would have to work from behavioural data, 
rather than stated opinion polls.

<p>One very good critique of our current electoral system is that it 
depends entirely on the self-measurement of human opinion.  Human beings 
are notorious for holding opinions that are systematically at odds with 
even their own reality (eg to ask: "How many units of alcohol do you 
think you drink a week?").  Policy spectrums, which this cluster diagram 
is emphatically not, are an easy way to influence political opinions by 
bundling policies up -- ones which you do like, together with ones you 
don't fully understand and probably wouldn't like if you did -- and 
getting you to pick from them.  In practice, influencing opinions are 
far easier for many politicians and vested interests to do, particularly 
for ones not immediately in power, than to make changes to reality.

<p>The election game, which puts the public's battered and misdirected 
opinion at a higher level of importance than any sociological measure, 
is clearly treated as a sport by the professional players.


<h2>Why is Tony Blair and his cabinet so far away from the rest of his party?</h2>

<p>I suspect it's because they mostly show up to votes which tend to be on 
contentious issues when many MPs are rebelling.  This gives them a 
higher than expected dissimilarity measure than if they turned up to 
all the non-contentious votes when there was no rebellion.  They show up 
during these contentious issues in order to encourage their MPs to vote 
the way they want; the rebellions could have been larger had they not shown up.

<p>The impression that they are pulling their party away from its centre of 
gravity, in the way that the leaders of the other parties are not, is 
probably correct.


<h2>What are the green dots?</h2>

<p>We've coloured the MPs who are not in the three big parties green.  
These parties don't have enough MPs to form colourful clusters; it's for 
aesthetic reasons, rather than anything we have against these smaller 
parties, that they are all lumped together.  You can, however, click on 
the individual members to find out pretty quickly that the Welsh and 
Scottish national party members tend to associate with the LibDems, 
while the Ulster parties tend to align with the Tories.


<h2>Any future developments?</h2>

<p>We've tried a few experiments, such as subselecting for votes on 
particular issues, and calculating the pattern for a three-month sliding 
window and animating it through time.  Neither produced very 
enlightening results, so we've not bothered to publish them.

<p>The pattern per parliament is reasonably stable and consistent.  In 
fact, it's a much better result than you normally get from cluster 
analysis of any kind.  I think these diagrams are about as far as it 
goes with this, and they are not bad.  If you would like the data in a 
form you can play with in your own cluster analysis software, then 
you download it on our <a href="project/data.php">Raw Data</a> page.

<p><b>2004-02-06</b> Chris Lightfoot did just that, and has generated very
interesting cluster graphics using principal component analyis.  This differs
from our distance-metric based clustering, by instead rotating a
multidimensional space so the 2D projection you see has the maximum variance
across it.  Full details, pictures and political commentary can be found in Chris's blog
entries <a
href="http://ex-parrot.com/~chris/wwwitter/20040203-which_parliamentary_co-ordinate_are_you.html">
"Which Parliamentary co-ordinate are you?"</a> and
<a href="http://www.ex-parrot.com/~chris/wwwitter/20040211-nontraditional_political_movements.html">"Nontraditional
political movements"</a>.  Chris's analysis enables him to work out what
the axes mean, and draw pictures of how MPs move between the last two parliaments.  Go have a look.
<p>

<p>More of the same?  <a href="minwhirl.php">Try our Ministerial Whirl</a></p>

<?php pw_footer() ?>

