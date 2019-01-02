package MandatoAberto::Controller::Chatbot::Recipient;
use Mojo::Base 'MandatoAberto::Controller';

sub post {
    my $c = shift;

    my $params = $c->req->params->to_hash;

    my $platform = $params->{platform} || 'facebook';
    die \['platform', 'invalid'] unless $platform =~ m/^(facebook|twitter)$/;

    my ( $id_param, $recipient_id );
    if ( $platform eq 'facebook' ) {
        $recipient_id = $params->{fb_id};
        die \["fb_id", "missing"] unless $recipient_id;

        $id_param = 'fb_id';
    }
    else {
        $recipient_id = $params->{twitter_id};
        die \["twitter_id", "missing"] unless $recipient_id;

        $id_param = 'twitter_id';
    }

	my $politician_id = $params->{politician_id};
	die \["politician_id", "missing"] unless $politician_id;

	my $politician = $c->schema->resultset('Politician')->find($politician_id);
	die \["politician_id", 'could not find politician with that id'] unless $politician;

	$params->{platform}          = $platform;
	$params->{politician_id}     = $politician_id;
	$params->{"$id_param"}       = $recipient_id;
	$params->{page_id}           = $platform eq 'facebook' ? $politician->fb_page_id : $politician->twitter_id;
	$params->{twitter_origin_id} = $platform eq 'twitter' ? $politician->twitter_id : ();

    my $recipient = $c->schema->resultset('Recipient')->execute(
        $c,
        for  => 'create',
        with => $params
    );

	return $c
    ->redirect_to('current')
    ->render(
		json   => { id => $recipient->id },
		status => 201,
	);
}

sub get {
    my $c = shift;

	my $fb_id = $c->req->params->to_hash->{fb_id};
	die \['fb_id', 'missing'] unless $fb_id;

	return $c->render(
		status => 200,
		json   => map {
			my $c = $_;

            +{
                id                     => $c->get_column('id'),
                gender                 => $c->get_column('gender'),
                email                  => $c->get_column('email'),
                cellphone              => $c->get_column('cellphone'),
                poll_notification_sent => $c->poll_notification ? $c->poll_notification->sent : 0,
            }
		} $c->schema->resultset('Recipient')->search( { fb_id => $fb_id } )->next
    );
}

1;
