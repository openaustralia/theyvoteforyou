


function UpdateCItable()
{
    var imap = [ ];
    for (var j = 0; j < issues.length; j++)
    {
        var option = document.getElementById("issue-" + issues[j]);
        imap[j] = parseInt(option.value); // this will be multiplied up by an importance rating (1-5, say)
        var rowid = issues[j] + "-row";
        document.getElementById(rowid).style.display = (imap[j] == 0 ? "none" : "");
    };
    
    var bestval;
    var bestlist = [ ]
    
    for (var i = 0; i < candidates.length; i++)
    {
        var sdem = 0.0; 
        var snum = 0.0;

        for (var j = 0; j < issues.length; j++)
        {
            var cellid = candidates[i] + "-" + issues[j];
            var cell = document.getElementById(cellid);
            var distance = citable[i][j];

            var bcolour;
            if (distance == -1)
                bcolour = "gray"; // not present
            else if (imap[j] == 0)
                bcolour = "gray"; // neutral
            else
            {
                var score = -(distance - 0.5) * 2 * imap[j];
   
                if (score < -0.7)
                    bcolour = "#9999ee";
                else if (score < -0.2)
                    bcolour = "#aaaacc";
                else if (score <= 0.2)
                    bcolour = "#bbbbbb";
                else if (score <= 0.7)
                    bcolour = "#ccddcc";
                else
                    bcolour = "#eeffee";
            
                snum += score;
                sdem += Math.abs(imap[j]);
            }
            cell.style.backgroundColor = bcolour;
        }

        if (sdem != 0.0)
        {
            var srat = snum / sdem;
            if ((bestlist.length == 0) || (bestval < srat))
            {
                bestlist.length = 0;
                bestval = srat;
            }
            if (bestval == srat)
                bestlist.push(i);
            var ssrat = String(Math.round(srat * 50));
        }
        else
            var ssrat = "undetermined";
        var rkcellid = candidates[i] + "-rank";
        var rkcell = document.getElementById(rkcellid);
        rkcell.innerHTML = ssrat;
    }
    
    // now mark the best by colour
    bestlist.reverse();
    for (var i = 0; i < candidates.length; i++)
    {
        var bbest = ((bestlist.length != 0) && (bestlist[bestlist.length - 1] == i))
        if (bbest)
            bestlist.pop();
        
        var mpcellid = candidates[i] + "-name";
        var mpcell = document.getElementById(mpcellid);
        mpcell.style.backgroundColor = (bbest ? "#eeffee" : "#9999ee");

        var rkcellid = candidates[i] + "-rank";
        var rkcell = document.getElementById(rkcellid);
        rkcell.style.backgroundColor = (bbest ? "#eeffee" : "#9999ee");
        if (bbest)
            rkcell.innerHTML += " (best)";
    }
}


function shownews(newsid, athis)
{
    var newsul = document.getElementById(newsid);
    if (newsul.style.display == "inline")
        newsul.style.display = "none";
    else
        newsul.style.display = "inline";
    athis.innerHTML = (newsul.style.display == "none" ? "show news" : "hide news");
}


