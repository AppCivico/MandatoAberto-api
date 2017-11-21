use utf8;

package MandatoAberto::Schema::Result::PoliticianGreeting;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::PoliticianGreeting

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

__PACKAGE__->load_components( "InflateColumn::DateTime", "TimeStamp", "PassphraseColumn" );

=head1 TABLE: C<politician_greeting>

=cut

__PACKAGE__->table("politician_greeting");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'politician_greetings_id_seq'

=head2 politician_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 text

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
    "id",
    {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
        sequence          => "politician_greetings_id_seq",
    },
    "politician_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "text",
    { data_type => "text", is_nullable => 0 },
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
    { user_id       => "politician_id" },
    { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

# Created by DBIx::Class::Schema::Loader v0.07047 @ 2017-11-16 16:27:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:36Ka73CU31nQmcU1RIjqoA

# You can replace this text with custom code or comments, and it will be preserved on regeneration

use Data::Verifier;

sub verifiers_specs {
    my $self = shift;

    return {
        update => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                politician_id => {
                    required => 1,
                    type     => "Int",
                },
                text => {
                    required   => 1,
                    type       => "Str",
                    max_length => 250,
                }
            }
        ),
    };
}

sub action_specs {
    my ($self) = @_;

    return {
        update => sub {
            my $r = shift;

            my %values = $r->valid_values;
            not defined $values{$_} and delete $values{$_} for keys %values;

            $self->update( \%values );
        }
    };
}

__PACKAGE__->meta->make_immutable;
1;
