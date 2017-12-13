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
                        $self->result_source->schema->resultset("User")->search({ email => $email })->count == 0;
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
                    # post_check => sub {
                    #     my $address_state = $_[0]->get_value('address_state_id');
                    #     $self->result_source->schema->resultset("State")->search({ id => $address_state })->count;
                    # },
                },
                address_city_id => {
                    required   => 1,
                    type       => "Int",
                    # post_check => sub {
                    #     my $address_city = $_[0]->get_value('address_city_id');
                    #     $self->result_source->schema->resultset("City")->search({ id => $address_city })->count;
                    # },
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
                fb_app_id => {
                    required   => 0,
                    type       => "Str",
                    post_check => sub {
                        my $r = shift;

                        $self->search({
                            fb_app_id => $r->get_value('fb_app_id'),
                        })->count and die \["fb_app_id", "alredy exists"];

                        return 1;
                    },
                },
                fb_app_secret => {
                    required   => 0,
                    type       => "Str",
                    post_check => sub {
                        my $r = shift;

                        $self->search({
                            fb_app_secret => $r->get_value('fb_app_secret'),
                        })->count and die \["fb_app_secret", "alredy exists"];

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

            if (length $values{password} < 6) {
                die \["password", "must have at least 6 characters"];
            }

            if (length $values{gender} > 1 || !($values{gender} eq "F" || $values{gender} eq "M" ) ) {
                die \["gender", "must be F or M"];
            }

            my $user = $self->result_source->schema->resultset("User")->create(
                { ( map { $_ => $values{$_} } qw(email password) ) },
            );

            $user->add_to_roles( { id => 2 } );

            my $politician = $self->create(
                {
                    (
                        map { $_ => $values{$_} } qw(
                            name address_state_id address_city_id party_id
                            office_id fb_page_id fb_app_id fb_app_secret
                            fb_page_access_token gender
                        )
                    ),
                    user_id => $user->id,
                }
            );

            # Ao criar um representante público cria-se também um chatbot
            my $chatbot_user = $self->result_source->schema->resultset("User")->create({
                email    => $values{email} . '.chatbot',
                password => $values{email} . '.chatbot'
            });

            $chatbot_user->add_to_roles( { id => 3 } );

            my $politician_chatbot = $self->result_source->schema->resultset("PoliticianChatbot")->create( {
                user_id       => $chatbot_user->id,
                politician_id => $politician->id
            } );

            if (is_test()) {
                $user->update( { approved => 1 } );
                $chatbot_user->update( { approved => 1 } );
            }

            return $politician
        }
    }
}

1;
