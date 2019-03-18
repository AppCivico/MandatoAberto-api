package MandatoAberto::Schema::ResultSet::OrganizationChatbotPersona;
use common::sense;
use Moose;
use namespace::autoclean;

use Data::Verifier;
use JSON::MaybeXS;

use WebService::Facebook;

extends "DBIx::Class::ResultSet";

with "MandatoAberto::Role::Verification";
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

has _facebook => (
    is         => "ro",
    isa        => "WebService::Facebook",
    lazy_build => 1,
);

sub verifiers_specs {
    my $self = shift;

    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                organization_chatbot_id => {
                    required   => 1,
                    type       => 'Int',
                    post_check => sub {
                        my $organization_chatbot_id = $_[0]->get_value('organization_chatbot_id');

                        $self->result_source->schema->resultset('OrganizationChatbot')->search( { id => $organization_chatbot_id } )->count;
                    }
                },
                name => {
                    required => 1,
                    type     => 'Str'
                },
                picture_url => {
                    required => 1,
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

            my $organization_chatbot = $self->result_source->schema->resultset('OrganizationChatbot')->find( $values{organization_chatbot_id} );
            my $access_token         = $organization_chatbot->organization_chatbot_facebook_config->access_token;

            my $persona_id = $self->_facebook->create_persona(
                access_token => $access_token,
                body         => encode_json(
                    {
                        name                => delete $values{picture_url},
                        profile_picture_url => delete $values{profile_picture_url}
                    }
                )
            );

            my $persona = $self->_facebook->get_persona(
                access_token => $access_token,
                persona_id   => $persona_id
            );

            $values{facebook_picture_url} = $persona->{profile_picture_url};
            $values{facebook_id}          = $persona->{id};

            $persona = $self->create(\%values);

            return $persona;
        }
    };
}

sub _build__facebook { WebService::Facebook->instance }

1;
