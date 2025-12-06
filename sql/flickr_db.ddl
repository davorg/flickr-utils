-- flickr.db schema

PRAGMA foreign_keys = ON;

CREATE TABLE photo (
  id                     TEXT PRIMARY KEY,   -- Flickr photo ID
  owner                  TEXT NOT NULL,      -- NSID, e.g. 39021241@N00
  secret                 TEXT NOT NULL,
  server                 TEXT NOT NULL,
  farm                   INTEGER,

  title                  TEXT,
  description            TEXT,

  is_public              INTEGER NOT NULL,   -- 0/1
  is_friend              INTEGER NOT NULL,   -- 0/1
  is_family              INTEGER NOT NULL,   -- 0/1

  license                TEXT,               -- Flickr licence code as string

  o_width                INTEGER,
  o_height               INTEGER,

  date_upload            INTEGER,            -- Unix epoch (from dateupload)
  last_update            INTEGER,            -- Unix epoch (from lastupdate)
  date_taken             TEXT,               -- 'YYYY-MM-DD HH:MM:SS'
  date_taken_granularity INTEGER,
  date_taken_unknown     INTEGER,

  owner_name             TEXT,
  icon_server            TEXT,
  icon_farm              INTEGER,

  views                  INTEGER,

  original_secret        TEXT,
  original_format        TEXT,               -- 'jpg', 'png', ...

  latitude               REAL,
  longitude              REAL,
  accuracy               INTEGER,
  context                INTEGER,

  media                  TEXT,               -- 'photo', 'video'
  media_status           TEXT,               -- 'ready', etc.

  file_name              TEXT                -- e.g. '16752213265.jpg'
);

CREATE TABLE tag (
  id   INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE
);

CREATE TABLE photo_tag (
  photo_id TEXT NOT NULL,
  tag_id   INTEGER NOT NULL,
  PRIMARY KEY (photo_id, tag_id),
  FOREIGN KEY (photo_id) REFERENCES photo(id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id)   REFERENCES tag(id)   ON DELETE CASCADE
);

CREATE TABLE machine_tag (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  raw        TEXT NOT NULL UNIQUE,  -- full 'ns:pred=value'
  namespace  TEXT,
  predicate  TEXT,
  value      TEXT
);

CREATE TABLE photo_machine_tag (
  photo_id       TEXT NOT NULL,
  machine_tag_id INTEGER NOT NULL,
  PRIMARY KEY (photo_id, machine_tag_id),
  FOREIGN KEY (photo_id)       REFERENCES photo(id)       ON DELETE CASCADE,
  FOREIGN KEY (machine_tag_id) REFERENCES machine_tag(id) ON DELETE CASCADE
);

CREATE INDEX idx_photo_date_taken   ON photo(date_taken);
CREATE INDEX idx_photo_date_upload  ON photo(date_upload);
CREATE INDEX idx_photo_owner        ON photo(owner);
CREATE INDEX idx_photo_lat_lon      ON photo(latitude, longitude);
CREATE INDEX idx_tag_name           ON tag(name);

