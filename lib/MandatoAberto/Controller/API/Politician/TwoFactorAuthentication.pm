package MandatoAberto::Controller::API::Politician::TwoFactorAuthentication;
use strict;
use warnings;
use utf8;
use Moose;
use namespace::autoclean;

use URI::Escape;
use Convert::Base32;
use Authen::OATH;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::TypesValidation";

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('two-factor-authentication') : CaptureArgs(0) { }

sub enable : Chained('base') : PathPart('enable') : Args(0) : ActionClass('REST') { }

sub enable_POST {
    my ($self, $c) = @_;

    my $secret  = encode_base32("12345678901234567890");
    my $email   = $c->user->obj()->email;
    my $otpauth = "otpauth://totp/$email?secret=$secret&issuer=MandatoAberto";

    my $url = "https://www.google.com/chart?chs=200x200&chld=M|0&cht=qr&chl=" . uri_escape($otpauth);

    $self->status_ok(
        $c,
        entity => {
            url => $url,
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

    my $secret = encode_base32("12345678901234567890");
    my $oath   = Authen::OATH->new();

    my $code = $c->req->params->{code};
    if ($code == $oath->totp($secret)) {
        #$c->stash->{session}->update( { '2fa' => 'true' } );
    }

    return $self->status_ok($c, entity => { ok => 1 });
}

__PACKAGE__->meta->make_immutable;

1;

