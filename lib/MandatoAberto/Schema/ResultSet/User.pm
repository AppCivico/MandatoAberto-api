package MandatoAberto::Schema::ResultSet::User;
use common::sense;
use Moose;
use namespace::autoclean;

extends "DBIx::Class::ResultSet";

with "MandatoAberto::Role::Verification";
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use MandatoAberto::Types qw(EmailAddress);

use Data::Verifier;
use MandatoAberto::Utils;

use UUID::Tiny qw/is_uuid_string/;

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
                    required   => 0,
                    type       => "Int",
                    post_check => sub {
                        my $address_state = $_[0]->get_value('address_state_id');
                        $self->result_source->schema->resultset("State")->search({ id => $address_state })->count;
                    },
                },
                address_city_id => {
                    required   => 0,
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
                    required   => 0,
                    type       => "Int",
                    post_check => sub {
                        my $party_id = $_[0]->get_value('party_id');
                        $self->result_source->schema->resultset("Party")->search({ id => $party_id })->count;
                    }
                },
                office_id => {
                    required   => 0,
                    type       => "Int",
                    post_check => sub {
                        my $office_id = $_[0]->get_value('office_id');
                        $self->result_source->schema->resultset("Office")->search({ id => $office_id })->count;
                    }
                },
                gender => {
                    required => 0,
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
                },
                fb_page_id => {
                    required => 0,
                    type     => 'Str'
                },
                fb_page_access_token => {
                    required => 0,
                    type     => 'Str'
                },
            }
        ),
        # Utilizando um método diferente para não precisar corrigir os testes por agora
        create_user => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                email => {
                    required => 1,
                    type       => EmailAddress,
                    post_check => sub {
                        my $email = $_[0]->get_value('email');

                        $self->result_source->schema->resultset("User")->search({ email => $email })->count
                            and die \["email", 'alredy in use'];

                        return 1;
                    }
                },
                password => {
                    required   => 1,
                    type       => "Str",
                    min_length => 4
                },
                name => {
                    required => 1,
                    type     => "Str",
                },
                invite_token => {
                    required   => 0,
                    type       => "Str",
                    post_check => sub {
                        my $token = $_[0]->get_value('invite_token');

                        is_uuid_string($token) or die \['invite_token', 'invalid'];

                        $self->result_source->schema->resultset('Organization')->search({ invite_token => $token })->count
                            or die \['invite_token', 'invalid'];
                    }
                },
                custom_url => {
                    required => 0,
                    type     => 'Str'
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

            my $user;
            $self->result_source->schema->txn_do(sub {
                if (length $values{password} < 6) {
                    die \["password", "must have at least 6 characters"];
                }

                if ( $values{gender} && length $values{gender} > 1 || !( $values{gender} eq "F" || $values{gender} eq "M" ) ) {
                    die \["gender", "must be F or M"];
                }

                my $organization = $self->result_source->schema->resultset('Organization')->create(
                    {
                        name                  => $values{name},
                        # Ao criar a organização já crio com um chatbot.
                        organization_chatbots => [
                            {
                                organization_chatbot_general_config => {
                                    is_active      => 0,
                                    issue_active   => 1,
                                    use_dialogflow => 1,
                                    # Criando com a config do MA
                                    dialogflow_config_id => 1
                                },
                            }
                        ]
                    }
                );
                $organization->organization_modules->create_mandatoaberto_modules($organization->id);

                $user = $self->create(
                    {
                        (
                            map { $_ => $values{$_} }
                              qw(
                              name email password address_state_id address_city_id party_id
                              office_id gender movement_id
                              ),
                        ),
                        politician => {(
                            map { $_ => $values{$_} }
                              qw(
                              name address_state_id address_city_id party_id
                              office_id fb_page_id fb_page_access_token gender
                              movement_id
                              )
                        )},
                        user_organizations => [{
                            organization_id => $organization->id,
                        }]
                    }
                );

                $user->add_to_roles( { id => 2 } );

                # Por enquanto usuarios são criados com todos as permissões
                $user->add_all_permissions();

                $user->send_greetings_email();
                $user->send_new_register_email();
                $user->send_email_confirmation();
            });

            return $user;
        },
        create_user => sub {
            my $r = shift;

            my %values = $r->valid_values;
            not defined $values{$_} and delete $values{$_} for keys %values;

            my $user;
            $self->result_source->schema->txn_do(sub {

                # Pegando organização do token de invite ou criando uma nova
                my $organization;
                if ( $values{invite_token} ) {
                    $organization = $self->result_source->schema->resultset('Organization')->search( { invite_token => delete $values{invite_token} } )->next;
                }
                else {
                    $organization = $self->result_source->schema->resultset('Organization')->create(
                        {
                            name             => $values{name},
                            is_mandatoaberto => 0,
                            custom_url       => $values{custom_url},
                            # Ao criar a organização já crio com um chatbot.
                            organization_chatbots => [
                                {
                                    organization_chatbot_general_config => {
                                        issue_active     => 1,
                                        use_dialogflow   => 0,
                                    },
                                }
                            ]
                        }
                    );
                }

                # Criando o usuário e vinculando com a organização
                $user = $self->create(
                    {
                        ( map { $_ => $values{$_} } qw( name email password ) ),
                        politician => {
                            name             => $values{name},
                            gender           => 'F',
                            address_city_id  => 1,
                            address_state_id => 1,
                        },
                        user_organizations => [{
                            organization_id => $organization->id,
                        }]
                    }
                );

                # Adicionando role de 'politician'
                # Por agora, essa permissão é necessária.
                # Pois as controllers ainda não foram atualizadas
                $user->user_roles->create( { role_id => 2 } );

                # Criando módulos da organização
                $organization->organization_modules->create_modules($organization->id);

                # Adicionando permissões para o usuário
                $user->add_all_permissions();
            });

            return $user;
        }
    }
}


sub get_politicians {
    my ($self) = @_;

    return politicians => [
        map {
            my $p = $_;

            {
                status             => $p->politician->get_current_pendency,
                id                 => $p->id,
                email              => $p->email,
                name               => $p->name,
                gender             => $p->politician->gender,
                address_state      => $p->address_state->name,
                address_city       => $p->address_city->name,
                office             => $p->politician->office ? $p->politician->office->name : undef,
                party              => $p->politician->party  ? $p->politician->party->name  : undef,
                approved           => $p->approved,
                approved_at        => $p->approved_at,
                approved_by        => $p->approved_by_admin_id ? $p->user->approved_by_admin->email : undef,
                premium            => $p->politician->premium,
                premium_updated_at => $p->politician->premium_updated_at,
                created_at         => $p->created_at
            }

          } $self->search(
            {},
            {
                prefetch => qw/ politician address_state address_city office party /,
                order_by => 'me.created_at'
            }
          )->all()
      ];
}


sub with_active_fb_page {
    my ($self) = @_;

    return $self->search(
        {
            fb_page_id           => \'IS NOT NULL',
            fb_page_access_token => \'IS NOT NULL'
        }
    );
}

1;
