package MandatoAberto::Controller::API::Politician::Poll;
use Moose;
use namespace::autoclean;

use Scalar::Util qw(looks_like_number);

BEGIN { extends "CatalystX::Eta::Controller::REST" }

with "CatalystX::Eta::Controller::AutoBase";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Poll",
);

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->detach("/api/forbidden") unless $c->stash->{is_me};

    eval { $c->assert_user_roles(qw/politician/) };
    if ($@) {
        $c->forward("/api/forbidden");
    }
}

sub base : Chained('root') : PathPart('poll') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $poll_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $poll_id } );

    my $poll = $c->stash->{collection}->find($poll_id);
    $c->detach("/error_404") unless ref $poll;

    $c->stash->{is_me} = int($c->user->id == $poll->politician_id);
    $c->stash->{poll}  = $poll;

    $c->detach("/api/forbidden") unless $c->stash->{is_me};
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    return $self->status_ok(
        $c,
        entity => {
            polls => [
                map {
                    my $p = $_;
                    +{
                        id        => $p->get_column('id'),
                        name      => $p->get_column('name'),
                        status_id => $p->get_column('status_id'),

                        questions => [
                            map {
                                my $pq = $_;
                                +{
                                    id      => $pq->get_column('id'),
                                    content => $pq->get_column('content'),
                                }

                            } $p->poll_questions->all()
                        ]
                    }
                } $c->stash->{collection}->search(
                    { 'me.organization_chatbot_id' => $c->stash->{politician}->user->organization_chatbot_id },
                    { prefetch => 'poll_questions' }
                )->all()
            ]
        }
    );
}

sub list_POST {
    my ($self, $c) = @_;

        $c->req->params->{poll_questions} = [];

    for my $param (keys %{ $c->req->params } ) {
        if ($param =~ m{^questions\[([0-9]+)\](\[([^\]]+)\])?(\[([0-9]+)\])?(\[([^\]]+)\])?$}) {
            $c->req->params->{poll_questions}->[$1] ||= {};

            if (!$3) {
                $c->req->params->{poll_questions}->[$1]->{content} = delete $c->req->params->{$param};
            }
            elsif ($3 eq 'options') {
                $c->req->params->{poll_questions}->[$1]->{poll_question_options}->[$5]->{content} = delete $c->req->params->{$param};
            }
        }
    }

    $c->req->params->{poll_questions} = [ grep defined, @{ $c->req->params->{poll_questions} } ];

    die \['questions[]', 'missing'] unless scalar(@{ $c->req->params->{poll_questions} }) >= 1;

    for (my $i = 0; $i < scalar @{ $c->req->params->{poll_questions} } ; $i++) {
        my $question = $c->req->params->{poll_questions}->[$i];

        die \["questions[$i]", 'must have at least 2 options'] if ( !defined $question->{poll_question_options} || scalar(@{ $question->{poll_question_options} }) < 2 );

        for my $k ( keys %{ $question } ) {
            my $cons;

            if ($k eq 'content') {
                $cons = Moose::Util::TypeConstraints::find_or_parse_type_constraint('Str');
                die \["question[$i]", 'invalid'] if !ref($cons) || !$cons->check($question->{$k}) || looks_like_number($question->{$k});
            }
            if ($k eq 'poll_question_options') {
                for (my $j = 0; $j < scalar @{ $question->{poll_question_options} }; $j++) {
                    my $question_option = $question->{poll_question_options}->[$j];

                    # Caso a enquete tenha 2 opções mas só tenha a opção 2 preenchida
                    # Isto é, apenas questions[$i][options][1] devo disparar um erro
                    die \["questions[$i][options][$j]", "missing"] if $j < 1 && ! defined $question_option;

                    # O Facebook tem um limite de 20 chars para botões de quick reply
                    if (length $question_option->{content} > 20) {
                        die \["questions[$i][options][$j]", "Options mustn't be longer than 20 characters"];
                    }
                }
            }
        }
    }

    my $poll = $c->stash->{collection}->execute(
        $c,
        for  => "create",
        with => {
            %{$c->req->params},
            politician_id => $c->user->id
        }
    );

    return $self->status_created(
        $c,
        location => $c->uri_for($c->controller("API::Poll")->action_for('result'), [ $poll->id ]),
        entity   => { id => $poll->id }
    );
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_GET {
    my ($self, $c) = @_;

    $c->stash->{collection} = $c->stash->{collection}->next;

    return $self->status_ok(
        $c,
        entity => {
            id        => $c->stash->{collection}->id,
            name      => $c->stash->{collection}->name,
            status_id => $c->stash->{collection}->status_id,

            questions => [
                map {
                    my $pq = $_;

                    +{
                        id      => $pq->get_column('id'),
                        content => $pq->get_column('content'),

                        options => [
                            map {
                                my $qo = $_;

                                +{
                                    id      => $qo->get_column('id'),
                                    content => $qo->get_column('content'),
                                    count   => $qo->poll_results->search( { origin => 'propagate' } )->count,
                                  }
                            } $pq->poll_question_options->all()
                        ]
                    }

                } $c->stash->{collection}->poll_questions->all()
            ]

        }
    );
}

sub propagate_list : Chained('base') : PathPart('propagate') : Args(0) : ActionClass('REST') { }

sub propagate_list_GET {
    my ($self, $c) = @_;

    my $politician_id = $c->stash->{politician}->id;

    return $self->status_ok(
        $c,
        entity => {
            poll_propagations => [
                map {
                    my $pp = $_;

                    +{
                        id              => $pp->get_column('campaign_id'),
                        recipient_count => $pp->get_column('count'),
                        groups          => [
                            map {
                                my $g = $_;

                                +{
                                    id   => $g->get_column('id'),
                                    name => $g->get_column('name')
                                }
                            } $pp->groups_rs->all()
                        ],

                        poll => {
                            id => $pp->get_column('poll_id'),

                            map {
                                my $p = $_;

                                name      => $p->get_column('name'),
                                questions => [
                                    map {
                                        my $pq = $_;
                                        +{
                                            id      => $pq->get_column('id'),
                                            content => $pq->get_column('content'),

                                            options => [
                                                map {
                                                    my $qo = $_;

                                                    +{
                                                        id      => $qo->get_column('id'),
                                                        content => $qo->get_column('content'),
                                                        count   => $qo->poll_results->search( { origin => 'propagate' } )->count,
                                                    }
                                                } $pq->poll_question_options->all()
                                            ]
                                        }

                                    } $p->poll_questions->all()
                                ]
                            } $pp->poll
                        }
                    }
                } $c->model("DB::PollPropagate")->search(
                    { 'me.politician_id'    => $politician_id },
                    { prefetch => [ 'poll', { 'poll' => { 'poll_questions' => { 'poll_question_options' => 'poll_results' } } } ] }
                )->all()
            ],
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;