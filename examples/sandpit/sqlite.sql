-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Sat Jun 11 00:39:51 2011
-- 

CREATE TABLE punctuated_column_name (
    id INTEGER PRIMARY KEY NOT NULL,
    "foo ' bar" INTEGER,
    'bar/baz' INTEGER,
    'baz;quux' INTEGER
);

CREATE INDEX punctuated_column_name_id ON punctuated_column_name (id);

INSERT INTO punctuated_column_name ("foo ' bar", 'bar/baz', 'baz;quux') VALUES (1,2,3);

INSERT INTO punctuated_column_name ("foo ' bar", 'bar/baz', 'baz;quux') VALUES (4,5,6);

--
-- Table: images
--
CREATE TABLE images (
  id INTEGER PRIMARY KEY NOT NULL,
  artwork_id integer NOT NULL,
  name varchar(100) NOT NULL,
  data blob
);

CREATE INDEX images_idx_artwork_id ON images (artwork_id);

--
-- Table: artist
--
CREATE TABLE artist (
  artistid INTEGER PRIMARY KEY NOT NULL,
  name varchar(100),
  rank integer NOT NULL DEFAULT 13,
  charfield char(10)
);

CREATE INDEX artist_name_hookidx ON artist (name);

CREATE UNIQUE INDEX artist_name ON artist (name);

CREATE UNIQUE INDEX u_nullable ON artist (charfield, rank);

INSERT INTO artist (artistid, name) VALUES (1, 'Caterwauler McCrae');

INSERT INTO artist (artistid, name) VALUES (2, 'Random Boy Band');

INSERT INTO artist (artistid, name) VALUES (3, 'We Are Goth');

--
-- Table: bindtype_test
--
CREATE TABLE bindtype_test (
  id INTEGER PRIMARY KEY NOT NULL,
  bytea blob,
  blob blob,
  clob clob,
  a_memo memo
);

INSERT INTO bindtype_test (bytea, blob, clob, a_memo) VALUES ('a','b','c','d');

--
-- Table: collection
--
CREATE TABLE collection (
  collectionid INTEGER PRIMARY KEY NOT NULL,
  name varchar(100) NOT NULL
);

INSERT INTO collection (name) VALUES ('orange');

INSERT INTO collection (name) VALUES ('black');

--
-- Table: encoded
--
CREATE TABLE encoded (
  id INTEGER PRIMARY KEY NOT NULL,
  encoded varchar(100)
);

INSERT INTO encoded (encoded) VALUES ('ANOTHER SECRET');

INSERT INTO encoded (encoded) VALUES ('I am SECRET');

--
-- Table: event
--
CREATE TABLE event (
  id INTEGER PRIMARY KEY NOT NULL,
  starts_at date NOT NULL,
  created_on timestamp NOT NULL,
  varchar_date varchar(20),
  varchar_datetime varchar(20),
  skip_inflation datetime,
  ts_without_tz datetime
);

INSERT INTO event (starts_at,created_on) VALUES ('1980-07-21','1980-07-21');

--
-- Table: fourkeys
--
CREATE TABLE fourkeys (
  foo integer NOT NULL,
  bar integer NOT NULL,
  hello integer NOT NULL,
  goodbye integer NOT NULL,
  sensors character(10) NOT NULL,
  read_count int,
  PRIMARY KEY (foo, bar, hello, goodbye)
);

INSERT INTO fourkeys (foo, bar, hello, goodbye, sensors) VALUES (1, 2, 3, 4, 4);

INSERT INTO fourkeys (foo, bar, hello, goodbye, sensors) VALUES (5, 4, 3, 6, 4);

--
-- Table: genre
--
CREATE TABLE genre (
  genreid INTEGER PRIMARY KEY NOT NULL,
  name varchar(100) NOT NULL
);

CREATE UNIQUE INDEX genre_name ON genre (name);

INSERT INTO genre (name) VALUES ('pop');

INSERT INTO genre (name) VALUES ('rock');

INSERT INTO genre (name) VALUES ('blues');

--
-- Table: link
--
CREATE TABLE link (
  id INTEGER PRIMARY KEY NOT NULL,
  url varchar(100),
  title varchar(100)
);

INSERT INTO link (url,title) VALUES ('http://www.perl.org/','Perl');

INSERT INTO link (url,title) VALUES ('http://www.google.com/','The Chocolate Factory');

INSERT INTO link (url,title) VALUES ('http://www.amazon.com/','Amazon');

--
-- Table: money_test
--
CREATE TABLE money_test (
  id INTEGER PRIMARY KEY NOT NULL,
  amount money
);

INSERT INTO money_test (amount) VALUES ('1.23');

INSERT INTO money_test (amount) VALUES ('4.56');

--
-- Table: noprimarykey
--
CREATE TABLE noprimarykey (
  foo integer NOT NULL,
  bar integer NOT NULL,
  baz integer NOT NULL
);

CREATE UNIQUE INDEX foo_bar ON noprimarykey (foo, bar);

INSERT INTO noprimarykey (foo,bar,baz) VALUES (1,2,3);

INSERT INTO noprimarykey (foo,bar,baz) VALUES (4,5,6);

INSERT INTO noprimarykey (foo,bar,baz) VALUES (2,3,4);

--
-- Table: onekey
--
CREATE TABLE onekey (
  id INTEGER PRIMARY KEY NOT NULL,
  artist integer NOT NULL,
  cd integer NOT NULL
);

INSERT INTO onekey (id, artist, cd) VALUES (1, 1, 1);

INSERT INTO onekey (id, artist, cd) VALUES (2, 1, 2);

INSERT INTO onekey (id, artist, cd) VALUES (3, 2, 2);

--
-- Table: owners
--
CREATE TABLE owners (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(100) NOT NULL
);

INSERT INTO owners (name) VALUES ('bob');

INSERT INTO owners (name) VALUES ('kitty');

INSERT INTO owners (name) VALUES ('cheryl');

--
-- Table: producer
--
CREATE TABLE producer (
  producerid INTEGER PRIMARY KEY NOT NULL,
  name varchar(100) NOT NULL
);

CREATE UNIQUE INDEX prod_name ON producer (name);

INSERT INTO producer (name) VALUES ('billy');

INSERT INTO producer (name) VALUES ('roger');

INSERT INTO producer (name) VALUES ('amanda');

--
-- Table: self_ref
--
CREATE TABLE self_ref (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(100) NOT NULL
);

INSERT INTO self_ref (name) VALUES ('harry');

INSERT INTO self_ref (name) VALUES ('bob');

INSERT INTO self_ref (name) VALUES ('jim');

--
-- Table: serialized
--
CREATE TABLE serialized (
  id INTEGER PRIMARY KEY NOT NULL,
  serialized text NOT NULL
);

INSERT INTO serialized (serialized) VALUES ('xxxyyy');

INSERT INTO serialized (serialized) VALUES ('aaabbb');

--
-- Table: artist_undirected_map
--
CREATE TABLE artist_undirected_map (
  id1 integer NOT NULL,
  id2 integer NOT NULL,
  PRIMARY KEY (id1, id2)
);

CREATE INDEX artist_undirected_map_idx_id1 ON artist_undirected_map (id1);

CREATE INDEX artist_undirected_map_idx_id2 ON artist_undirected_map (id2);

INSERT INTO artist_undirected_map (id1,id2) VALUES (1,2);

INSERT INTO artist_undirected_map (id1,id2) VALUES (2,3);

--
-- Table: bookmark
--
CREATE TABLE bookmark (
  id INTEGER PRIMARY KEY NOT NULL,
  link integer
);

CREATE INDEX bookmark_idx_link ON bookmark (link);

INSERT INTO bookmark (link) VALUES (1);

--
-- Table: books
--
CREATE TABLE books (
  id INTEGER PRIMARY KEY NOT NULL,
  source varchar(100) NOT NULL,
  owner integer NOT NULL,
  title varchar(100) NOT NULL,
  price integer
);

CREATE INDEX books_idx_owner ON books (owner);

CREATE UNIQUE INDEX books_title ON books (title);

INSERT INTO books (source,owner,title,price) VALUES ('secret',1,'something secret','1.99');

INSERT INTO books (source,owner,title,price) VALUES ('hot',1,'something hot','2.99');

--
-- Table: employee
--
CREATE TABLE employee (
  employee_id INTEGER PRIMARY KEY NOT NULL,
  position integer NOT NULL,
  group_id integer,
  group_id_2 integer,
  group_id_3 integer,
  name varchar(100),
  encoded integer
);

CREATE INDEX employee_idx_encoded ON employee (encoded);

INSERT INTO employee (position,group_id,group_id_2,group_id_3,name,encoded) VALUES (1,1,1,1,'billy',1);

INSERT INTO employee (position,group_id,group_id_2,group_id_3,name,encoded) VALUES (1,1,1,1,'roger',1);

--
-- Table: forceforeign
--
CREATE TABLE forceforeign (
  artist INTEGER PRIMARY KEY NOT NULL,
  cd integer NOT NULL
);

INSERT INTO forceforeign (cd) VALUES (1);

INSERT INTO forceforeign (cd) VALUES (2);

--
-- Table: self_ref_alias
--
CREATE TABLE self_ref_alias (
  self_ref integer NOT NULL,
  alias integer NOT NULL,
  PRIMARY KEY (self_ref, alias)
);

CREATE INDEX self_ref_alias_idx_alias ON self_ref_alias (alias);

CREATE INDEX self_ref_alias_idx_self_ref ON self_ref_alias (self_ref);

INSERT INTO self_ref_alias (self_ref,alias) VALUES (1,2);

INSERT INTO self_ref_alias (self_ref,alias) VALUES (2,1);

--
-- Table: track
--
CREATE TABLE track (
  trackid INTEGER PRIMARY KEY NOT NULL,
  cd integer NOT NULL,
  position int NOT NULL,
  title varchar(100) NOT NULL,
  last_updated_on datetime,
  last_updated_at datetime
);

CREATE INDEX track_idx_cd ON track (cd);

CREATE UNIQUE INDEX track_cd_position ON track (cd, position);

CREATE UNIQUE INDEX track_cd_title ON track (cd, title);

INSERT INTO track (cd,position,title) VALUES (1,1,'track one');

INSERT INTO track (cd,position,title) VALUES (1,2,'track two');

--
-- Table: cd
--
CREATE TABLE cd (
  cdid INTEGER PRIMARY KEY NOT NULL,
  artist integer NOT NULL,
  title varchar(100) NOT NULL,
  year varchar(100) NOT NULL,
  genreid integer,
  single_track integer
);

CREATE INDEX cd_idx_artist ON cd (artist);

CREATE INDEX cd_idx_genreid ON cd (genreid);

CREATE INDEX cd_idx_single_track ON cd (single_track);

CREATE UNIQUE INDEX cd_artist_title ON cd (artist, title);

INSERT INTO cd (cdid, artist, title, year)
    VALUES (1, 1, "Spoonful of bees", 1999);

INSERT INTO cd (cdid, artist, title, year)
    VALUES (2, 1, "Forkful of bees", 2001);

INSERT INTO cd (cdid, artist, title, year)
    VALUES (3, 1, "Caterwaulin' Blues", 1997);

INSERT INTO cd (cdid, artist, title, year)
    VALUES (4, 2, "Generic Manufactured Singles", 2001);

INSERT INTO cd (cdid, artist, title, year)
    VALUES (5, 3, "Come Be Depressed With Us", 1998);

--
-- Table: collection_object
--
CREATE TABLE collection_object (
  collection integer NOT NULL,
  object integer NOT NULL,
  PRIMARY KEY (collection, object)
);

CREATE INDEX collection_object_idx_collection ON collection_object (collection);

CREATE INDEX collection_object_idx_object ON collection_object (object);

INSERT INTO collection_object (collection, object) VALUES (1,1);

--
-- Table: lyrics
--
CREATE TABLE lyrics (
  lyric_id INTEGER PRIMARY KEY NOT NULL,
  track_id integer NOT NULL
);

CREATE INDEX lyrics_idx_track_id ON lyrics (track_id);

INSERT INTO lyrics (track_id) VALUES (1);

INSERT INTO lyrics (track_id) VALUES (2);

--
-- Table: cd_artwork
--
CREATE TABLE cd_artwork (
  cd_id INTEGER PRIMARY KEY NOT NULL
);

INSERT INTO cd_artwork (cd_id) VALUES (1);

INSERT INTO cd_artwork (cd_id) VALUES (2);

--
-- Table: liner_notes
--
CREATE TABLE liner_notes (
  liner_id INTEGER PRIMARY KEY NOT NULL,
  notes varchar(100) NOT NULL
);

INSERT INTO liner_notes (liner_id, notes)
    VALUES (2, "Buy Whiskey!");

INSERT INTO liner_notes (liner_id, notes)
    VALUES (4, "Buy Merch!");

INSERT INTO liner_notes (liner_id, notes)
    VALUES (5, "Kill Yourself!");

--
-- Table: lyric_versions
--
CREATE TABLE lyric_versions (
  id INTEGER PRIMARY KEY NOT NULL,
  lyric_id integer NOT NULL,
  text varchar(100) NOT NULL
);

CREATE INDEX lyric_versions_idx_lyric_id ON lyric_versions (lyric_id);

INSERT INTO lyric_versions (lyric_id,text) VALUES (1,'some words');

INSERT INTO lyric_versions (lyric_id,text) VALUES (2,'for a while');

--
-- Table: tags
--
CREATE TABLE tags (
  tagid INTEGER PRIMARY KEY NOT NULL,
  cd integer NOT NULL,
  tag varchar(100) NOT NULL
);

CREATE INDEX tags_idx_cd ON tags (cd);

CREATE UNIQUE INDEX tagid_cd ON tags (tagid, cd);

CREATE UNIQUE INDEX tagid_cd_tag ON tags (tagid, cd, tag);

CREATE UNIQUE INDEX tags_tagid_tag ON tags (tagid, tag);

CREATE UNIQUE INDEX tags_tagid_tag_cd ON tags (tagid, tag, cd);

INSERT INTO tags (tagid, cd, tag) VALUES (1, 1, "Blue");

INSERT INTO tags (tagid, cd, tag) VALUES (2, 2, "Blue");

INSERT INTO tags (tagid, cd, tag) VALUES (3, 3, "Blue");

INSERT INTO tags (tagid, cd, tag) VALUES (4, 5, "Blue");

INSERT INTO tags (tagid, cd, tag) VALUES (5, 2, "Cheesy");

INSERT INTO tags (tagid, cd, tag) VALUES (6, 4, "Cheesy");

INSERT INTO tags (tagid, cd, tag) VALUES (7, 5, "Cheesy");

INSERT INTO tags (tagid, cd, tag) VALUES (8, 2, "Shiny");

INSERT INTO tags (tagid, cd, tag) VALUES (9, 4, "Shiny");

--
-- Table: cd_to_producer
--
CREATE TABLE cd_to_producer (
  cd integer NOT NULL,
  producer integer NOT NULL,
  attribute integer,
  PRIMARY KEY (cd, producer)
);

CREATE INDEX cd_to_producer_idx_cd ON cd_to_producer (cd);

CREATE INDEX cd_to_producer_idx_producer ON cd_to_producer (producer);

INSERT INTO cd_to_producer (cd,producer,attribute) VALUES (1,1,1);

--
-- Table: twokeys
--
CREATE TABLE twokeys (
  artist integer NOT NULL,
  cd integer NOT NULL,
  PRIMARY KEY (artist, cd)
);

CREATE INDEX twokeys_idx_artist ON twokeys (artist);

INSERT INTO twokeys (artist, cd) VALUES (1, 1);

INSERT INTO twokeys (artist, cd) VALUES (1, 2);

INSERT INTO twokeys (artist, cd) VALUES (2, 2);

--
-- Table: artwork_to_artist
--
CREATE TABLE artwork_to_artist (
  artwork_cd_id integer NOT NULL,
  artist_id integer NOT NULL,
  PRIMARY KEY (artwork_cd_id, artist_id)
);

CREATE INDEX artwork_to_artist_idx_artist_id ON artwork_to_artist (artist_id);

CREATE INDEX artwork_to_artist_idx_artwork_cd_id ON artwork_to_artist (artwork_cd_id);

INSERT INTO artwork_to_artist (artwork_cd_id,artist_id) VALUES (1,1);

--
-- Table: fourkeys_to_twokeys
--
CREATE TABLE fourkeys_to_twokeys (
  f_foo integer NOT NULL,
  f_bar integer NOT NULL,
  f_hello integer NOT NULL,
  f_goodbye integer NOT NULL,
  t_artist integer NOT NULL,
  t_cd integer NOT NULL,
  autopilot character NOT NULL,
  pilot_sequence integer,
  PRIMARY KEY (f_foo, f_bar, f_hello, f_goodbye, t_artist, t_cd)
);

CREATE INDEX fourkeys_to_twokeys_idx_f_foo_f_bar_f_hello_f_goodbye ON fourkeys_to_twokeys (f_foo, f_bar, f_hello, f_goodbye);

CREATE INDEX fourkeys_to_twokeys_idx_t_artist_t_cd ON fourkeys_to_twokeys (t_artist, t_cd);

INSERT INTO fourkeys_to_twokeys (f_foo, f_bar, f_hello, f_goodbye, t_artist, t_cd, autopilot) VALUES (1, 2, 3, 4, 1, 2, 'x');

INSERT INTO fourkeys_to_twokeys (f_foo, f_bar, f_hello, f_goodbye, t_artist, t_cd, autopilot) VALUES (5, 4, 3, 6, 2, 1, 'y');

--
-- View: year2000cds
--
CREATE VIEW year2000cds AS
    SELECT cdid, artist, title, year, genreid, single_track FROM cd WHERE year = "2000";
