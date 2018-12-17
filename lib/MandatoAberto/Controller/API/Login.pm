package MandatoAberto::Controller::API::Login;
use Moose;
use namespace::autoclean;

use MandatoAberto::Types qw(EmailAddress);

BEGIN { extends "CatalystX::Eta::Controller::REST" }

with "CatalystX::Eta::Controller::TypesValidation";

sub root : Chained('/api/root') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('login') : CaptureArgs(0) { }

sub login : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub login_POST {
    my ($self, $c) = @_;

    if (length $c->req->params->{email} < 1) {
        die \['email', 'missing'] unless $c->req->params->{email};
    }

    $c->req->params->{email} = lc $c->req->params->{email};

    $self->validate_request_params(
        $c,
        email => {
            type     => EmailAddress,
            required => 1,
        },
        password => {
            type     => "Str",
            required => 1,
        },
    );

    my $user = $c->model("DB::User")->search( { email => $c->req->params->{email} } )->next;

    if ($user) {
        $user->approved == 1 ? () : die \['approved', 'user not approved']
    }

    my $authenticate = $c->authenticate({
        ( map { $_ => $c->req->params->{$_} } qw(email password) ),
        approved => 1
    });

    if ($authenticate) {
        my $ipAddr = $c->req->header("CF-Connecting-IP") || $c->req->header("X-Forwarded-For") || $c->req->address;

        my $session = $c->user->obj->new_session(
            %{$c->req->params},
            ip => $ipAddr,
        );

		my $ret = {
            organizations => [
                map {
                    my $o = $_->organization;

                    +{
                        id      => $o->id,
                        name    => $o->name,
                        picture => $o->picture,
                        modules => [
                            map {
                                my $m    = $_->module;
                                my $name = $m->name;

                                my $p = $user->parse_permissions( name => $m->name );

                                +{
                                    "$name" => {
                                        id          => $m->id,
                                        permissions => $p->{$name},
                                    }
                                }
                            } $o->organization_modules
                        ]
                    }
                } $user->organizations->all()
		    ],
            %$session
        };

        return $self->status_ok( $c, entity => $ret );
    }

    return $self->status_bad_request($c, message => 'Bad email or password.');
}

__PACKAGE__->meta->make_immutable;

1;