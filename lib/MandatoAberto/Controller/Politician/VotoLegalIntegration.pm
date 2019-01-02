package MandatoAberto::Controller::Politician::VotoLegalIntegration;
use Mojo::Base 'Mojolicious::Controller';

use MandatoAberto::Utils qw/is_test/;

use Furl;
use JSON::MaybeXS;

sub post {
    my $c = shift;

    my $furl = Furl->new();

    my $security_token = $ENV{VOTOLEGAL_SECURITY_TOKEN};
    die \['missing env', 'VOTOLEGAL_SECURITY_TOKEN'] unless $security_token;

    my $votolegal_email = $c->req->params->to_hash->{votolegal_email};
    die \['votolegal_email', 'missing'] unless $votolegal_email;

    my $politician = $c->stash->{politician};
    die \['politician_id', 'no active fb_page_id for this politician'] unless $politician->fb_page_id;

    my $active = $c->req->params->to_hash->{active};
    $active = 1 unless defined $active;

    my $res;
    if ( is_test() ) {
        $res = $MandatoAberto::Test::votolegal_response;
    }
    else {
        $res = $furl->post(
            $ENV{VOTOLEGAL_API_URL} . '/candidate/mandatoaberto_integration',
            [],
            {
                active           => $active,
                page_id          => $politician->fb_page_id,
                security_token   => $security_token,
                email            => $votolegal_email,
                mandatoaberto_id => $politician->id,
                greeting         => $c->req->params->{greeting}
            }
        );
        die \['votolegal_email', 'non existent on voto legal'] unless $res->is_success;

        $res = decode_json $res->decoded_content;
    }

	die \['invalid response', 'id'] if !$res->{id} || !$res->{username};
	die \['invalid response', 'id'] if ref $res ne 'HASH';

    my $votolegal_integration = $c->schema->resultset('PoliticianVotolegalIntegration')->execute(
        $c,
        for  => 'create',
        with => {
            votolegal_id    => $res->{id},
            username        => $res->{username},
            custom_url      => $res->{custom_url},
            active          => $active,
            votolegal_email => $votolegal_email,
            politician_id   => $c->current_user->id,
        }
    );

	return $c->render(
		json   => { id => $votolegal_integration->id },
		status => 201,
	);
}

1;

