package MandatoAberto::Controller::API::Politician::Recipients;
use common::sense;
use Moose;
use namespace::autoclean;

use MandatoAberto::Utils qw(is_test);

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with 'CatalystX::Eta::Controller::AutoObject';
with "CatalystX::Eta::Controller::TypesValidation";
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
            intents  => [
                map {
                    {
                        id  => $_->id,
                        tag => $_->human_name
                    }
                } $r->entity_rs->all()
            ]
        };
     },
);

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('recipients') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{collection} = $c->stash->{politician}->user->organization_chatbot->recipients;
}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    my $politician = $c->stash->{politician};

    $self->validate_request_params(
        $c,
        page => {
            required   => 0,
            type       => 'Int'
        },
        results => {
            required => 0,
            type     => 'Int',
        },
    );

    my $page    = $c->req->params->{page}    || 1;
    my $results = $c->req->params->{results} || 20;

    if ( !$politician->user->organization_chatbot->fb_config ) {
        # TODO pensar numa solução melhor
        return $self->status_ok(
        $c,
        entity => {
            recipients => [
            ],
            itens_count => 0
        },
    );
    }

    my $has_active_page = $politician->user->organization_chatbot->fb_config->access_token ? 1 : 0;

    $c->stash->{collection} = $c->stash->{collection}->search(
        {
            # Caso o político não tenha nenhuma página ativa no momento
            # mostro todos os recipients, independente da página de origem
            ( $has_active_page && !is_test ? ( page_id => $politician->user->organization_chatbot->fb_config->page_id ) : () )
        },
    );

    return $self->status_ok(
        $c,
        entity => {
            recipients => [
                map {
                    # Tratando caso de pessoas que entraram no banco com o nome undefined undefined
                    my $name = $_->get_column('name');
                    $name = $name eq 'undefined undefined' ? 'Não definido' : $name;

                    +{
                        id            => $_->get_column('id'),
                        name          => $name,
                        cellphone     => $_->get_column('cellphone'),
                        email         => $_->get_column('email'),
                        gender        => $_->get_column('gender'),
                        created_at    => $_->get_column('created_at'),
                        cpf           => $_->get_column('cpf'),
                        groups        => [
                            map {
                                {
                                    id               => $_->id,
                                    name             => $_->get_column('name'),
                                    recipients_count => $_->get_column('recipients_count'),
                                    status           => $_->get_column('status'),
                                }
                            } $_->groups_rs->all()
                        ],
                        intents  => [
                            map {

                                {
                                    id  => $_->id,
                                    tag => $_->human_name
                                }
                            } $_->entity_rs->all()
                        ]
                    }
                } $c->stash->{collection}->search(
                    undef,
                    { page => $page, rows => $results }
                  )->all()
            ],
            itens_count => $c->stash->{collection}->count
        },
    );
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_GET { }

__PACKAGE__->meta->make_immutable;

1;

