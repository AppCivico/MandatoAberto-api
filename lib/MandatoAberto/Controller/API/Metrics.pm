package MandatoAberto::Controller::API::Metrics;
use common::sense;
use Moose;
use namespace::autoclean;

with "CatalystX::Eta::Controller::TypesValidation";

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

sub root : Chained('/api/root') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('metrics') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    $self->validate_request_params(
        $c,
        chatbot_id => {
            type     => 'Int',
            required => 1,
        },
        security_token => {
            type     => 'Str',
            required => 1
        },
        since => {
            type     => 'Int',
            required => 0
        },
        until => {
            type     => 'Int',
            required => 0
        }
    );

    $c->req->params->{security_token} eq $ENV{METRICS_SECURITY_TOKEN}
      or die \['security_token', 'invalid'];

    my $chatbot = $c->model('DB::OrganizationChatbot')->find($c->req->params->{chatbot_id})
      or die \['chatbot_id', 'invalid'];

    return $self->status_ok(
        $c,
        entity => $chatbot->build_external_metrics(
            since => $c->req->params->{since},
            until => $c->req->params->{until}
        )
    );
}

1;