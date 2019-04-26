package MandatoAberto::Controller::Organization::Chatbot::Recipient;
use Mojo::Base 'MandatoAberto::Controller';

sub load {
	my $c = shift;

	my $recipient_id = $c->param('recipient_id');
	my $recipient    = $c->schema->resultset('Recipient')->search( { 'me.id' => $recipient_id } )->next;

    if (!ref $recipient) {
		$c->reply_not_found;
		$c->detach();
	}

	$c->stash(recipient => $recipient);

	return $c;
}

sub get {
    my $c = shift;

    my $chatbot = $c->stash('chatbot');

	my $page    = $c->req->params->{page}    || 1;
	my $results = $c->req->params->{results} || 20;


    return $c->render(
        status => 200,
        json   => {
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
                } $chatbot->recipients->search(
                    undef,
                    { page => $page, rows => $results }
                  )->all()
            ],
			itens_count => $chatbot->recipients->count
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
