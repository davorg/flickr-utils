use utf8;
package Flickr::Schema::Result::Photo;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Flickr::Schema::Result::Photo

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<photo>

=cut

__PACKAGE__->table("photo");

=head1 ACCESSORS

=head2 id

  data_type: 'text'
  is_nullable: 0

=head2 owner

  data_type: 'text'
  is_nullable: 0

=head2 secret

  data_type: 'text'
  is_nullable: 0

=head2 server

  data_type: 'text'
  is_nullable: 0

=head2 farm

  data_type: 'integer'
  is_nullable: 1

=head2 title

  data_type: 'text'
  is_nullable: 1

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 is_public

  data_type: 'integer'
  is_nullable: 0

=head2 is_friend

  data_type: 'integer'
  is_nullable: 0

=head2 is_family

  data_type: 'integer'
  is_nullable: 0

=head2 license

  data_type: 'text'
  is_nullable: 1

=head2 o_width

  data_type: 'integer'
  is_nullable: 1

=head2 o_height

  data_type: 'integer'
  is_nullable: 1

=head2 date_upload

  data_type: 'integer'
  is_nullable: 1

=head2 last_update

  data_type: 'integer'
  is_nullable: 1

=head2 date_taken

  data_type: 'text'
  datetime_timezone: 'UTC'
  inflate_datetime: 1
  is_nullable: 1

=head2 date_taken_granularity

  data_type: 'integer'
  is_nullable: 1

=head2 date_taken_unknown

  data_type: 'integer'
  is_nullable: 1

=head2 owner_name

  data_type: 'text'
  is_nullable: 1

=head2 icon_server

  data_type: 'text'
  is_nullable: 1

=head2 icon_farm

  data_type: 'integer'
  is_nullable: 1

=head2 views

  data_type: 'integer'
  is_nullable: 1

=head2 original_secret

  data_type: 'text'
  is_nullable: 1

=head2 original_format

  data_type: 'text'
  is_nullable: 1

=head2 latitude

  data_type: 'real'
  is_nullable: 1

=head2 longitude

  data_type: 'real'
  is_nullable: 1

=head2 accuracy

  data_type: 'integer'
  is_nullable: 1

=head2 context

  data_type: 'integer'
  is_nullable: 1

=head2 media

  data_type: 'text'
  is_nullable: 1

=head2 media_status

  data_type: 'text'
  is_nullable: 1

=head2 file_name

  data_type: 'text'
  is_nullable: 1

=head2 exif_datetime_original

  data_type: 'text'
  is_nullable: 1

=head2 exif_create_date

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "text", is_nullable => 0 },
  "owner",
  { data_type => "text", is_nullable => 0 },
  "secret",
  { data_type => "text", is_nullable => 0 },
  "server",
  { data_type => "text", is_nullable => 0 },
  "farm",
  { data_type => "integer", is_nullable => 1 },
  "title",
  { data_type => "text", is_nullable => 1 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "is_public",
  { data_type => "integer", is_nullable => 0 },
  "is_friend",
  { data_type => "integer", is_nullable => 0 },
  "is_family",
  { data_type => "integer", is_nullable => 0 },
  "license",
  { data_type => "text", is_nullable => 1 },
  "o_width",
  { data_type => "integer", is_nullable => 1 },
  "o_height",
  { data_type => "integer", is_nullable => 1 },
  "date_upload",
  { data_type => "integer", is_nullable => 1 },
  "last_update",
  { data_type => "integer", is_nullable => 1 },
  "date_taken",
  {
    data_type         => "text",
    datetime_timezone => "UTC",
    inflate_datetime  => 1,
    is_nullable       => 1,
  },
  "date_taken_granularity",
  { data_type => "integer", is_nullable => 1 },
  "date_taken_unknown",
  { data_type => "integer", is_nullable => 1 },
  "owner_name",
  { data_type => "text", is_nullable => 1 },
  "icon_server",
  { data_type => "text", is_nullable => 1 },
  "icon_farm",
  { data_type => "integer", is_nullable => 1 },
  "views",
  { data_type => "integer", is_nullable => 1 },
  "original_secret",
  { data_type => "text", is_nullable => 1 },
  "original_format",
  { data_type => "text", is_nullable => 1 },
  "latitude",
  { data_type => "real", is_nullable => 1 },
  "longitude",
  { data_type => "real", is_nullable => 1 },
  "accuracy",
  { data_type => "integer", is_nullable => 1 },
  "context",
  { data_type => "integer", is_nullable => 1 },
  "media",
  { data_type => "text", is_nullable => 1 },
  "media_status",
  { data_type => "text", is_nullable => 1 },
  "file_name",
  { data_type => "text", is_nullable => 1 },
  "exif_datetime_original",
  { data_type => "text", is_nullable => 1 },
  "exif_create_date",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 album_photos

Type: has_many

Related object: L<Flickr::Schema::Result::AlbumPhoto>

=cut

__PACKAGE__->has_many(
  "album_photos",
  "Flickr::Schema::Result::AlbumPhoto",
  { "foreign.photo_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 photo_machine_tags

Type: has_many

Related object: L<Flickr::Schema::Result::PhotoMachineTag>

=cut

__PACKAGE__->has_many(
  "photo_machine_tags",
  "Flickr::Schema::Result::PhotoMachineTag",
  { "foreign.photo_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 photo_tags

Type: has_many

Related object: L<Flickr::Schema::Result::PhotoTag>

=cut

__PACKAGE__->has_many(
  "photo_tags",
  "Flickr::Schema::Result::PhotoTag",
  { "foreign.photo_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 machine_tags

Type: many_to_many

Composing rels: L</photo_machine_tags> -> machine_tag

=cut

__PACKAGE__->many_to_many("machine_tags", "photo_machine_tags", "machine_tag");

=head2 tags

Type: many_to_many

Composing rels: L</photo_tags> -> tag

=cut

__PACKAGE__->many_to_many("tags", "photo_tags", "tag");


# Created by DBIx::Class::Schema::Loader v0.07053 @ 2025-12-04 17:02:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CaWqSpelGazqCv26F+dAPg

# Photo <-> Album (via album_photo)
__PACKAGE__->many_to_many(
  albums => 'album_photos', 'album'
);

use DateTime;

sub date_upload_dt { shift->epoch_to_datetime('date_upload') }
sub last_update_dt { shift->epoch_to_datetime('last_update') }

sub epoch_to_datetime {
  my $self  = shift;
  my ($column, $tz) = @_;
  $tz //= 'UTC';

  my $epoch = $self->$column;

  return unless defined $epoch && $epoch =~ /^\d+$/ && $epoch > 0;

  return DateTime->from_epoch(
    epoch     => $epoch,
    time_zone => $tz,
  );
}


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
