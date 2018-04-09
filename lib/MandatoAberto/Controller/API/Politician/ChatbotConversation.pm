package MandatoAberto::Controller::API::Politician::ChatbotConversation;
use common::sense;
use Moose;
use namespace::autoclean;

use MandatoAberto::Utils qw/ is_test /;

use YAML::XS;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoListPOST";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::PoliticianChatbotConversation",

    # AutoListPOST
    data_from_body            => 1,
    prepare_params_for_create => sub {
        my ($self, $c, $params) = @_;

        $params->{politician_id} = $c->stash->{politician}->id;

        return $params;
    },
);

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('chatbot-conversation') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST { }

sub list_GET {
    my ($self, $c) = @_;

    return $self->status_ok(
        $c,
        entity => {
            $c->stash->{politician}->answers->get_answered_dialogs
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
