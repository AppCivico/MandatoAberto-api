package MandatoAberto::Controller::API::Chatbot;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::User",
);

sub root : Chained('/api/root') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('chatbot') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    my $page_id = $c->req->params->{fb_page_id};
    die \["fb_page_id", "missing"] unless $page_id;

    # TODO implementar autenticação mais consistente

    return $self->status_ok(
        $c,
        entity => {
            map {
                my $c = $_;

                politician_id    => $c->get_column('id'),
                politician_email => $c->get_column('email'),
                access_token     => $c->politician->get_column('fb_page_access_token')

            } $c->stash->{collection}->search(
                { 'politician.fb_page_id' => $page_id },
                { prefetch => 'politician' }
            )->next
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;