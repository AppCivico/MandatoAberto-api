package MandatoAberto::Controller::API::Politician::Entity;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with 'CatalystX::Eta::Controller::AutoBase';
with 'CatalystX::Eta::Controller::AutoListGET';
with 'CatalystX::Eta::Controller::AutoObject';
with 'CatalystX::Eta::Controller::AutoResultGET';

__PACKAGE__->config(
    # AutoBase
    result  => 'DB::PoliticianEntity',
    no_user => 1,

    # AutoListGET
    list_key => 'politician_entities',
    build_list_row => sub {
        my ($r, $self, $c) = @_;

        return {
            id              => $r->id,
            recipient_count => $r->recipient_count,
            created_at      => $r->created_at,
            updated_at      => $r->updated_at,
            tag             => $r->name,
        };
    },


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
            tag             => $r->name,
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
                } $r->get_recipients->all()
            ]
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

sub list_GET { }

# Listagem de entities sem nenhum posicionamento (politician_knowledge_base)
sub pending : Chained('base') : PathPart('pending') : Args(0) : ActionClass('REST') { }

sub pending_GET {
    my ($self, $c) = @_;

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
                            tag             => $e->name,
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
                    { politician_id => $c->stash->{politician}->id }
                  )->all
            ]
        }
    )
}


__PACKAGE__->meta->make_immutable;

1;