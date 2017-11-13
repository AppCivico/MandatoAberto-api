package MandatoAberto::Controller::API::Politician::Contact;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoResultPUT";
with "CatalystX::Eta::Controller::AutoListGET";
with "CatalystX::Eta::Controller::AutoListPOST";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::PoliticianContact",

    # AutoResultPUT.
    object_key     => "politician_contact",
    result_put_for => "update",

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

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('contact') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $politician_contact_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $politician_contact_id } );

    my $politician_contact = $c->stash->{collection}->find($politician_contact_id);
    $c->detach("/error_404") unless ref $politician_contact;

    $c->stash->{politician_contact} = $politician_contact;

    $c->stash->{is_me} = int($c->user->id == $politician_contact->politician_id);
    $c->detach("/api/forbidden") unless $c->stash->{is_me};
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_PUT { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST { }

sub list_GET {
    my ($self, $c) = @_;

    my $politician_id = $c->user->id;

    return $self->status_ok(
        $c,
        entity => {
            politician_contact => {
                politician_id => $politician_id,

                map {
                    my $c = $_;

                    facebook  => $c->get_column('facebook'),
                    twitter   => $c->get_column('twitter'),
                    email     => $c->get_column('email'),
                    cellphone => $c->get_column('cellphone'),
                } $c->stash->{collection}->search( { politician_id => $politician_id } )->all()
            }
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;