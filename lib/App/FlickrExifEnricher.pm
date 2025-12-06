package App::FlickrExifEnricher;
use strict;
use warnings;
use feature qw[say state];

use Path::Tiny qw(path);
use JSON::MaybeXS;
use IPC::Open3;
use Symbol qw(gensym);

use Flickr::Schema;

sub new {
  my ($class, %args) = @_;

  my $self = bless {
    root      => $args{root}      // '.',
    db_path   => $args{db_path},
    dry_run   => $args{dry_run}   // 0,
    force     => $args{force}     // 0,
    categories => $args{categories} // {},
    where     => $args{where},
  }, $class;

  my $rootdir = path($self->{root})->absolute;
  $self->{rootdir}     = $rootdir;
  $self->{photostream} = $rootdir->child('photostream');

  $self->{schema} = Flickr::Schema->get_schema($self->{db_path});

  return $self;
}

# -------- category spec ---------------------------------------------------

my %CATEGORY_SPEC = (
  date => {
    inspect_tags => [ qw(
      EXIF:DateTimeOriginal
      EXIF:CreateDate
    ) ],
    builder => \&_build_date_tags,
  },

  location => {
    inspect_tags => [ qw(
      EXIF:GPSLatitude
      EXIF:GPSLongitude
    ) ],
    builder => \&_build_location_tags,
  },

  description => {
    inspect_tags => [ qw(
      EXIF:ImageDescription
      IPTC:Caption-Abstract
      XMP-dc:Description
      XMP-dc:Title
      EXIF:XPTitle
    ) ],
    builder => \&_build_description_tags,
  },

  tags => {
    inspect_tags => [ qw(
      IPTC:Keywords
      XMP-dc:Subject
    ) ],
    builder => \&_build_tags_tags,
  },

  'machine-tags' => {
    inspect_tags => [ qw(
      IPTC:Keywords
      XMP-dc:Subject
    ) ],
    builder => \&_build_machine_tags_tags,
  },

  author => {
    inspect_tags => [ qw(
      EXIF:Artist
      IPTC:By-line
      XMP-dc:Creator
    ) ],
    builder => \&_build_author_tags,
  },

  license => {
    inspect_tags => [ qw(
      EXIF:Copyright
      IPTC:CopyrightNotice
      XMP-dc:Rights
    ) ],
    builder => \&_build_license_tags,
  },
);

# -------- public API ------------------------------------------------------

sub run {
  my ($self) = @_;

  my $schema      = $self->{schema};
  my $photostream = $self->{photostream};
  my $dry_run     = $self->{dry_run};

  my $enabled = $self->_effective_categories;

  unless (%$enabled) {
    say "No categories enabled; nothing to do.";
    return;
  }

  my $where = $self->{where} // {};

  my $rs = $schema->resultset('Photo')->search($where);

  my $updated = 0;

  while (my $photo = $rs->next) {
    my $file = $photostream->child($photo->file_name);
    next unless $file->exists;

    my $file_path = $file->stringify;

    # Determine which categories actually need applying for this file
    my $exif_existing = $self->{force}
      ? {}
      : $self->_read_existing_tags($file_path, $enabled);

    my %tags_to_set;

    CATEGORY:
    for my $cat (sort keys %$enabled) {
      my $spec = $CATEGORY_SPEC{$cat} or next;

      # If not forcing and existing metadata for this category is present, skip
      unless ($self->{force}) {
        my $present = $self->_category_present($cat, $exif_existing);
        next CATEGORY if $present;
      }

      my $builder = $spec->{builder} or next;
      my $new_tags = $builder->($photo);

      # builder may decide "nothing to add" (undef or empty hashref)
      next CATEGORY unless $new_tags && %$new_tags;

      @tags_to_set{ keys %$new_tags } = values %$new_tags;
    }

    next unless %tags_to_set;  # nothing to do for this photo

    $self->_apply_tags($file_path, \%tags_to_set);
    $updated++;
  }

  say $dry_run
    ? "Dry run complete."
    : "Updated metadata on $updated photos.";
}

# -------- category helpers ------------------------------------------------

sub _effective_categories {
  my ($self) = @_;

  my %enabled = %{ $self->{categories} || {} };

  # If nothing explicitly enabled, treat as --all
  unless (%enabled) {
    %enabled = map { $_ => 1 } keys %CATEGORY_SPEC;
  }

  # Filter to known categories only
  my %effective;
  for my $cat (keys %enabled) {
    next unless $enabled{$cat};
    next unless exists $CATEGORY_SPEC{$cat};
    $effective{$cat} = 1;
  }

  return \%effective;
}

sub _read_existing_tags {
  my ($self, $file_path, $enabled) = @_;

  my %all_tags;
  my @tag_list;

  # Collect union of inspect_tags for all enabled categories
  for my $cat (keys %$enabled) {
    my $spec = $CATEGORY_SPEC{$cat} or next;
    push @tag_list, @{ $spec->{inspect_tags} || [] };
  }

  # No tags to inspect => nothing to check
  return {} unless @tag_list;

  my @cmd = (
    'exiftool',
    '-json',
    (map { "-$_" } @tag_list),
    $file_path,
  );

  my ($json, $err, $exit) = _run_capture(@cmd);
  return {} if $exit != 0;

  my $data = eval { decode_json($json) } || [];
  my $first = $data->[0] || {};

  # exiftool returns tags without group names in JSON (e.g. "DateTimeOriginal")
  # So we normalise keys to bare tag names for presence checks.
  %all_tags = %$first;

  return \%all_tags;
}

sub _category_present {
  my ($self, $cat, $existing) = @_;

  my $spec = $CATEGORY_SPEC{$cat} or return 0;

  my @inspect = @{ $spec->{inspect_tags} || [] };
  return 0 unless @inspect;

  # Strip group name (EXIF:, IPTC:, etc.) when checking JSON keys
  my @bare = map { s/^[^:]+://r } @inspect;

  for my $tag (@bare) {
    next unless exists $existing->{$tag};
    my $val = $existing->{$tag};

    # treat undef/empty string/empty array as "not present"
    if (defined $val) {
      if (ref $val eq 'ARRAY') {
        return 1 if @$val;
      } elsif ($val ne '') {
        return 1;
      }
    }
  }

  return 0;
}

sub _apply_tags {
  my ($self, $file_path, $tags) = @_;

  my $dry_run = $self->{dry_run};

  my @args;
  for my $tag (sort keys %$tags) {
    my $val = $tags->{$tag};
    next unless defined $val;

    # exiftool wants "TAG=Value", with optional group, e.g. "EXIF:DateTimeOriginal=..."
    push @args, "-$tag=$val";
  }

  return unless @args;

  say +($dry_run ? "[DRY RUN] " : ""),
      "Updating $file_path with: ",
      join(", ", @args);

  return if $dry_run;

  my @cmd = (
    'exiftool',
    '-overwrite_original',
    @args,
    $file_path,
  );

  my ($out, $err, $exit) = _run_capture(@cmd);
  if ($exit != 0) {
    warn "exiftool failed for $file_path (exit $exit)\n$err\n";
  }
}

# -------- builder subs ----------------------------------------------------

sub _build_date_tags {
  my ($photo) = @_;

  my $dt = $photo->date_taken or return {};
  my $exif_dt = $dt->strftime('%Y:%m:%d %H:%M:%S');

  return {
    'EXIF:DateTimeOriginal' => $exif_dt,
    'EXIF:CreateDate'       => $exif_dt,
  };
}

sub _build_location_tags {
  my ($photo) = @_;

  my $lat = $photo->latitude;
  my $lon = $photo->longitude;

  return {} unless defined $lat && defined $lon;
  return {} if $lat == 0 && $lon == 0;

  my ($lat_ref, $lon_ref) = ($lat >= 0 ? 'N' : 'S', $lon >= 0 ? 'E' : 'W');

  # exiftool is happy with decimal degrees for GPSLatitude/Longitude
  return {
    'EXIF:GPSLatitude'     => abs($lat),
    'EXIF:GPSLatitudeRef'  => $lat_ref,
    'EXIF:GPSLongitude'    => abs($lon),
    'EXIF:GPSLongitudeRef' => $lon_ref,
  };
}

sub _build_description_tags {
  my ($photo) = @_;

  my $title = $photo->title       // '';
  my $desc  = $photo->description // '';

  $title =~ s/\s+\z// if $title;
  $desc  =~ s/\s+\z// if $desc;

  return {} unless length $title || length $desc;

  my %tags;

  if (length $title) {
    $tags{'XMP-dc:Title'} = $title;
    $tags{'EXIF:XPTitle'} = $title;
  }

  if (length $desc) {
    $tags{'EXIF:ImageDescription'}  = $desc;
    $tags{'IPTC:Caption-Abstract'}  = $desc;
    $tags{'XMP-dc:Description'}     = $desc;
  }

  return \%tags;
}

sub _build_tags_tags {
  my ($photo) = @_;

  my @tags = map { $_->name } $photo->tags;
  return {} unless @tags;

  my $joined = join(', ', @tags);

  return {
    'IPTC:Keywords'   => $joined,
    'XMP-dc:Subject'  => $joined,
  };
}

sub _build_machine_tags_tags {
  my ($photo) = @_;

  my @raw = map { $_->raw } $photo->machine_tags;
  return {} unless @raw;

  my $joined = join(', ', @raw);

  return {
    'IPTC:Keywords'   => $joined,
    'XMP-dc:Subject'  => $joined,
  };
}

sub _build_author_tags {
  my ($photo) = @_;

  my $author = $photo->owner_name // '';
  $author =~ s/\s+\z//;

  return {} unless length $author;

  return {
    'EXIF:Artist'    => $author,
    'IPTC:By-line'   => $author,
    'XMP-dc:Creator' => $author,
  };
}

sub _build_license_tags {
  my ($photo) = @_;

  state %FLICKR_LICENSE = (
    0 => {
      name => 'All Rights Reserved',
      url => undef
    },
    1 => {
      name => 'CC BY-NC-SA 2.0',
      url => 'https://creativecommons.org/licenses/by-nc-sa/2.0/'
    },
    2 => {
      name => 'CC BY-NC 2.0',
      url => 'https://creativecommons.org/licenses/by-nc/2.0/'
    },
    4 => {
      name => 'CC BY 2.0',
      url => 'https://creativecommons.org/licenses/by/2.0/'
    },
    5 => {
      name => 'CC BY-SA 2.0',
      url => 'https://creativecommons.org/licenses/by-sa/2.0/'
    },
    6 => {
      name => 'CC BY-ND 2.0',
      url => 'https://creativecommons.org/licenses/by-nd/2.0/'
    },
    9 => {
      name => 'CC0 1.0 (Public Domain Dedication)',
      url => 'https://creativecommons.org/publicdomain/zero/1.0/'
    },
  );

  my $code = $photo->license;
  return {} unless defined $code;

  my $lic = $FLICKR_LICENSE{$code}
         || { name => "Flickr license code $code", url => undef };

  my $name = $lic->{name};
  my $url  = $lic->{url};

  my %tags = (
    'EXIF:Copyright'        => $name,
    'IPTC:CopyrightNotice'  => $name,
    'XMP-dc:Rights'         => $url ? "$name – see $url" : $name,
  );

  # Optional but nice: explicit rights URL
  if ($url) {
    $tags{'XMP-xmpRights:WebStatement'} = $url;
  }

  return \%tags;
}

# -------- small helper: run a command and capture stdout/stderr -----------

sub _run_capture {
  my @cmd = @_;

  my $err_fh = gensym;
  my $pid = open3(undef, my $out_fh, $err_fh, @cmd);

  local $/;
  my $out = <$out_fh> // '';
  my $err = <$err_fh> // '';

  waitpid($pid, 0);
  my $exit = $? >> 8;

  return ($out, $err, $exit);
}

1;

