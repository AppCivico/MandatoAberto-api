use utf8;
package MandatoAberto::Schema::Result::Answer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::Answer

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

=head1 TABLE: C<answer>

=cut

__PACKAGE__->table("answer");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'answers_id_seq'

=head2 question_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 content

  data_type: 'text'
  is_nullable: 0

=head2 politician_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 active

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "answers_id_seq",
  },
  "question_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "content",
  { data_type => "text", is_nullable => 0 },
  "politician_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "active",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 politician

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Politician>

=cut

__PACKAGE__->belongs_to(
  "politician",
  "MandatoAberto::Schema::Result::Politician",
  { user_id => "politician_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 question

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Question>

=cut

__PACKAGE__->belongs_to(
  "question",
  "MandatoAberto::Schema::Result::Question",
  { id => "question_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-10-08 18:55:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:R54HDAAyqUa8Haq51Q+3mA


# You can replace this text with custom code or comments, and it will be preserved on regeneration

with 'MandatoAberto::Role::Verification';
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

sub verifiers_specs {
    my $self = shift;

    return {
        update => Data::Verifier->new(
            filters => [ qw(trim) ],
            profile => {
                answer => {
                    required   => 0,
                    type       => 'Str',
                    max_lenght => 1000
                },
                active => {
                    required => 0,
                    type     => 'Bool'
                }
            },
        )
    };
}

sub action_specs {
    my ($self) = @_;

    return {
        update => sub {
            my $r = shift;

            my %values = $r->valid_values;
            not defined $values{$_} and delete $values{$_} for keys %values;

            return $self->update(\%values);
        }
    };
}

__PACKAGE__->meta->make_immutable;
1;