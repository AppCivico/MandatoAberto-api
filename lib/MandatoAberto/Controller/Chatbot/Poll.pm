package MandatoAberto::Controller::Chatbot::Poll;
use Mojo::Base 'MandatoAberto::Controller';

sub get {
	my $c = shift;

    my $fb_page_id = $c->req->params->to_hash->{fb_page_id};
    die \['fb_page_id', 'missing'] unless $fb_page_id;

	my $politician = $c->schema->resultset('Politician')->search( { fb_page_id => $fb_page_id } )->next;
	die \['fb_page_id', 'invalid'] unless $politician;

	return $c->render(
		status => 200,
        json   => map {
            my $p = $_;

            +{
                id        => $p->get_column('id'),
                name      => $p->get_column('name'),

                questions => [
                    map {
                        my $q = $_;

                        +{
                            id      => $q->get_column('id'),
                            content => $q->get_column('content'),

                            options => [
                                map {
                                    my $o = $_;

                                    +{
                                        id      => $o->get_column('id'),
                                        content => $o->get_column('content')
                                    }
                                } $q->poll_question_options->all()
                            ]
                        }
                    } $p->poll_questions->all()
                ]
            },
        } $politician->polls->search(
            { 'me.status_id' => 1 },
            { prefetch => [ 'poll_questions', { 'poll_questions' => "poll_question_options" }, 'politician' ] }
          )->all()
    );
}

1;
