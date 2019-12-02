package MandatoAberto::Controller::API::Chatbot::Ticket::Type;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

sub root : Chained('/api/chatbot/ticket/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('type') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    my $chatbot_id = $c->req->params->{chatbot_id}
      or die \['chatbot_id', 'missing'];

    my $chatbot = $c->model('DB::OrganizationChatbot')->find($chatbot_id)
      or die \['chatbot_id', 'invalid'];

    my $rs = $c->model('DB::OrganizationTicketType')->search_rs( { 'me.organization_id' => $chatbot->organization_id } );

    return $self->status_ok(
        $c,
        entity => $rs->build_list
    );
}

__PACKAGE__->meta->make_immutable;

1;
