package MandatoAberto::Schema::ResultSet::Politician;
use common::sense;
use Moose;
use namespace::autoclean;

extends "DBIx::Class::ResultSet";

with "MandatoAberto::Role::Verification";
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use MandatoAberto::Types qw(EmailAddress);

use Data::Verifier;
use MandatoAberto::Utils;

sub verifiers_specs {
    my $self = shift;

    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                email => {
                    required   => 1,
                    type       => EmailAddress,
                    post_check => sub {
                        my $email = $_[0]->get_value("email");
                        my $email_count = $self->result_source->schema->resultset("User")->search({ email => $email })->count;
                        die \["email", 'alredy in use'] if $email_count;

                        return 1;
                    }
                },
                password => {
                    required => 1,
                    type     => "Str",
                },
                name => {
                    required => 1,
                    type     => "Str",
                },
                address_state_id => {
                    required   => 1,
                    type       => "Int",
                    post_check => sub {
                        my $address_state = $_[0]->get_value('address_state_id');
                        $self->result_source->schema->resultset("State")->search({ id => $address_state })->count;
                    },
                },
                address_city_id => {
                    required   => 1,
                    type       => "Int",
                    post_check => sub {
                        my $address_city  = $_[0]->get_value('address_city_id');
                        my $address_state = $_[0]->get_value('address_state_id');

                        $self->result_source->schema->resultset("City")->search(
                            {
                                'me.id' => $address_city,
                                'state.id' => $address_state
                            },
                            { prefetch => 'state' }
                        )->count;
                    },
                },
                party_id => {
                    required   => 1,
                    type       => "Int",
                    post_check => sub {
                        my $party_id = $_[0]->get_value('party_id');
                        $self->result_source->schema->resultset("Party")->search({ id => $party_id })->count;
                    }
                },
                office_id => {
                    required   => 1,
                    type       => "Int",
                    post_check => sub {
                        my $office_id = $_[0]->get_value('office_id');
                        $self->result_source->schema->resultset("Office")->search({ id => $office_id })->count;
                    }
                },
                fb_page_id => {
                    required   => 0,
                    type       => "Str",
                    post_check => sub {
                        my $r = shift;

                        $self->search({
                            fb_page_id => $r->get_value('fb_page_id'),
                        })->count and die \["fb_page_id", "alredy exists"];

                        return 1;
                    },
                },
                fb_page_access_token => {
                    required   => 0,
                    type       => "Str",
                    post_check => sub {
                        my $r = shift;

                        $self->search({
                            fb_page_access_token => $r->get_value('fb_page_access_token'),
                        })->count and die \["fb_page_access_token", "alredy exists"];

                        return 1;
                    },
                },
                gender => {
                    required => 1,
                    type     => "Str"
                },
                movement_id => {
                    required   => 0,
                    type       => "Int",
                    post_check => sub {
                        my $movement_id = $_[0]->get_value('movement_id');

                        my $movement_rs = $self->result_source->schema->resultset('Movement');
                        $movement_rs->search( { id => $movement_id } )->count;
                    }
                }
            }
        ),
    };
}

sub action_specs {
    my ($self) = @_;

    return {
        create => sub {
            my $r = shift;

            my %values = $r->valid_values;
            not defined $values{$_} and delete $values{$_} for keys %values;

            my $politician;
            $self->result_source->schema->txn_do(sub{
                if (length $values{password} < 6) {
                    die \["password", "must have at least 6 characters"];
                }

                if (length $values{gender} > 1 || !($values{gender} eq "F" || $values{gender} eq "M" ) ) {
                    die \["gender", "must be F or M"];
                }

                my $user = $self->result_source->schema->resultset("User")->create({ ( map { $_ => $values{$_} } qw(email password) ) },);

                $user->add_to_roles( { id => 2 } );

                $politician = $self->create(
                    {
                        (
                            map { $_ => $values{$_} }
                              qw(
                              name address_state_id address_city_id party_id
                              office_id fb_page_id fb_page_access_token gender
                              movement_id
                              )
                        ),
                        user_id => $user->id,
                    }
                );

                $politician->send_greetings_email();
                $politician->send_new_register_email();
                $user->send_email_confirmation();

                my $entity_rs = $self->result_source->schema->resultset('PoliticianEntity');
                $entity_rs->sync_dialogflow_one_politician($politician->id);
            });

            return $politician
        }
    }
}

sub get_politicians {
    my ($self) = @_;

    return politicians => [
        map {
            my $p = $_;

            {
                status             => $p->get_current_pendency,
                id                 => $p->user_id,
                email              => $p->user->email,
                name               => $p->name,
                gender             => $p->gender,
                address_state      => $p->address_state->name,
                address_city       => $p->address_city->name,
                office             => $p->office->name,
                party              => $p->party->name,
                approved           => $p->user->approved,
                approved_at        => $p->user->approved_at,
                approved_by        => $p->user->approved_by_admin_id ? $p->user->approved_by_admin->email : undef,
                premium            => $p->premium,
                premium_updated_at => $p->premium_updated_at,
                created_at         => $p->user->created_at
            }

        } $self->search(
            {},
            {
                prefetch => qw/ user address_state address_city office party /,
                order_by => 'user.created_at'
            }
          )->all()
    ]
}

sub with_active_fb_page {
    my ( $self ) = @_;

    return $self->search(
        {
            fb_page_id           => \'IS NOT NULL',
            fb_page_access_token => \'IS NOT NULL'
        }
    );
}

1;
