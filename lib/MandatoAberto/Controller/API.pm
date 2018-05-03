package MandatoAberto::Controller::API;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

sub root : Chained('/') : PathPart('api') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->response->headers->header(charset => "utf-8");

    my $api_key = $c->req->param('api_key') || $c->req->header('X-API-Key');

    # Como utilizamos Cloudflare, não dá pra validar a api_token por IP pois cada hora a request vem de um IP diferente.
    if (defined($api_key)) {
        my $user_session = $c->model('DB::UserSession')->search({
            api_key      => $api_key,
            # valid_until  => { '>=' => \"NOW()" },
            #valid_for_ip => $c->req->address,
        })->next;

        if ($user_session) {
            my $user = $c->find_user({ id => $user_session->user_id });
            $c->set_authenticated($user);
        }
        else {
            $c->forward('forbidden');
        }
    }
}

sub logged : Chained('root') : PathPart('') : CaptureArgs(0) {
    my ($self, $c) = @_;

    if (!$c->user) {
        $c->forward('forbidden');
    }
}

sub forbidden : Private {
    my ($self, $c) = @_;

    $self->status_forbidden($c, message => "access denied");
    $c->detach();
}

__PACKAGE__->meta->make_immutable;

1;