<?php

# $Id: db.inc,v 1.7 2005/01/14 16:07:26 frabcus Exp $
# Database access wrapper.  Calls mysql.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

include_once "config.inc";

function db_scrub($text)
{
    return mysql_escape_string(stripslashes($text));
}

function html_scrub($text)
{
    return htmlentities(html_entity_decode(stripslashes($text)));
}

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
#print $query;
        $this->$result = mysql_query($query, $this->link) 
            or die("Query failed : " .  mysql_error());
    }

    function query_errcheck($query)
    {
#print $query;
        $this->$result = mysql_query($query, $this->link);
        return $this->$result;
    }


    function fetch_row()
    {
        return mysql_fetch_row($this->$result);
    }

    function fetch_row_assoc()
    {
        return mysql_fetch_assoc($this->$result);
    }


    function fetch_rows_assoc()
    {
        $ret = array();
        while ($row = mysql_fetch_assoc($this->$result))
        {
            array_push($ret, $row);
        }
        return $ret;
    }


    function rows()
    {
        if (gettype($this->$result) == "boolean")
            return $this->$result;
        return mysql_num_rows($this->$result);
    }

    function query_one_row($query)
    {
        $this->query($query);
        if ($this->rows() != 1) die("Single row query didn't get one row, got " . $this->rows());
        $row = $this->fetch_row();
        return $row;
    }

    function query_one_row_assoc($query)
    {
        $this->query($query);
        if ($this->rows() != 1) die("Single row query didn't get one row, got " . $this->rows());
        $row = $this->fetch_row_assoc();
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
