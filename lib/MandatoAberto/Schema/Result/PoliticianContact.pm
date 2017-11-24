use utf8;
package MandatoAberto::Schema::Result::PoliticianContact;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::PoliticianContact

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

=head1 TABLE: C<politician_contact>

=cut

__PACKAGE__->table("politician_contact");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'politician_contact_id_seq'

=head2 politician_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 twitter

  data_type: 'text'
  is_nullable: 1

=head2 facebook

  data_type: 'text'
  is_nullable: 1

=head2 email

  data_type: 'text'
  is_nullable: 1

=head2 cellphone

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "politician_contact_id_seq",
  },
  "politician_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "twitter",
  { data_type => "text", is_nullable => 1 },
  "facebook",
  { data_type => "text", is_nullable => 1 },
  "email",
  { data_type => "text", is_nullable => 1 },
  "cellphone",
  { data_type => "text", is_nullable => 1 },
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


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2017-11-23 16:35:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lMRUev5g5NH4THB2GJW8cg

# You can replace this text with custom code or comments, and it will be preserved on regeneration
with 'MandatoAberto::Role::Verification';
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use MandatoAberto::Types qw(EmailAddress URI PhoneNumber Twitter);

sub verifiers_specs {
    my $self = shift;

    return {
        update => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                twitter => {
                    required   => 0,
                    type       => Twitter,
                    post_check => sub {
                        my $twitter = $_[0]->get_value('twitter');

                        $self->search({
                            twitter => $twitter
                        })->count and die \["twitter", "alredy in use"];

                        return 1;
                    }
                },
                facebook => {
                    required   => 0,
                    type       => URI,
                    post_check => sub {
                        my $facebook = $_[0]->get_value('facebook');

                        $self->search({
                            facebook => $facebook
                        })->count and die \["facebook", "alredy in use"];

                        return 1;
                    }
                },
                email => {
                    required   => 0,
                    type       => EmailAddress,
                    post_check => sub {
                        my $email = $_[0]->get_value('email');

                        $self->search({
                            email => $email
                        })->count and die \["email", "alredy in use"];

                        return 1;
                    }
                },
                cellphone => {
                    required   => 0,
                    type       => PhoneNumber,
                    post_check => sub {
                        my $cellphone = $_[0]->get_value('cellphone');

                        $self->search({
                            cellphone => $cellphone
                        })->count and die \["cellphone", "alredy in use"];

                        return 1;
                    }
                },
            }
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

            die \[ "twitter", "must'nt be longer than 15 chars" ] if length $values{twitter} > 15;

            $self->update( \%values );
        }
    };
}

__PACKAGE__->meta->make_immutable;
1;
