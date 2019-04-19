package MandatoAberto::Controller::Login;
use Mojo::Base 'MandatoAberto::Controller';

use MandatoAberto::Types qw(EmailAddress);

sub post {
    my $c = shift;

    my $email = $c->req->param('email') || q{};
    $c->req->params->param(email => lc $email);
    $email = $c->req->param('email');
    die \['email', 'missing'] unless length $email > 3;

    $c->validate_request_params(
        email => {
            type     => EmailAddress,
            required => 1,
        },
        password => {
            type     => "Str",
            required => 1,
        },
    );

    my $user = $c->schema->resultset('User')->search( { email => $c->req->param('email') } )->next;
    die \['email', 'invalid'] unless $user;

    my $password = $c->req->param('password');

    if ($c->authenticate($email, $password)) {
        my $ip_address = $c->req->headers->header("CF-Connecting-IP") || $c->req->headers->header("X-Forwarded-For") || $c->tx->remote_address;

        my $session = $c->current_user->new_session(
            %{ $c->req->params->to_hash },
            ip => $ip_address,
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
                                my $m = $_->module;

                                my $p = $user->parse_permissions( name => $m->name );

                                +{
                                    id          => $m->id,
                                    name        => $m->name,
                                    human_name  => $m->human_name,
                                    permissions => $p->{$m->name},
                                    weight      => $o->weight_for_module(module_id => $m->id),
                                    sub_modules => [
                                        map {
                                            +{
                                                name         => $_->name,
                                                human_name   => $_->human_name,
                                                url          => $_->url,
                                                icon_class   => $_->icon_class,
                                                weight       => $o->weight_for_module(sub_module_id => $_->id)
                                            }
                                        } $m->sub_modules->all()
                                    ]
                                }
                            } grep { $_->module->has_sub_modules == 1 } $o->organization_modules->search()->all()
                        ],
                        chatbots => [
                            map {
                                my $oc = $_;

                                +{
                                    id      => $oc->id,
                                    name    => $oc->name,
                                    picture => $oc->picture
                                }
                            } $o->organization_chatbots->all()
                        ]
                    }
                } $user->organizations->all()
            ],
            %$session
        };

        return $c->render(
            json   => $ret,
            status => 200,
        );
    }

    return $c->render(
        json   => { error => 'Bad email or password' },
        status => 400,
    );
}

1;