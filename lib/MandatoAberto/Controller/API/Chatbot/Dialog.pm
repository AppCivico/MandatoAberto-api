package MandatoAberto::Controller::API::Chatbot::Dialog;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::OrganizationDialog",
);

sub root : Chained('/api/chatbot/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('dialog') : CaptureArgs(0) {  }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    my $politician_id = $c->req->params->{politician_id};
    die \["politician_id", "missing"] unless $politician_id;

    my $dialog_name = $c->req->params->{dialog_name};
    die \["dialog_name", "missing"] unless $dialog_name;

    my $politician = $c->model('DB::Politician')->find($politician_id);

    return $self->status_ok(
        $c,
        entity => {
            map {
                my $d = $_;
                    id          => $d->get_column('id'),

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
                                            content => $a->get_column('content')
                                        }
                                    } $c->model("DB::Answer")->search(
                                        {
                                            organization_chatbot_id => $politician->user->organization_chatbot_id,
                                            organization_question_id   => $q->get_column('id'),
                                        }
                                      )->all()

                            }
                        } $d->organization_questions->all()
                    ],
            } $c->stash->{collection}->search({ 'me.name' => $dialog_name }, { prefetch => [ { 'organization_questions' => 'answers' } ] })->all()
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;