package MandatoAberto::Controller::API::Politician::TwoFactorAuthentication;
use strict;
use warnings;
use utf8;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::TypesValidation";

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('two-factor-authentication') : CaptureArgs(0) { }

sub enable : Chained('base') : PathPart('enable') : Args(0) : ActionClass('REST') { }

sub enable_POST {
    my ($self, $c) = @_;

    $self->status_ok(
        $c,
        entity => {
            url => $c->user->obj->get_2fa_qrcode_url(),
        },
    );
}

sub verify : Chained('base') : PathPart('verify') : Args(0) : ActionClass('REST') { }

sub verify_POST {
    my ($self, $c) = @_;

    $self->validate_request_params(
        $c,
        code => {
            type     => 'Str',
            required => 1,
        },
    );

    my $code = $c->req->params->{code};
    my $user = $c->user->obj; # TODO Passar o user na stash.
    if ($user->verify_2fa_code($code)) {
        # TODO Validar se devemos destruir a sessão para o usuário logar de novo, já com o 2fa.
        $c->stash->{user_session}->update( { require_2fa => 'false' } );
    }

    return $self->status_ok($c, entity => { ok => 1 });
}

__PACKAGE__->meta->make_immutable;

1;

