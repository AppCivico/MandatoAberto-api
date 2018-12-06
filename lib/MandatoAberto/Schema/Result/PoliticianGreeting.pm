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

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "PassphraseColumn");

=head1 TABLE: C<politician_greeting>

=cut

__PACKAGE__->table("politician_greeting");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'politician_greetings_id_seq'

=head2 greeting_id

  data_type: 'integer'
  default_value: 1
  is_foreign_key: 1
  is_nullable: 1

=head2 on_facebook

  data_type: 'text'
  is_nullable: 0

=head2 on_website

  data_type: 'text'
  is_nullable: 0

=head2 organization_chatbot_id

  data_type: 'integer'
  is_foreign_key: 1
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
  "greeting_id",
  {
    data_type      => "integer",
    default_value  => 1,
    is_foreign_key => 1,
    is_nullable    => 1,
  },
  "on_facebook",
  { data_type => "text", is_nullable => 0 },
  "on_website",
  { data_type => "text", is_nullable => 0 },
  "organization_chatbot_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 greeting

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Greeting>

=cut

__PACKAGE__->belongs_to(
  "greeting",
  "MandatoAberto::Schema::Result::Greeting",
  { id => "greeting_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 organization_chatbot

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::OrganizationChatbot>

=cut

__PACKAGE__->belongs_to(
  "organization_chatbot",
  "MandatoAberto::Schema::Result::OrganizationChatbot",
  { id => "organization_chatbot_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-12-05 11:44:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dZibxsDcdw53Yxx0s1inUw

# You can replace this text with custom code or comments, and it will be preserved on regeneration

with "MandatoAberto::Role::Verification";

sub verifiers_specs {
    my $self = shift;

    return {
        update => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                greeting_id => {
                    required   => 0,
                    type       => "Int",
                    post_check => sub {
                        my $greeting_id = $_[0]->get_value('greeting_id');

                        $self->result_source->schema->resultset("Greeting")->search( { id => $greeting_id } )->count;
                    }
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

            my $politician_greeting = $self->update( \%values );

            return $politician_greeting;
        }
    };
}

__PACKAGE__->meta->make_immutable;
1;
