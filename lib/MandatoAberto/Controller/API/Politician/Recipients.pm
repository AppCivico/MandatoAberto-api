package MandatoAberto::Controller::API::Politician::Recipients;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with 'CatalystX::Eta::Controller::AutoObject';
with 'CatalystX::Eta::Controller::AutoResultGET';

use Data::Printer;

__PACKAGE__->config(
    object_verify_type => 'int',
    object_key => 'recipient',

     build_row => sub {
        my ($r, $self, $c) = @_;

        return {
            id            => $r->get_column('id'),
            name          => $r->get_column('name'),
            cellphone     => $r->get_column('cellphone'),
            email         => $r->get_column('email'),
            gender        => $r->get_column('gender'),
            origin_dialog => $r->get_column('origin_dialog'),
            created_at    => $r->get_column('created_at'),
            groups        => [
                map {
                    {
                        id               => $_->id,
                        name             => $_->get_column('name'),
                        recipients_count => $_->get_column('recipients_count'),
                        status           => $_->get_column('status'),
                    }
                } $r->groups_rs->all()
            ],
            platform => $r->get_column('platform'),
        };
     },
);

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('recipients') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{collection} = $c->stash->{politician}->recipients;
}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    my $politician = $c->stash->{politician};

    my $page    = $c->req->params->{page}    || 1;
    my $results = $c->req->params->{results} || 20;

    my $has_active_page = $politician->fb_page_id ? 1 : 0;

    $c->stash->{collection} = $c->stash->{collection}->search(
        {
            politician_id => $politician->user_id,

            # Caso o político não tenha nenhuma página ativa no momento
            # mostro todos os recipients, independente da página de origem
            ( $has_active_page ? ( page_id => $politician->fb_page_id ) : () )
        },
        # { page => $page, rows => $results }
    );

    return $self->status_ok(
        $c,
        entity => {
            recipients => [
                map {
                    +{
                        id            => $_->get_column('id'),
                        name          => $_->get_column('name'),
                        cellphone     => $_->get_column('cellphone'),
                        email         => $_->get_column('email'),
                        gender        => $_->get_column('gender'),
                        origin_dialog => $_->get_column('origin_dialog'),
                        platform      => $_->get_column('platform'),
                        created_at    => $_->get_column('created_at')
                    }
                } $c->stash->{collection}->all()
            ],
        },
    );
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_GET { }

__PACKAGE__->meta->make_immutable;

1;

