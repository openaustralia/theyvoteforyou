-- $Id: create.sql,v 1.7 2005/01/23 14:31:37 frabcus Exp $
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

-------------------------------------------------------------------------------
-- Static tables
--   those based on Hansard data, which get updated, but not altered by scripts

drop table if exists pw_mp, pw_division, pw_vote, pw_moffice;

create table pw_mp (
    mp_id int not null primary key auto_increment,
    first_name varchar(100) not null,
    last_name varchar(100) not null,
    title varchar(100) not null,
    constituency varchar(100) not null,
    party varchar(100) not null,

    -- these are inclusive, and measure days when the mp could vote
    entered_house date not null default '1000-01-01',
    left_house date not null default '9999-12-31',
    entered_reason enum('unknown', 'general_election', 'by_election', 'changed_party',
        'reinstated') not null default 'unknown',
    left_reason enum('unknown', 'still_in_office', 'general_election',
        'changed_party', 'died', 'declared_void', 'resigned',
        'disqualified', 'became_peer') not null default 'unknown',

    person int,

    unique(first_name, last_name, constituency, entered_house, left_house)
);

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

    source_gid text not null, -- global identifier
    debate_gid text not null, -- global identifier

    unique(division_date, division_number)
);

create table pw_vote (
    division_id int not null,
    mp_id int not null,
    vote enum("aye", "no", "both", "tellaye", "tellno") not null,

    index(division_id),
    index(mp_id),
    index(vote),
    unique(division_id, mp_id, vote)
);

-- Ministerial offices
create table pw_moffice (
    moffice_id int not null primary key auto_increment,

    dept varchar(100) not null,
    position varchar(100) not null,

    -- these are inclusive, the person became a minister at some time
    -- on the start date, and finished on the end date
    from_date date not null default '1000-01-01',
    to_date date not null default '9999-12-31',

    person int,

    index(person)
);

-------------------------------------------------------------------------------
-- Dynamic tables
--   those which people using the website can alter 
--   prefixed dyn_ for dynamic

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

-- changes people have been making are stored here for debugging
create table pw_dyn_auditlog (
    auditlog_id int not null primary key auto_increment,
    user_id int not null,
    event_date datetime,
    event text,
    remote_addr text
);

-- for wiki text objects.  this is a transaction table, we only
-- insert rows into it, so we can show history.  when reading
-- from it, use the most recent row for a given object_key.
create table pw_dyn_wiki (
    wiki_id int not null primary key auto_increment,
    -- name/id of object this is an edit of 
    object_key varchar(100) not null, 

    -- the new text that has change
    text_body text not null,

    -- who and when this changes was made
    user_id int not null, 
    edit_date datetime,

    index(object_key)
);

create table pw_dyn_newsletters_sent (
    user_id int not null,
    newsletter_name varchar(100) not null,

    unique(user_id, newsletter_name)
);

-------------------------------------------------------------------------------
