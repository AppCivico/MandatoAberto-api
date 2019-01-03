package MandatoAberto::Controller::Chatbot::Dialog;
use Mojo::Base 'MandatoAberto::Controller';

sub get {
    my $c = shift;

	my $politician_id = $c->req->params->to_hash->{politician_id};
	die \["politician_id", "missing"] unless $politician_id;

	my $dialog_name = $c->req->params->to_hash->{dialog_name};
	die \["dialog_name", "missing"] unless $dialog_name;

    return $c->render(
        status => 200,
        json   => map {
            my $d = $_;

            +{
                id => $d->get_column('id'),

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
                                } $c->schema->resultset('Answer')->search(
                                    {
                                        politician_id => $politician_id,
                                        question_id   => $q->get_column('id'),
                                    }
                                    )->all()

                        }
                    } $d->questions->all()
                ]
            },
        } $c->schema->resultset('Dialog')->search({ 'me.name' => $dialog_name }, { prefetch => [ 'questions', { 'questions' => 'answers' } ] })->all()

    );
}

1;
