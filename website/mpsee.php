<?php $title = "Vote map"; include "header.inc" 
# $Id: mpsee.php,v 1.3 2003/09/19 16:06:37 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.
?>


<?
    include "db.inc";
?>

<p>For your convenience, this is a Java applet for 
interactively navigating the space of MPs clustered by 
their voting records.  </p>

<p>Click and drag the mouse pointer 
in the image to drag, zoom, or select from the space.  
(Click on the radio buttons at the bottom 
marked "Drag", "Zoom", or "Select" to determine the mode.)  
Zooming happens if you drag the mouse pointer right or left.  </p>

<p>The panel on the right shows the list of MPs.  
Selected names are highlighted in white in the image.  Warning: 
when you select from the image with the circle pointer, 
you may get more than one MP, and you will have to scroll 
through the list to see them all.  </p>  

<p>Not working?  If you are able, download <a href="http://www.java.com">Sun's Java
software</a>.  On Windows, the old unsupported Microsoft versions of Java will not do.
Alternatively, get a taste with a <a href="mpsee.png">static
screenshot</a> of the clustered MPs.
</p>

<center>
<applet code="mpapplet.class" archive="mpscatt.jar" width="700" height="400">
    <param name="posfile" value="mpcoords.txt">
	alt="Java applet."
</applet>
</center>

<hr class="bottomline">

<h2>What is this picture showing? </h2> 

<p>This requires a few words of explanation.  </p> 

<p>Imagine you picked 5 cities in Europe: 
Amsterdam, Antwerp, Athens, Barcelona, and Basel, 
and you wrote down distance table (in kilometres) 
between them, like so: </p>

<pre>
Amsterdam | Antwerp | Athens | Barcelona | Basel | 
        0 |     156 |   3022 |      1538 |   780 | Amsterdam
      156 |       0 |   2971 |      1365 |   629 | Antwerp     
     3022 |    2971 |      0 |      3313 |  2567 | Athens
     1538 |    1365 |   3313 |         0 |  1056 | Barcelona
      780 |     629 |   2567 |      1056 |     0 | Basel
</pre>

<p>I copied these numbers out of a road atlas I 
happened to find.  Let us suppose these distances are 
"as the crow flies".  This table of distances is a 
symmetric matrix of values.  </p>  

<p>From this matrix, it's possible to recover the relative 
locations of these cities on a map.  You can do this by 
cutting lengths of stiff wire to scale and arranging them on a 
table so that ends corresponding to the same city matched up.  </p>   

<p>The other technique is to use matrix algebra to recover the 
positions using a method called "Multi-Dimensional Scaling" 
(in this case, dimensions equals 2).  
The calculation for 600 cities takes about 
three minutes on a home computer.  </p>

<p>What does this have to do with MPs?  
Using Multi-Dimensional Scaling, we can start with a table 
of distances between people that has nothing to do with 
cities on a map, and use the same algorithm to work out 
where these people would have to be put on a map to best 
represent their positions in relation to one another.  </p>  

<p>In this experiment, 
the distance between two MPs is the proportion of divisions 
in which they voted on opposite sides out of the number of 
times they both voted in the same division.  
Two MPs who always vote against one another are distance 1.0 apart, 
while two MPs who always vote the same way are distance 0.0 apart.  </p>

<p>So, that's how this diagram is made.  
The choice of how we make up the distances is arbitrary, 
and if I had more time I'd experiment with more than one 
possible metric.  
It's likely we ought to throw out several of the outliers 
(eg MPs who never vote on anything) who may be distorting 
the map by their presence.  
Maybe we can try to make an image for each year  
so as to see if we can detect drifts in voting patterns 
as MPs progress through their careers.  </p>  

<p>Whatever you think of it, it's just a bit of fun, not to 
be taken too seriously.  One can say for certain 
that the results here need some debugging.  For example, 
the Prime Minister is way out on the fringe of the diagram, and 
that can't be true.  Anyone is free to have a look at 
our program and run it, and work out what is going awol.  </p>  

<p>I do consider it encouraging that the parties 
have clustered in the image.  Notice that the shape is 
two-dimensional, rather than extending along a 
left-right political axis of the kind they teach 
you about in your first lesson on politics.   
I remember being told that there is this 
one-dimensional space of political opinion, with 
communists on the left, and feudalists on the right, 
onto which you had to nail your political colours.  
And, from the position on the line you choose, 
it was possible to 
inform your entire political mind down to the finest detail.  </p>  

<p>The fact is, there are many distinct political issues 
which are not constrained together in one vector.  You may be 
pro-road building, but against city centre incinerators, 
even though the two issues tend to be highly correlated 
across the spectrum of parties, from the ones that 
are pro-business and for letting them build whatever they like, 
to those that are anti-business who would prefer development 
cease altogether.  
Whereas, the people might like some things 
to be selectively built, but don't want their air 
contaminated just because it's allowed.  </p> 

<p>There's an interesting experiment which may get done 
one day, based on this image.  
Suppose we selected, say, fifty interesting votes in 
parliament (which are, after all, done on our behalf), 
and we asked all the people in a 
representative sample of the general public 
to vote on them, and act as a people's parliament.  
I don't know what the results 
of this would be, but let's suppose people's interests 
are often the same to an extent that we can't see, 
because we are artificially divided by the choice of  
different parties.  Suppose the votes of the general public formed 
a single, fourth cluster in this multi-dimensional image.  
If this cluster is nowhere near any of the three parties, 
what does this say about the system?  How can we explain why the 
parties are where they are, and not where the people are?  
Is it a fact that we are being taken for a 
ride and just could not prove it?  </p>  

<?php include "footer.inc" ?>
