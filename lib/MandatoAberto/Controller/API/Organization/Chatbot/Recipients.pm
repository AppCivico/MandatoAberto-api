package MandatoAberto::Controller::API::Organization::Chatbot::Recipients;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::TypesValidation";

sub root : Chained('/api/organization/chatbot/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('recipients') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{collection} = $c->stash->{chatbot}->recipients;
}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $recipient_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { 'me.id' => $recipient_id } );

    my $recipient = $c->stash->{collection}->find($recipient_id);
    $c->detach("/error_404") unless ref $recipient;

    $c->stash->{recipient} = $recipient;
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

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
        page_id => {
            required => 0,
            type     => 'Str'
        }
    );

    my $page    = $c->req->params->{page}    || 1;
    my $results = $c->req->params->{results} || 20;
    my $page_id = $c->req->params->{page_id};

    $c->stash->{collection} = $c->stash->{collection}->search(
        {
            $page_id ?
              (
                  'organization_chatbot_facebook_config.page_id' => $page_id
              )
              : ()
        },
        { prefetch => { 'organization_chatbot' => 'organization_chatbot_facebook_config' } }
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

sub result_GET {
    my ($self, $c) = @_;

    my $recipient = $c->stash->{recipient};

    return $self->status_ok(
        $c,
        entity => {
            id            => $recipient->get_column('id'),
            name          => $recipient->get_column('name'),
            cellphone     => $recipient->get_column('cellphone'),
            email         => $recipient->get_column('email'),
            gender        => $recipient->get_column('gender'),
            created_at    => $recipient->get_column('created_at'),
            groups        => [
                map {
                    {
                        id               => $_->id,
                        name             => $_->get_column('name'),
                        recipients_count => $_->get_column('recipients_count'),
                        status           => $_->get_column('status'),
                    }
                } $recipient->groups_rs->all()
            ],
            intents  => [
                map {
                    {
                        id  => $_->id,
                        tag => $_->human_name
                    }
                } $recipient->entity_rs->all()
            ]
        }
    )
}

__PACKAGE__->meta->make_immutable;

1;

