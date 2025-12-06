use utf8;
package Flickr::Schema::Result::AlbumPhoto;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Flickr::Schema::Result::AlbumPhoto

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

=head1 TABLE: C<album_photo>

=cut

__PACKAGE__->table("album_photo");

=head1 ACCESSORS

=head2 album_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 photo_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 position

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "album_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "photo_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "position",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</album_id>

=item * L</photo_id>

=back

=cut

__PACKAGE__->set_primary_key("album_id", "photo_id");

=head1 RELATIONS

=head2 album

Type: belongs_to

Related object: L<Flickr::Schema::Result::Album>

=cut

__PACKAGE__->belongs_to(
  "album",
  "Flickr::Schema::Result::Album",
  { id => "album_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 photo

Type: belongs_to

Related object: L<Flickr::Schema::Result::Photo>

=cut

__PACKAGE__->belongs_to(
  "photo",
  "Flickr::Schema::Result::Photo",
  { id => "photo_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07053 @ 2025-12-04 16:10:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:u5UZkiMH5tAxe7TqkUh2gw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
