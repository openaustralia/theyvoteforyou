<?php

# $Id: db.inc,v 1.1 2003/08/14 19:35:48 frabcus Exp $
# Database access wrapper.  Calls mysql.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

include "/home/francis/.pwdb.inc";

class DB
{
    var $link;
    var $result;

    function DB()
    {
        $this->connect();
    }

    function connect()
    {
        global $host, $user, $password, $database;

        $this->link = mysql_connect($host, $user, $password) 
            or die("Could not connect : " . mysql_error());

        mysql_select_db($database, $this->link) 
           or die("Could not select database : " . mysql_error());
    }

    function query($query)
    {
        $this->$result = mysql_query($query, $this->link) 
            or die("Query failed : " .  mysql_error());
    }

    function fetch_row()
    {
        return mysql_fetch_row($this->$result);
    }

    function rows()
    {
        return mysql_num_rows($this->$result);
    }

    function query_one_row($query)
    {
        $this->query($query);
        if ($this->rows() != 1) die("Single row query didn't get one row, got " . $this->rows());
        $row = $this->fetch_row();
        return $row;
    }

    function query_one_value($query)
    {
        $row = $this->query_one_row($query);
        if (count(row) != 1) die("Single value query didn't get one value, got " . count(row));
        return $row[0];
    }

    function disconnect()
    {
    #    mysql_free_result($result);
        mysql_close($this->link);
    }

}

?>
