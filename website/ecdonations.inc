<?php
    $ecconstituency = $mpprop['constituency']; 
    $ecconstituency = preg_replace('# &amp; .*#', '', $ecconstituency); 
    $ecconstituency = preg_replace('# and .*#', '', $ecconstituency); 
?>
<li>
<form action="http://registers.electoralcommission.org.uk/regulatory-issues/regdpoliticalparties.cfm?ec=%7Bts%20%272010%2D02%2D24%2016%3A23%3A20%27%7D" method="post">
    <input type="hidden" name="frmPreviewPage" value="0">
    <select id="id_political" class="eclong" name="frmPartyID">
        <option value="0">All</option>
    </select>
    <select name="frmType" size="1" class="eclong" id="id_donationtype">
        <option value="0">All</option>
    </select>
    <select name="frmPeriod" size="1" class="eclong" id="id_quarterly">
        <option value="0">All</option>
    </select>
    <select name="frmPeriodTo" size="1" class="eclong" id="id_quarterly">
        <option value="0" selected></option>
    </select>
    <input type="Hidden" class="eclong" name="frmPeriodList"  value="12001,22001,32001,42001,12002,22002,32002,42002,12003,22003,32003,42003,12004,22004,32004,42004,12005,22005,32005,42005,12006,22006,32006,42006,12007,22007,32007,42007,12008,22008,32008,42008,12009,22009,32009,42009"/>
    <select name="frmAmount" class="eclong" size="1" id="id_donationvalue">
        <option value="" selected="selected">All</option>
    </select>
    <select name="frmStatus" size="1" class="eclong" id="id_status">
        <option value="">Any</option>
    </select>
    <input id="id_donorname" class="eclong" type="text" name="frmName" maxlength="100" size="24">
    <input id="id_companyreg" class="eclong" type="text" name="frmCompany" maxlength="100" size="24"> 
    <input id="id_dateacceptedreturned" class="eclong" type="text" name="frmDate" maxlength="11" size="12">
    
    <b>New!</b> Local party donations declared to the Electoral Commission: 
    <input id="id_received" class="ecbranch" type="text" name="frmReceived" size="16" value="<?php echo $ecconstituency?>">
    <input id="id_submit" class="ecsubmit" type="submit" name="submitButtonName" value="Search">
</form>
</li>

