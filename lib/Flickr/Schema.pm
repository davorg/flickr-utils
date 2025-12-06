use utf8;
package Flickr::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces(
    resultset_namespace => "ResultSet",
);


# Created by DBIx::Class::Schema::Loader v0.07053 @ 2025-12-03 15:41:03
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HAt4dr4q7FP+43VVDFWmgg

sub get_schema {
  my $class = shift;
  my ($db)  = @_;

  $db //= $ENV{FLICKR_DB_PATH};

  die "No database given\n" unless defined $db;

  return $class->connect(
    "dbi:SQLite:dbname=$db",
    '', '',
    {
      sqlite_unicode  => 1,
      on_connect_call => 'use_foreign_keys',
    },
  );
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
