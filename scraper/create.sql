-- $Id: create.sql,v 1.1 2003/08/14 19:35:48 frabcus Exp $
-- SQL script to create the empty database tables for publicwhip.
--
-- The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
-- This is free software, and you are welcome to redistribute it under
-- certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
-- For details see the file LICENSE.html in the top level of the source.

--
-- You need to do the following to use this:
--
-- 1. Install MySQL.
--
-- 2. Create a new database. Giving your user account permission to access
--    it from the host you will be running the client on.  Try using
--    mysql_setpermission to do this with.
-- 
-- 3. Type something like "cat create.sql | mysql --database=yourdb -u username -p"
--    Or you can load this file into some GUI client and inject it.
-- 

drop table if exists pw_hansard_day, pw_debate_content;
drop table if exists pw_mp, pw_division, pw_vote;

create table pw_hansard_day (
    day_date date not null,
    first_page_url blob not null,

    unique(day_date)
);

create table pw_debate_content (
    day_date date not null,
    content longblob,
    download_date datetime not null,
    divisions_extracted int not null default 0,

    unique(day_date)
);

create table pw_mp (
    mp_id int not null primary key auto_increment,
    first_name varchar(100) not null,
    last_name varchar(100) not null,
    title varchar(100) not null,
    constituency varchar(100) not null,
    party varchar(100) not null,

    -- these are inclusive, and measure days when the MP could vote
    entered_house date not null default '1000-01-01',
    left_house date not null default '9999-12-31',

    unique(first_name, last_name, constituency, entered_house, left_house)
);

create table pw_division (
	division_id int not null primary key auto_increment,
    valid bool,

    division_date date not null,
    division_number int not null,
    division_name blob not null,
    source_url blob not null,
    motion blob not null,
    notes blob not null,

    unique(division_date, division_number)
);

create table pw_vote (
    division_id int not null,
    mp_id int not null,
    vote enum("aye", "noe") not null,

    index(division_id),
    index(mp_id)
);

