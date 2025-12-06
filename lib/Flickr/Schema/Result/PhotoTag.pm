use utf8;
package Flickr::Schema::Result::PhotoTag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Flickr::Schema::Result::PhotoTag

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

=head1 TABLE: C<photo_tag>

=cut

__PACKAGE__->table("photo_tag");

=head1 ACCESSORS

=head2 photo_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 tag_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "photo_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "tag_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</photo_id>

=item * L</tag_id>

=back

=cut

__PACKAGE__->set_primary_key("photo_id", "tag_id");

=head1 RELATIONS

=head2 photo

Type: belongs_to

Related object: L<Flickr::Schema::Result::Photo>

=cut

__PACKAGE__->belongs_to(
  "photo",
  "Flickr::Schema::Result::Photo",
  { id => "photo_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 tag

Type: belongs_to

Related object: L<Flickr::Schema::Result::Tag>

=cut

__PACKAGE__->belongs_to(
  "tag",
  "Flickr::Schema::Result::Tag",
  { id => "tag_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07053 @ 2025-12-03 15:25:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YBTJA2FouxngnZzmBQ+Idg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
