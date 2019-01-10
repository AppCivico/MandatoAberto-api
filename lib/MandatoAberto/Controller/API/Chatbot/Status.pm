package MandatoAberto::Controller::API::Chatbot::Status;
use common::sense;
use Moose;
use namespace::autoclean;

use JSON::MaybeXS;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

sub root : Chained('/api/chatbot/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('status') : CaptureArgs(0) {  }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST {
    my ($self, $c) = @_;

    if ( defined $c->req->params->{err_msg} ) {
        $c->req->params->{err_msg} = eval { decode_json $c->req->params->{err_msg} };
        die \['err_msg', 'could not decode json'] if $@;
    }

    my $status = $c->model('DB::OrganizationChatbotStatus')->execute(
        $c,
        for  => 'create',
        with => $c->req->params
    );

    return $self->status_created(
        $c,
        location => $c->uri_for($c->controller('API::Chatbot::Politician::Status'), $status->id),
        entity   => { id => $status->id }
    );
}

sub list_GET {
    my ($self, $c) = @_;

    die \['organization_chatbot_id', 'missing'] unless defined $c->req->params->{organization_chatbot_id};

    my $status = $c->model('DB::OrganizationChatbotStatus')->search( { organization_chatbot_id => $c->req->params->{organization_chatbot_id} } )->next;
    use DDP; p $status;
    return $self->status_ok(
        $c,
        entity => {

        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
