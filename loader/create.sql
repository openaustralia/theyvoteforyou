-- $Id: create.sql,v 1.59 2009/05/24 13:05:35 marklon Exp $
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
-- 3. Type something like "mysql --database=yourdb -u username -p < create.sql"
--    Or you can load this file into a GUI client and inject it.
-- 

-------------------------------------------------------------------------------
-- Static tables
--   those based on Hansard data, which get updated, but not altered by scripts

drop table if exists pw_seat, pw_division, pw_vote, pw_moffice;

-- A seat in parliament for a period of time, also changes if party changes.
-- MPs and Peers are in this table.  The fields originally just stored data
-- about MPs; they have been overloaded to also store info about Lords
create table pw_mp (
    mp_id int not null primary key, -- internal to Public Whip

    gid varchar(100) not null, -- uk.org.publicwhip/member/123, uk.org.publicwhip/lord/123
    source_gid text not null, -- global identifier
    
    first_name varchar(100) not null, -- Lords: "$lordname" or empty string for "The" lords
    last_name varchar(100) not null, -- Lords: "of $lordofname"
    title varchar(50) not null, -- Lords: (The) Bishop / Lord / Earl / Viscount etc...
    constituency varchar(100) not null, -- Lords: NOT USED
    party varchar(100) not null, -- Lords: affiliation
    house enum('commons', 'lords', 'scotland') not null,

    -- these are inclusive, and measure days when the mp could vote
    entered_house date not null default '1000-01-01',
    left_house date not null default '9999-12-31',
    entered_reason enum('unknown', 'general_election', 'by_election', 'changed_party',
        'reinstated') not null default 'unknown',
    -- general_election has three types 1) unknown 2) MP didn't try to stand
    -- again (or was deselected, etc.) 3) MP did try to stand again (if successful
    -- they will appear in another record)
    left_reason enum('unknown', 'still_in_office', 
        'general_election', 'general_election_standing', 'general_election_notstanding',
        'changed_party', 'died', 'declared_void', 'resigned',
        'disqualified', 'became_peer') not null default 'unknown',

    person int,

    index(entered_house),
    index(left_house),
    index(person),
    index(house),
    index(party),
    index(gid),
    -- Need title in the unique key here, to distinguish the Mr and Sir Rowland
    -- Blennerhassetts who were simultaneously both MPs for Kerry constituency
    -- between 1880 and 1885
    unique(title, first_name, last_name, constituency, entered_house, left_house, house)
) DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Has multiple entries for different spellings of each constituency
create table pw_constituency (
    cons_id int not null,
    name varchar(100) not null,
    main_name bool not null,

    -- these are inclusive, and measure days when the boundaries were active
    from_date date not null default '1000-01-01',
    to_date date not null default '9999-12-31',

    -- need this to distinguish between Scottish constituencies and
    -- identically named ones in Westminster
    house enum('commons', 'scotland') not null default 'commons',

    index(from_date),
    index(to_date),
    index(name),
    index(cons_id, name)
) DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

create table pw_division (
    division_id int not null primary key auto_increment,
    valid bool,

    division_date date not null,
    division_number int not null,
    house enum('commons', 'lords', 'scotland') not null,

    division_name text not null,
    source_url blob not null, -- exact source of division
    debate_url blob not null, -- start of subsection
    motion blob not null,
    notes blob not null,
    clock_time text,

    source_gid text not null, -- global identifier
    debate_gid text not null, -- global identifier
    
    index(division_date),
    index(division_number),
    index(house),
    unique(division_date, division_number, house)
) DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

create table if not exists pw_vote (
    division_id int not null,
    mp_id int not null,
    vote enum("aye", "no", "both", "tellaye", "tellno", "abstention", "spoiled") not null,

    index(division_id),
    index(mp_id),
    index(vote),
    unique(division_id, mp_id, vote)
) DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Ministerial offices
create table pw_moffice (
    moffice_id int not null primary key auto_increment,

    dept varchar(100) not null,
    position varchar(100) not null,
    responsibility varchar(100) not null,

    -- these are inclusive, the person became a minister at some time
    -- on the start date, and finished on the end date
    from_date date not null default '1000-01-01',
    to_date date not null default '9999-12-31',

    person int,

    index(person)
) DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- True abstentions ("abstention") and ("spoiled") are innovations of
-- the Scottish Parliament.  There is only a single instance of a
-- spoiled vote, but I'm including this for them moment anyway.

-- Define a sort order for displaying votes
create table if not exists pw_vote_sortorder (
    vote enum("aye", "no", "both", "tellaye", "tellno", "abstention", "spoiled") not null,
    position int not null
) DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
insert into pw_vote_sortorder(vote, position) values('aye', 10);
insert into pw_vote_sortorder(vote, position) values('no', 5);
insert into pw_vote_sortorder(vote, position) values('both', 1);
insert into pw_vote_sortorder(vote, position) values('tellaye', 10);
insert into pw_vote_sortorder(vote, position) values('tellno', 5);
insert into pw_vote_sortorder(vote, position) values('abstention', -5);
insert into pw_vote_sortorder(vote, position) values('spoiled', -10);

create table pw_candidate (
    candidate_id int not null primary key, -- allocated by Public Whip

    first_name varchar(100) not null, -- Lords: "$lordname" or empty string for "The" lords
    last_name varchar(100) not null, -- Lords: "of $lordofname"

    constituency varchar(100) not null, -- Lords: NOT USED
    party varchar(100) not null, -- Lords: affiliation
    house enum('commons', 'lords') not null,

    became_candidate date not null default '1000-01-01',
    left_candidate date not null default '9999-12-31',

    url text not null,

    index(house),
    index(party),
    index(became_candidate),
    index(left_candidate),
    index(constituency),
    unique(first_name, last_name, constituency, became_candidate, left_candidate)
) DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


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
  confirm_return_url text,
  is_confirmed int(11) NOT NULL default '0',
  reg_date datetime default NULL,
  active_policy_id int,
  PRIMARY KEY  (user_id)
) TYPE=MyISAM;

-- subscriptions of email addresses to the newsletter
create table pw_dyn_newsletter (
  newsletter_id int not null primary key auto_increment,
  email varchar(255),
  token text not null,
  confirm tinyint,
  subscribed datetime,
  unique(email)
) DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- who each issue of newsletter has been sent to so far
create table pw_dyn_newsletters_sent (
    newsletter_id int not null,
    newsletter_name varchar(100) not null,

    unique(newsletter_id, newsletter_name)
) DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


create table pw_dyn_dreammp (
    dream_id int not null primary key auto_increment,
    name varchar(100) not null,
    user_id int not null,
    description blob not null,
    private tinyint not null, -- 0 public, 1 legacy dream mp, 2 public draft

    index(user_id),
    unique(dream_id, name, user_id)
) DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

create table pw_dyn_aggregate_dreammp (
	dream_id_agg int not null,
	dream_id_sel int not null,
    vote_strength enum("strong", "weak") not null,
	index(dream_id_agg),
	index(dream_id_sel),
    unique(dream_id_agg, dream_id_sel)
) DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

create table pw_dyn_dreamvote (
    division_date date not null,
    division_number int not null,
    house enum('commons', 'lords', 'scotland') not null,
    dream_id int not null,
    vote enum("aye", "no", "both", "aye3", "no3", "abstention", "spoiled") not null,

    index(division_date),
    index(division_number),
    index(dream_id),
    unique(division_date, division_number, house, dream_id)
) DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- changes people have been making are stored here for debugging
create table pw_dyn_auditlog (
    auditlog_id int not null primary key auto_increment,
    user_id int not null,
    event_date datetime,
    event text,
    remote_addr text
) DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- for wiki text objects.  this is a transaction table, we only
-- insert rows into it, so we can show history.  when reading
-- from it, use the most recent row for a given key.
create table pw_dyn_wiki_motion (
    wiki_id int not null primary key auto_increment,
    -- name/id of object this is an edit of 
    division_date date not null,
    division_number int not null,
    house enum('commons', 'lords', 'scotland') not null,

    -- the new text that has change
    text_body text not null,

    -- who and when this changes was made
    user_id int not null, 
    edit_date datetime,

    index(division_date, division_number, house)
) DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-------------------------------------------------------------------------------
-- Cache tables
--   Those written to by the website itself during PHP requests are here.
--   There are also lots more cache tables made automatically by loader.pl,
--   which is run once a day.

-- information about one Dream MP
create table pw_cache_dreaminfo (
    dream_id int not null primary key,

    -- 0 - nothing is up to date
    -- 1 - calculation has been done
    cache_uptodate int NOT NULL,

    votes_count int not null,
    edited_motions_count int not null,
    consistency_with_mps float
) DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- information about a real MP for a particular Dream MP
-- e.g. Scores for how well they follow the Dream MP's whip.
create table pw_cache_dreamreal_distance (
    dream_id int not null,
    person int not null,

    -- number of votes same / different / MP absent
    nvotessame int,
    nvotessamestrong int,
    nvotesdiffer int,
    nvotesdifferstrong int,
    nvotesabsent int,
    nvotesabsentstrong int,

    distance_a float, -- use abstentions
    distance_b float, -- ignore abstentions

    index(dream_id),
    index(person),
    unique(dream_id, person)
) DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- distance metric between MPs
create table pw_cache_realreal_distance (
  mp_id1 int not null,
  mp_id2 int not null,

  -- number of votes same / different / MP absent
  nvotessame int,
  nvotesdiffer int,
  nvotesabsent int,

  distance_a float, -- use abstentions
  distance_b float, -- ignore absentions

  index(mp_id1),
  index(mp_id2),
  unique(mp_id1, mp_id2)
) DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- New table to store division comparisons
create table pw_cache_divdiv_distance (
  division_id int not null,
  division_id2 int not null,

  -- number MPs could vote in both
  nvotespossible smallint, 

  -- number of MPs who voted aye/aye or no/no
  nvotessame smallint,
  -- number of MPs who voted aye/no or no/aye
  nvotesdiff smallint,

  -- number of MPs who were absent for both votes
  nvotesabsent int,

  distance float, 

  index(division_id),
  index(division_id2),
  unique(division_id, division_id2)
) DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Stores the most recent wiki item for this division
create table pw_cache_divwiki (
    division_date date not null,
    division_number int not null,
    house enum('commons', 'lords', 'scotland') not null,
    wiki_id int not null,
    unique(division_date, division_number, house)
) DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

create table pw_logincoming (
    referrer varchar(120),
    ltime timestamp,
    ipnumber varchar(20),
    page varchar(20),
    subject varchar(60),
    url varchar(120),
    thing_id int,
    index(ltime),
    index(thing_id)
) DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-------------------------------------------------------------------------------
