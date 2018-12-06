package MandatoAberto::Controller::API::Politician::Entity;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with 'CatalystX::Eta::Controller::AutoBase';
with 'CatalystX::Eta::Controller::AutoObject';
with 'CatalystX::Eta::Controller::AutoResultGET';

__PACKAGE__->config(
    # AutoBase
    result  => 'DB::PoliticianEntity',
    no_user => 1,

    # AutoObject
    object_verify_type => 'int',
    object_key         => 'politician_entity',

    # AutoResultGET
    build_row => sub {
        my ($r, $self, $c) = @_;

        return {
            id              => $r->id,
            recipient_count => $r->recipient_count,
            created_at      => $r->created_at,
            updated_at      => $r->updated_at,
            tag             => $r->human_name,
            recipients      => [
                map {
                    my $recipient = $_;

                    +{
                        id        => $recipient->id,
                        name      => $recipient->name,
                        gender    => $recipient->gender,
                        email     => $recipient->email,
                        gender    => $recipient->gender,
                        picture   => $recipient->picture,
                        platform  => $recipient->platform,
                        cellphone => $recipient->cellphone,
                        groups    => [
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
                } $r->get_recipients->all()
            ],
            knowledge_base => $r->get_knowledge_bases_by_types()
        };
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

sub base : Chained('root') : PathPart('intent') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) { }

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_GET { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    my $filter = $c->req->params->{filter} || 'all';
    die \['filter', 'invalid'] unless $filter =~ m/(all|active)/;

    my $organization_chatbot_id = $c->stash->{politician}->user->organization_chatbot_id;

    return $self->status_ok(
        $c,
        entity => {
            politician_entities => [
                map {
                    my $e = $_;

                    if ( $filter eq 'all' ) {
                        +{
                            id              => $e->id,
                            recipient_count => $e->recipient_count,
                            created_at      => $e->created_at,
                            updated_at      => $e->updated_at,
                            tag             => $e->human_name,
                            knowledge_base  => $e->get_knowledge_bases_by_types()
                        }
                    }
                    else {
                        if ( $e->has_active_knowledge_base ) {
                            +{
                                id              => $e->id,
                                recipient_count => $e->recipient_count,
                                created_at      => $e->created_at,
                                updated_at      => $e->updated_at,
                                tag             => $e->human_name,
                                knowledge_base  => $e->get_knowledge_bases_by_types()
                            };
                        } else { }
                    }

                } $c->stash->{collection}->search(
                    { organization_chatbot_id => $organization_chatbot_id },
                    { order_by => 'name' }
                  )->all
            ]
        }
    )
}

# Listagem de entities sem nenhum posicionamento (politician_knowledge_base)
sub pending : Chained('base') : PathPart('pending') : Args(0) : ActionClass('REST') { }

sub pending_GET {
    my ($self, $c) = @_;

    my $organization_chatbot_id = $c->stash->{politician}->user->organization_chatbot_id;

    return $self->status_ok(
        $c,
        entity => {
            politician_entities => [
                map {
                    my $e = $_;

                    if ( !$e->has_active_knowledge_base ) {
                        +{
                            id              => $e->id,
                            recipient_count => $e->recipient_count,
                            created_at      => $e->created_at,
                            updated_at      => $e->updated_at,
                            tag             => $e->human_name,
                            recipients      => [
                                map {
                                    my $recipient = $_;

                                    +{
                                        id        => $recipient->id,
                                        email     => $recipient->email,
                                        gender    => $recipient->gender,
                                        picture   => $recipient->picture,
                                        platform  => $recipient->platform,
                                        cellphone => $recipient->cellphone
                                    }
                                } $e->get_recipients->all()
                            ]
                        }
                    }
                    else {  }
                } $c->stash->{collection}->search(
                    { organization_chatbot_id => $organization_chatbot_id },
                    { order_by => 'name' }
                  )->all
            ]
        }
    )
}


__PACKAGE__->meta->make_immutable;

1;