-- $Id: create.sql,v 1.13 2004/03/26 14:09:32 frabcus Exp $
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

-create table pw_mp (
-    mp_id int not null primary key auto_increment,
-    first_name varchar(100) not null,
-    last_name varchar(100) not null,
-    title varchar(100) not null,
-    constituency varchar(100) not null,
-    party varchar(100) not null,
-
-    -- these are inclusive, and measure days when the MP could vote
-    entered_house date not null default '1000-01-01',
-    left_house date not null default '9999-12-31',
-    entered_reason enum('unknown', 'general_election', 'by_election', 'changed_party',
-        'reinstated') not null default 'unknown',
-    left_reason enum('unknown', 'still_in_office', 'general_election',
-        'changed_party', 'died', 'declared_void', 'resigned',
-        'disqualified', 'became_peer') not null default 'unknown',
-
-    unique(first_name, last_name, constituency, entered_house, left_house)
-);

create table pw_division (
    division_id int not null primary key auto_increment,
    valid bool,

    division_date date not null,
    division_number int not null,
    division_name text not null,
    source_url blob not null, -- exact source of division
    debate_url blob not null, -- start of subsection
    motion blob not null,
    notes blob not null,

    unique(division_date, division_number)
);

create table pw_vote (
    division_id int not null,
    mp_id int not null,
    vote enum("aye", "no", "both", "tellaye", "tellno") not null,

    index(division_id),
    index(mp_id).
    index(vote),
    unique(division_id, mp_id, vote)
);

CREATE TABLE pw_dyn_user (
  user_id int(11) NOT NULL auto_increment,
  user_name text,
  real_name text,
  email text,
  password text,
  remote_addr text,
  confirm_hash text,
  is_confirmed int(11) NOT NULL default '0',
  is_newsletter int(11) NOT NULL default '1',
  reg_date datetime default NULL,
  PRIMARY KEY  (user_id)
) TYPE=MyISAM;

-- rolliemp is as in "roll your own MP", an old name for "Dream MP"

create table pw_dyn_rolliemp (
    rollie_id int not null primary key auto_increment,
    name varchar(100) not null,
    user_id int not null,
    description blob not null,

    unique(rollie_id, name, user_id)
);

create table pw_dyn_rollievote (
    division_date date not null,
    division_number int not null,
    rolliemp_id int not null,
    vote enum("aye", "no", "both") not null,

    index(division_date),
    index(division_number),
    index(rolliemp_id),
    unique(division_date, division_number, rolliemp_id)
);

create table pw_dyn_auditlog (
    auditlog_id int not null primary key auto_increment,
    user_id int not null,
    event_date datetime,
    event text,
    remote_addr text
);

