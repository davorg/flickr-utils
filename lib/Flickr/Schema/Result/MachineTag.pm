use utf8;
package Flickr::Schema::Result::MachineTag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Flickr::Schema::Result::MachineTag

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

=head1 TABLE: C<machine_tag>

=cut

__PACKAGE__->table("machine_tag");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 raw

  data_type: 'text'
  is_nullable: 0

=head2 namespace

  data_type: 'text'
  is_nullable: 1

=head2 predicate

  data_type: 'text'
  is_nullable: 1

=head2 value

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "raw",
  { data_type => "text", is_nullable => 0 },
  "namespace",
  { data_type => "text", is_nullable => 1 },
  "predicate",
  { data_type => "text", is_nullable => 1 },
  "value",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<raw_unique>

=over 4

=item * L</raw>

=back

=cut

__PACKAGE__->add_unique_constraint("raw_unique", ["raw"]);

=head1 RELATIONS

=head2 photo_machine_tags

Type: has_many

Related object: L<Flickr::Schema::Result::PhotoMachineTag>

=cut

__PACKAGE__->has_many(
  "photo_machine_tags",
  "Flickr::Schema::Result::PhotoMachineTag",
  { "foreign.machine_tag_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 photos

Type: many_to_many

Composing rels: L</photo_machine_tags> -> photo

=cut

__PACKAGE__->many_to_many("photos", "photo_machine_tags", "photo");


# Created by DBIx::Class::Schema::Loader v0.07053 @ 2025-12-03 15:25:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:A+vhRfTBE7uM0xIVcph4OQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
