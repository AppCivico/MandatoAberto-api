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
        },
    }
}

1;
