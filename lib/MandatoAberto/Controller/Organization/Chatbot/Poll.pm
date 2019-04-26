package MandatoAberto::Controller::Organization::Chatbot::Poll;
use Mojo::Base 'MandatoAberto::Controller';

use Moose::Util::TypeConstraints;
use Scalar::Util qw(looks_like_number);

sub load {
	my $c = shift;

	my $poll_id = $c->param('poll_id');
	my $poll    = $c->schema->resultset('Poll')->search( { 'me.id' => $poll_id } )->next;

    if (!ref $poll) {
		$c->reply_not_found;
		$c->detach();
	}

	$c->stash(poll => $poll);

	return $c;
}

sub post {
    my $c = shift;

    my $params = $c->req->params->to_hash;

    # Tratando parametros de perguntas e opções
    $params->{poll_questions} = [];

    for my $param (keys %{ $params } ) {
        if ($param =~ m{^questions\[([0-9]+)\](\[([^\]]+)\])?(\[([0-9]+)\])?(\[([^\]]+)\])?$}) {
            $params->{poll_questions}->[$1] ||= {};

            if (!$3) {
                $params->{poll_questions}->[$1]->{content} = delete $params->{$param};
            }
            elsif ($3 eq 'options') {
                $params->{poll_questions}->[$1]->{poll_question_options}->[$5]->{content} = delete $params->{$param};
            }
        }
    }

    $params->{poll_questions} = [ grep defined, @{ $params->{poll_questions} } ];

    die \['questions[]', 'missing'] unless scalar(@{ $params->{poll_questions} }) >= 1;

    for (my $i = 0; $i < scalar @{ $params->{poll_questions} } ; $i++) {
        my $question = $params->{poll_questions}->[$i];

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

	my $poll = $c->stash('chatbot')->polls->execute(
		$c,
		for  => 'create',
		with => $params,
	);

	$c->render(
		status => 201,
		json   => { id => $poll->id }
	);
}

sub get {
    my $c = shift;

    my $chatbot = $c->stash('chatbot');

	my $page    = $c->req->params->{page}    || 1;
	my $results = $c->req->params->{results} || 20;

    return $c->render(
        status => 200,
        json   => {
            polls => [
                map {
                    my $p = $_;
                    +{
                        id        => $p->get_column('id'),
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
												count   => $qo->poll_results->search()->count,
											  }
										} $pq->poll_question_options->all()
									]
                                }

                            } $p->poll_questions->all()
                        ]
                    }
                } $chatbot->polls->search(
                    undef,
                    { prefetch => 'poll_questions' }
                )->all()
            ],
			itens_count => $chatbot->polls->count
        }
    );
}

sub get_result {
    my $c = shift;

    my $recipient = $c->stash('recipient');

    return $c->render(
        status => 200,
        json   => {
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
    );
}


1;
