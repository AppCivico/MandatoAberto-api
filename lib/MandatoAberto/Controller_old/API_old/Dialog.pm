package MandatoAberto::Controller::API::Dialog;
use Moose;
use namespace::autoclean;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoListGET";
with "CatalystX::Eta::Controller::AutoResultPUT";
with "CatalystX::Eta::Controller::AutoResultGET";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Dialog",

    # AutoResultPUT.
    object_key     => "dialog",
    result_put_for => "update",

    # AutoResultGET
    build_row => sub { return { $_[0]->get_columns() } },

    # AutoListGET
    list_key => "dialog",
    build_row  => sub {
        return { $_[0]->get_columns() };
    }
);

sub root : Chained('/api/logged') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('dialog') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $dialog_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $dialog_id } );

    my $dialog = $c->stash->{collection}->find($dialog_id);
    $c->detach("/error_404") unless ref $dialog;

    $c->stash->{dialog} = $dialog;
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    my $politician_id = $c->user->id;

    my $politician = $c->model('DB::Politician')->find($politician_id);
    if ( !$politician->user->organization->is_mandatoaberto ) {
        return $self->status_ok(
            $c,
            entity => {
                dialogs => []
            }
        );
    }

    my $show_question_name = $ENV{SHOW_QUESTION_NAME};

    return $self->status_ok(
        $c,
        entity => {
            dialogs => [
                map {
                    my $d = $_;
                    +{
                        id          => $d->get_column('id'),
                        name        => $d->get_column('name'),
                        description => $d->get_column('description'),

                        questions => [
                            map {
                                my $q = $_;

                                +{
                                    id            => $q->get_column('id'),
                                    name          => $q->get_column('name'),
                                    content       => $q->get_column('content'),
                                    citizen_input => $q->get_column('citizen_input'),

                                    answer =>
                                        map {
                                            my $a = $_;

                                            +{
                                                id      => $a->get_column('id'),
                                                content => $a->get_column('content'),
                                                active  => $a->get_column('active')
                                            }
                                        } $c->model("DB::Answer")->search(
                                            {
                                                organization_chatbot_id => $politician->user->organization_chatbot_id,
                                                question_id             => $q->get_column('id'),
                                            }
                                          )->all()

                                }
                            } $d->questions->search( { 'me.active' => 1 } )->all()
                        ],
                    }
                } $c->stash->{collection}->search(
                    {
                        'me.active'                     => 1,
                        'organization.is_mandatoaberto' => 1
                    },
                    { prefetch => [ 'questions', { 'questions' => { 'answers' => { 'organization_chatbot' => 'organization' } } } ] }
                  )->all()
            ],
        }
    );
}

sub result : Chained('object') : PathPart('') :Args(0) : ActionClass('REST') { }

sub result_PUT { }

sub result_GET { }

__PACKAGE__->meta->make_immutable;

1;