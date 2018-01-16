package MandatoAberto::Controller::API::Politician::Premium;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Politician",
);

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) {
    my ($self, $c) = @_;

    eval { $c->assert_user_roles(qw/admin/) };
    if ($@) {
        $c->forward("/api/forbidden");
    }
}

sub base : Chained('root') : PathPart('premium') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST {
    my ($self, $c) = @_;

    # Posteriormente será implementado um método de pagamento
    # e a renovação/contratação do serviço premium
    # será automatizada
    my $premium = $c->req->params->{premium};
    die \["premium", 'missing'] unless defined $premium;
    my $politician = $c->stash->{politician}->update(
        {
            premium            => $premium,
            premium_updated_at => \'NOW()'
        }
    );

    # Envio um e-mail para notificar o usuário que ele pode ou não mandar mensagens diretas
    if ($politician->premium == 1) {
        $c->stash->{politician}->send_premium_activated_email();
    } else {
        $c->stash->{politician}->send_premium_deactivated_email();
    }

    return $self->status_ok(
        $c,
        entity => {
            id => $politician->id
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;