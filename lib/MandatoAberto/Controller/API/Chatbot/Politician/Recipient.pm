package MandatoAberto::Controller::API::Chatbot::Politician::Recipient;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

sub root : Chained('/api/chatbot/politician/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('recipient') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{collection} = $c->model('DB::Recipient');
}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $recipient_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $recipient_id } );

    my $recipient = $c->stash->{collection}->find($recipient_id);
    $c->detach("/error_404") unless ref $recipient;

    $c->stash->{recipient} = $recipient;
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST {
    my ($self, $c) = @_;

    my $politician = $c->stash->{politician};

    my $platform = $c->req->params->{platform} || 'facebook';

    my ( $id_param, $recipient_id );
    if ( $platform eq 'facebook' ) {
        $recipient_id = $c->req->params->{fb_id};
        die \["fb_id", "missing"] unless $recipient_id;

        $id_param = 'fb_id';
    }
    else {
        $recipient_id = $c->req->params->{twitter_id};
        die \["twitter_id", "missing"] unless $recipient_id;

        $id_param = 'twitter_id';
    }

    my $politician_id = $c->req->params->{politician_id};
    die \["politician_id", "missing"] unless $politician_id;

    die \["politician_id", 'could not find politician with that id'] unless $politician_id == $c->stash->{politician}->id;

    $c->req->params->{platform}          = $platform;
    $c->req->params->{politician_id}     = $politician_id;
    $c->req->params->{"$id_param"}       = $recipient_id;
    $c->req->params->{page_id}           = $platform eq 'facebook' ? $politician->fb_page_id : $politician->twitter_id;
    $c->req->params->{twitter_origin_id} = $platform eq 'twitter' ? $politician->twitter_id : ();

    my $recipient = $c->stash->{collection}->execute(
        $c,
        for => 'create',
        with => $c->req->params
    );

	return $self->status_created(
		$c,
		location => $c->uri_for($c->controller('API::Chatbot::Politician::Recipient')->action_for('result'), [ $recipient->id ]),
		entity   => { id => $recipient->id }
	);
}

__PACKAGE__->meta->make_immutable;

1;