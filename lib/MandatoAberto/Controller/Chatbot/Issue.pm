package MandatoAberto::Controller::Chatbot::Issue;
use Mojo::Base 'MandatoAberto::Controller';

use Encode;
use Mojo::JSON qw(decode_json);

sub post {
    my $c = shift;

    my $params = $c->req->params->to_hash;

    my $recipient_fb_id = $params->{fb_id};
    die \["fb_id", "missing"] unless $recipient_fb_id;

    my $recipient = $c->schema->resultset('Recipient')->search( { 'me.fb_id' => $recipient_fb_id } )->next;
    die \["fb_id", "could not find recipient with that fb_id"] unless ref $recipient;

    $params->{recipient_id} = $recipient->id;

    my $entities = $params->{entities};

    if ( $entities && $entities ne '{}' ) {
        $entities = decode_json(Encode::encode_utf8($entities)) or die \['entities', 'could not decode json'];

        my @required_json_fields = qw (metadata resolvedQuery);
        die \['entities', "missing 'result' param"] unless $entities->{result};

        for (@required_json_fields) {
            die \['entities', "missing '$_' param"] unless $entities->{result}->{$_}
        }

        $params->{entities} = $entities;
    }

    $params->{entities} = undef if $params->{entities} && $params->{entities} eq '{}';

    my $issue = $c->schema->resultset('Issue')->execute(
        $c,
        for  => 'create',
        with => $params,
    );

    return $c
    ->redirect_to(undef) # TODO
    ->render(
        status => 201,
        json   => { id => $issue->id }
    );
}

1;
