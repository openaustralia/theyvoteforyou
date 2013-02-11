<?php

# $Id: db.inc,v 1.33 2011/06/12 20:44:44 publicwhip Exp $
# Database access wrapper.  Calls mysql.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.
$pwpdo = new PWPDO();
$pwpdo2 = new PWPDO();
$db=new DB(); // needed for calls to mysql_real_escape_string

# debug setting which prints out all the statements in the SQL calls
$bdebug = 0;


function db_scrub($text)
{
    return mysql_real_escape_string($text);
}

function html_scrub($text)
{
    return htmlentities(html_entity_decode(stripslashes($text), ENT_COMPAT, 'UTF-8'), ENT_COMPAT, 'UTF-8');
}

function isrobot()
{
    $useragent = $_SERVER["HTTP_USER_AGENT"];
    return preg_match(
        "/(Google|Slurp|msnbot|robot|Gigabot|Teoma|VoilaBot|searchme|ia_archiver|Crawler|MSNBOT|MLBot|Wget|Yandex)/",
        $useragent
    );
}

function possiblexss($string) {
    $requesturi = (isset($_SERVER['REQUEST_URI']) === true ? $_SERVER['REQUEST_URI'] : '[no url]');
    error_log('Possible XSS: === [' . $string . '] === on page ' . $requesturi);
}

function disabled($string) {
    $requesturi = (isset($_SERVER['REQUEST_URI']) === true ? $_SERVER['REQUEST_URI'] : '[no url]');
    error_log('Disabled function called: === [' . $string . '] === on page ' . $requesturi);
}


class PWPDO
{
    public $pdo;
    public $currentstatement;

    private function logfail(Exception $e,$message,$query,$placeholders=array()) {
        $requesturi = (isset($_SERVER['REQUEST_URI']) === true ? $_SERVER['REQUEST_URI'] : '[no url]');
        error_log($message.' : '.$e->getMessage().' when running '.$query.' '.print_r($placeholders,TRUE).' on '.$requesturi);
        trigger_error('Database error '.$e->getMessage().' : '.$message,E_USER_ERROR);
    }

    public function __construct()
    {
        global $pw_host, $pw_user, $pw_password, $pw_database;
        try {
            $this->pdo = new PDO(
                'mysql:dbname=' . $pw_database .
                    ';host=' . $pw_host, $pw_user,
                $pw_password,
                array(PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8"));
            $this->pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch (Exception $e) {
            die('Unable to access database:' . $e->getMessage());
        }
    }

    private function prepare($query)
    {
        //error_log('new:'.$query);
        try {
            return $this->pdo->prepare($query);
        } catch (Exception $e) {
            $this->logfail($e,'Unable to prepare query',$query);
        }
    }

    function get_single_row($query, $placeholders)
    {
        $statement = $this->prepare($query);
        try {
        $statement->execute($placeholders);
        } catch (Exception $e) {
            $this->logfail($e,'Unable to run get_single_row',$query,$placeholders);
        }
        $data = $statement->fetch(PDO::FETCH_ASSOC);
        if (is_array($data) === false) {
            return null;
        }
        $test = $statement->fetch(PDO::FETCH_ASSOC);
        if (is_array($test) === true && count($test)>0) {
            $this->logfail(new Exception(),'get_single_row got more than 1 row',$query);
        }
        return $data;
    }

    public function fetch_all_rows($query, $placeholders)
    {
        try {
            $statement = $this->prepare($query);
            $statement->execute($placeholders);
        } catch (Exception $e) {
            $this->logfail($e,'fetch_all_rows',$query,$placeholders);
        }
        return $statement->fetchAll(PDO::FETCH_ASSOC);
    }

    public function query($query, $placeholders)
    {
        try {
            $this->statement = $this->prepare($query);
            $this->statement->execute($placeholders);
        } catch (Exception $e) {
            $this->logfail($e,'query',$query,$placeholders);
        }

    }

    public function fetch_row()
    {
        try {
            return $this->statement->fetch(PDO::FETCH_ASSOC);
        } catch (Exception $e) {
            $this->logfail($e,'fetch_row','');
        }
    }

    public function quote($string) {
        return $this->pdo->quote($string);
    }
}

class DB
{
    var $link;
    var $result;

    public function __construct()
    {
        $this->connect();
    }

    function connect()
    {
        global $pw_host, $pw_user, $pw_password, $pw_database;

        $this->link = mysql_connect($pw_host, $pw_user, $pw_password)
            or trigger_error("Could not connect : " . mysql_error(), E_USER_ERROR);

        mysql_query("SET NAMES 'utf8'", $this->link);
        mysql_select_db($pw_database, $this->link)
            or trigger_error("Could not select database : " . mysql_error(), E_USER_ERROR);

    }

    function query($query)
    {
        $requesturi = (isset($_SERVER['REQUEST_URI']) === true ? $_SERVER['REQUEST_URI'] : '[no url]');
        error_log('Old query: == ' . $query . ' == on page ' . $requesturi);
        $x = mysql_query($query, $this->link)
            or trigger_error("Query failed : " . mysql_error(), E_USER_ERROR);
        $this->result = $x;
    }

    function query_errcheck($query)
    {
        $this->result = mysql_query($query, $this->link);
        return $this->result;
    }


    function fetch_row()
    {
        return mysql_fetch_row($this->result);
    }

    function fetch_row_assoc()
    {
        return mysql_fetch_assoc($this->result);
    }

    function fetch_row_both()
    {
        return mysql_fetch_array($this->result, MYSQL_BOTH);
    }

    function fetch_rows_assoc()
    {
        $ret = array();
        while ($row = mysql_fetch_assoc($this->result)) {
            array_push($ret, $row);
        }
        return $ret;
    }


    function rows()
    {
        if (gettype($this->result) == "boolean") {
            return $this->result;
        }
        return mysql_num_rows($this->result);
    }

    function query_one_row($query)
    {
        $this->query($query);
        if ($this->rows() != 1) {
            trigger_error(
                "query_one_row: Single row query didn't get one row, got " . $this->rows() . " on query: " . $query,
                E_USER_ERROR
            );
        }
        $row = $this->fetch_row();
        return $row;
    }

    function query_onez_row($query)
    {
        $this->query($query);
        if ($this->rows() == 0) {
            return null;
        }
        if ($this->rows() != 1) {
            trigger_error(
                "query_one_row: Single row query didn't get one row, got " . $this->rows() . " on query: " . $query,
                E_USER_ERROR
            );
        }
        $row = $this->fetch_row();
        return $row;
    }


    function query_one_row_assoc($query)
    {
        $this->query($query);
        if ($this->rows() != 1) {
            trigger_error(
                "query_one_row_assoc: Single row query didn't get one row, got " . $this->rows(
                ) . " on query: " . $query,
                E_USER_ERROR
            );
        }
        $row = $this->fetch_row_assoc();
        return $row;
    }

    function query_onez_row_assoc($query)
    {
        $this->query($query);
        $rows = $this->rows();
        if ($rows == 0) {
            return null;
        }
        if ($rows != 1) {
            trigger_error(
                "query_onez_row_assoc: Single row query didn't get one row, got " . $rows . " on query: " . $query,
                E_USER_ERROR
            );
        }
        $row = $this->fetch_row_assoc();
        return $row;
    }

    function query_one_value($query)
    {
        $row = $this->query_one_row($query);
        if (count(row) != 1) {
            trigger_error(
                "Single value query didn't get one value, got " . count(row) . " on query: " . $query,
                E_USER_ERROR
            );
        }
        return $row[0];
    }

    function disconnect()
    {
        mysql_close($this->link);
    }

}
