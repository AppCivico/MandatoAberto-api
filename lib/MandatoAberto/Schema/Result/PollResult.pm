use utf8;
package MandatoAberto::Schema::Result::PollResult;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::PollResult

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

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::PassphraseColumn>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "PassphraseColumn");

=head1 TABLE: C<poll_results>

=cut

__PACKAGE__->table("poll_results");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'poll_results_id_seq'

=head2 citizen_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 option_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "poll_results_id_seq",
  },
  "citizen_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "option_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 citizen

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Citizen>

=cut

__PACKAGE__->belongs_to(
  "citizen",
  "MandatoAberto::Schema::Result::Citizen",
  { id => "citizen_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 option

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::QuestionOption>

=cut

__PACKAGE__->belongs_to(
  "option",
  "MandatoAberto::Schema::Result::QuestionOption",
  { id => "option_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2017-12-11 09:12:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0R8tsjvbLT2CYzfuglRdbg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
