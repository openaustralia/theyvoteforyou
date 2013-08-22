

lookupstrength = ["a", "z", "b", "c", "d", "z", "e"];
function UpdateCItable()
{
    var hrefhash = location.href.lastIndexOf('#');
    var hrefpos = (hrefhash != -1 ? location.href.substring(hrefhash + 1) : "");
    //alert(hrefpos);

    var imap = [ ];
    var vkey = "";
    for (var j = 0; j < issues.length; j++)
    {
        var issue = issues[j]; 
        var option = document.getElementById("issue-" + issue);
        var strength = document.getElementById("issue-strength-" + issue);
        
        imap[j] = parseInt(option.value) * (strength.checked ? 3 : 1); 
        if (option.value == 0)
            alert("ususu " + issue); //option.style.color = "red";
        
        //if (j == 0)
            alert("ususu " + option.value); //option.style.color = "red";
        
        var rowid = issue + "-row";
        
        // this is the bit that shows-hides
        var selerow = "selerowc-" + issue;
        var seletd = document.getElementById(selerow);
        
        var seletr = document.getElementById(rowid);
        var newstr = document.getElementById("newsart-" + issue);
        if (imap[j] != 0)
        {
            seletr.style.display = "";
            newstr.style.display = "none";
        }
        else
        {
            seletr.style.display = "none";
            newstr.style.display = "";
        }
        //if (selerow == hrefpos)
        //    seletd.style.height = "400px";
        //else
        //    seletd.style.height = "";

        var vkey = vkey + lookupstrength[imap[j] + 3]; 
    };
    var vkeyval = document.getElementById("vkey");
    if (vkeyval)
        vkeyval.value = vkey;
    
    var bestval;
    var bestlist = [ ]
    var nissues = 0;
    
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
                    bcolour = "#f078ae";
                else if (score < -0.2)
                    bcolour = "#ccaaaa";
                else if (score <= 0.2)
                    bcolour = "#bbbbbb";
                else if (score <= 0.7)
                    bcolour = "#bcddbc";
                else
                    bcolour = "#adffad";
            
                snum += score;
                sdem += Math.abs(imap[j]);
            }
            cell.style.backgroundColor = bcolour;
        }

        if (sdem != 0.0)
        {
            var srat = snum / sdem;
            var score = Math.round((snum + sdem) * 5); 
            if ((bestlist.length == 0) || (bestval < score))
            {
                bestlist.length = 0;
                bestval = score;
            }
            if (bestval == score)
                bestlist.push(i);
            //var ssrat = String(Math.round(srat * 50));
            var ssrat = String(score) + " out of " + String(Math.round(sdem * 2 * 5));
            //var ssrat = String(snum) + " / " + String(sdem);
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

        // copy best selections into lower duplicate row
        var mpcelll = document.getElementById(mpcellid + "l");
        mpcelll.style.backgroundColor = mpcell.style.backgroundColor;
        var rkcelll = document.getElementById(rkcellid + "l");
        rkcelll.style.backgroundColor = rkcell.style.backgroundColor;
        rkcelll.innerHTML = rkcell.innerHTML;
    }
}

function NextClick(dreamidselect)
{
    var hrefhash = location.href.lastIndexOf('#');
    var hrefbase = (hrefhash != -1 ? location.href.substring(0, hrefhash) : location.href);
    var hrefpos = "selerowc-" + dreamidselect;
    for (var j = 0; j < issues.length; j++)
    {
        var selerow = "selerowc-" + issues[j];
        var seletd = document.getElementById(selerow);
        if (selerow == hrefpos)
            seletd.style.height = "400px";
        else
            seletd.style.height = "";
    }
    location.href = hrefbase + "#" + hrefpos;
    //UpdateCItable();
}

// this function is defunct
function shownews(newsid, athis)
{
    var newsul = document.getElementById(newsid);
    if (newsul.style.display == "inline")
        newsul.style.display = "none";
    else
        newsul.style.display = "inline";
    athis.innerHTML = (newsul.style.display == "none" ? "show news" : "hide news");
}


