package MandatoAberto::Controller::API::Politician::Contact;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoListGET";
with "CatalystX::Eta::Controller::AutoListPOST";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::PoliticianContact",

    list_key  => "politician_contact",
    build_row => sub {
        return { $_[0]->get_columns() };
    },

    prepare_params_for_create => sub {
        my ($self, $c, $params) = @_;

        $params->{politician_id} = $c->user->id;

        return $params;
    },
);

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->detach("/api/forbidden") unless $c->stash->{is_me};

    eval { $c->assert_user_roles(qw/politician/) };
    if ($@) {
        $c->forward("/api/forbidden");
    }
}

sub base : Chained('root') : PathPart('contact') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST {
    my ($self, $c) = @_;

    my $politician_contact = $c->stash->{collection}->execute(
        $c,
        for  => "create",
        with => {
            %{ $c->req->params },
            politician_id => $c->user->id
        },
    );

    $politician_contact->id;

    return $self->status_ok(
        $c,
        entity => {
            id        => $politician_contact->id,
            facebook  => $politician_contact->facebook,
            twitter   => $politician_contact->twitter,
            cellphone => $politician_contact->cellphone,
            email     => $politician_contact->email,
            instagram => $politician_contact->instagram
        }
    );
}

sub list_GET {
    my ($self, $c) = @_;

    my $politician = $c->stash->{politician};

    return $self->status_ok(
        $c,
        entity => {
            politician_contact => {
                politician_id => $politician->id,

                map {
                    my $c = $_;
                    id        => $c->get_column('id'),
                    facebook  => $c->get_column('facebook'),
                    twitter   => $c->get_column('twitter'),
                    email     => $c->get_column('email'),
                    cellphone => $c->get_column('cellphone'),
                    url       => $c->get_column('url'),
                    instagram => $c->get_column('instagram')
                } $politician->politician_contacts->all()
            }
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;