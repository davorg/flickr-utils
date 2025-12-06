# flickr-utils

Small collection of utilities to help migrate and normalise a Flickr archive
downloaded with [`flickrmirrorer`](https://github.com/justinlittman/flickrmirrorer),
store its metadata in SQLite, enrich the image files with EXIF/IPTC/XMP data,
and (optionally) upload to Google Photos.

The focus is:

* Keep a **canonical archive** on disk / NAS.
* Normalise all Flickr metadata into a **SQLite database**.
* Push as much of that metadata as possible back into the **image files**.
* Optionally use `rclone` or other tools as front-ends to cloud services.

> **Note:** The actual SQLite database (`db/flickr_db.sqlite`) is *not* included
> in this repository. 

---

## Repository layout

```text
bin/
  backup_album           # Shell helper for rclone → Google Photos (per-album)
  enrich_exif_from_db    # Main EXIF/IPTC/XMP enrichment script
  generate_classes       # Regenerate DBIx::Class schema from the DB
  import_album_structure # Import Albums/Collections into the DB
  insert_flickr_metadata # Import .metadata JSON into the DB

db/
  flickr_db.sqlite       # (Not committed) SQLite DB built from Flickr metadata

lib/
  App/
    FlickrExifEnricher.pm    # Core logic for enrich_exif_from_db
  Flickr/
    Schema.pm                # DBIx::Class::Schema
    Schema/Result/*.pm       # Result classes (Photo, Tag, Album, …)

sql/
  flickr_db.ddl          # Schema used to initialise the SQLite DB
```

---

## Requirements

* Perl 5.32+ (earlier may work, but this was written with “modern Perl” in mind)

* SQLite 3

* [ExifTool](https://exiftool.org/) (`exiftool` on your `PATH`)

* `flickrmirrorer` output tree (something like):

  ```text
  photostream/         # Original images + .metadata JSON from flickrmirrorer
  Albums/              # Per-album directories
  Collections/         # Collection directories (as created/renamed locally)
  ```

* Perl modules (install via your preferred CPAN client):

  * `DBIx::Class`
  * `DBIx::Class::Schema::Loader` (for `generate_classes`)
  * `JSON::MaybeXS`
  * `Path::Tiny`
  * `Getopt::Long`
  * `DateTime`
  * plus whatever `Flickr::Schema`/Result classes already depend on

---

## Typical workflow

The intended flow looks like this:

1. **Mirror Flickr with `flickrmirrorer`**

   Run `flickrmirrorer` against your account to create a local tree:

   ```text
   photostream/
     1234567890.jpg
     1234567890.jpg.metadata
     ...
   Albums/
   Collections/
   ```

2. **Create the SQLite database**

   From the repo root:

   ```bash
   sqlite3 db/flickr_db.sqlite < sql/flickr_db.ddl
   ```

3. **Populate the DB with photo metadata**

   Use `insert_flickr_metadata` to read the `.metadata` JSON files produced by
   `flickrmirrorer` and insert/update rows in the `photo`, `tag`,
   `machine_tag` and join tables.

   It is designed to operate on a single `.metadata` file at a time, so you
   typically run it via `find`/`xargs` or similar over `photostream/`.

4. **Import Albums and Collections**

   `import_album_structure` walks the `Albums/` and `Collections/` directories
   produced (or renamed) locally and populates the `album`, `collection`,
   and `album_photo` tables in the SQLite DB.

5. **Enrich EXIF/IPTC/XMP in the original files**

   Once the DB is populated, use `enrich_exif_from_db` to push metadata back
   into the image files under `photostream/` using ExifTool.

   For example:

   ```bash
   # Dry run: show what would be changed, but don’t write anything
   bin/enrich_exif_from_db --root ~/win/flickr --dry-run

   # Actually write all categories (date, location, description, tags, …)
   bin/enrich_exif_from_db --root ~/win/flickr
   ```

   See **`enrich_exif_from_db`** below for details.

6. **Optional: upload albums to Google Photos**

   The `backup_album` script is a small helper around `rclone` to upload a
   single album directory from `Albums/` to a matching album in Google Photos,
   and (on success) rename the local directory to append ` - Done`.

   This process is intentionally decoupled from the EXIF enrichment; the NAS /
   local copy is treated as canonical.

---

## Scripts

### `bin/enrich_exif_from_db`

Main script to enrich image files with metadata from the SQLite database.

It delegates most of its logic to `App::FlickrExifEnricher`, and is designed
to be:

* **Data-driven** – a category → DB fields → EXIF/IPTC/XMP mapping.
* **Selective** – you choose which “categories” to write.
* **Careful** – by default, only fills in fields that are currently missing;
  you can override that with `--force`.

**Key concepts**

* Root directory: expected to be the `flickrmirrorer` tree:

  ```text
  ROOT/
    photostream/
      1234567890.jpg
      ...
    Albums/
    Collections/
  ```

* Each row in the `photo` table corresponds to a file in
  `ROOT/photostream/$photo->file_name`.

**Options (summary)**

```text
--root DIR      Root of flickrmirrorer tree (default: .; expects photostream/)
--db PATH       Path to flickr_db.sqlite (otherwise uses $FLICKR_DB_PATH)
--dry-run       Show what would be changed; do not call exiftool
--force         Overwrite existing metadata for selected categories

# Category selectors (all enabled if none specified, or if --all is given)
--date          Write EXIF dates from date_taken
--location      Write GPS coordinates from latitude/longitude
--description   Write title/description into EXIF/IPTC/XMP caption fields
--tags          Write Flickr tags as IPTC Keywords / XMP Subject
--machine-tags  Write Flickr machine tags as extra Keywords / Subject
--author        Write author/creator fields from owner_name
--license       Write licence information from Flickr’s license code

--all           Enable all of the above categories

# Optional single-photo selection
--id ID         Process only the photo with this DB/Flickr id
--file NAME     Process only the photo with this file_name (e.g. 51427544778.jpg)
```

Without `--force`, each category will only be written for a file if **none of
its corresponding fields are currently set**. For example, `--location` will
skip any file that already has GPS coordinates, but `--license` will still be
written if the copyright fields are empty.

With `--force`, the chosen categories are always written from the database,
even if the file already has values.

---

### `bin/insert_flickr_metadata`

Imports a single `.metadata` JSON file produced by `flickrmirrorer` into the
SQLite database:

* Inserts/updates the `photo` row.
* Normalises tags and machine tags into `tag`, `machine_tag`,
  `photo_tag`, `photo_machine_tag`.

Typical usage is to run this over all `.metadata` files under
`photostream/` using `find`/`xargs`/GNU Parallel.

The script can optionally skip updates for photos that already exist, or
force an update when invoked with the relevant flag (see the script itself
for current options).

---

### `bin/import_album_structure`

Scans the `Albums/` and `Collections/` directories under the root and
populates the `album`, `collection`, and `album_photo` tables in the DB,
using the folder names as titles and the contained filenames to associate
photos to albums.

It is designed to be re-runnable as you rename or regroup album directories.

---

### `bin/generate_classes`

Helper script around `DBIx::Class::Schema::Loader` to regenerate the result
classes under `lib/Flickr/Schema/Result/` from the live SQLite schema.

Use this after you make schema changes (e.g. editing `sql/flickr_db.ddl` and
migrating the DB) to keep the DBIx::Class layer in sync.

---

### `bin/backup_album`

Small shell helper to upload a single album from `Albums/` to Google Photos
using `rclone` (with a pre-configured `gphotos:` remote), and on success,
rename the album directory to append ` - Done`.

This script is intentionally minimal and tailored to the author’s workflow;
treat it as an example rather than a polished general-purpose tool.

---

## Regenerating the DBIx::Class schema

If you change the database schema:

1. Update `sql/flickr_db.ddl` and apply migrations to your SQLite DB.

2. Regenerate the DBIx::Class classes:

   ```bash
   bin/generate_classes
   ```

3. Manually add any `many_to_many` helpers or custom methods (e.g. DateTime
   inflators) as needed – those are not generated automatically.

---

## Notes

* This project is opinionated and tailored to one particular migration
  (long-time Flickr user → local archive + Google Photos), but most of the
  pieces should be adaptable to other workflows.
* The SQLite schema is documented in `sql/flickr_db.ddl`; the generated
  DBIx::Class layer lives under `lib/Flickr/Schema/Result/`.
* Treat the NAS / local copy under `photostream/` as canonical; cloud
  services are best thought of as views or caches on top of that archive.

---

## Licence

This project is licensed under the MIT Licence. You’re free to use, copy,
modify, merge, publish, distribute, sublicense, and/or sell copies of the
software, subject to the usual MIT conditions.

See the [LICENSE](LICENSE) file for full details.

Copyright © 2025 Dave Cross.
