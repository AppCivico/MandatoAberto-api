package MandatoAberto::Controller::Chatbot::Politician;
use Mojo::Base 'MandatoAberto::Controller';

sub stasher {
    my $c = shift;

    $c->stash( collection => $c->schema->resultset('Politician') );

    my $platform = $c->param('platform') || 'fb';
    die \['platform', 'invalid'] unless $platform =~ m/^(fb|twitter)$/;

    my ($politician, $page_id, $cond);
    if ( $platform eq 'fb' ) {

        $page_id = $c->req->params->to_hash->{fb_page_id};
        die \["fb_page_id", "missing"] unless $page_id;

        $politician = $c->stash('collection')->search( { fb_page_id => $page_id } )->next;
        die \['fb_page_id', 'could not find politician with that fb_page_id'] unless $politician;

        $cond = 'fb_page_id';
    }
    else {

        $page_id = $c->req->params->to_hash->{twitter_id};
        die \['twitter_id', 'missing'] unless $page_id;

        $politician = $c->stash('collection')->search( { twitter_id => $page_id } )->next;
        die \['twitter_id', 'could not find politician with that twitter_id'] unless $politician;

        $cond = 'twitter_id';
    }

    $c->stash(
        platform => {
            name                => $platform,
            rs_search_condition => $cond,
            rs_search_value     => $page_id
        },
        politician => $politician,
        collection => $c->stash('collection')->search_rs(
            { user_id => $politician->user_id },
            { prefetch => [ qw/politician_contacts party office /, { 'politicians_greeting' => 'greeting' } ] }
        )
    );
}

sub get {
    my $c = shift;

    my $politician = $c->stash('politician');

    my $politician_greeting = $politician->politicians_greeting->next;

    return $c->render(
        status => 200,
        json   => map {
            my $p = $_;

            +{
                user_id        => $p->get_column('user_id'),
                name           => $p->get_column('name'),
                gender         => $p->get_column('gender'),
                address_city   => $p->get_column('address_city_id'),
                address_state  => $p->get_column('address_state_id'),
                picframe_url   => $p->get_column('share_url'),
                picframe_text  => $p->get_column('share_text'),

                share => {
                    url  => $p->get_column('share_url'),
                    text => $p->get_column('share_text')
                },

                (
                    $c->stash('platform') eq 'fb' ?
                    (
                        fb_access_token => $p->get_column('fb_page_access_token')
                    ) :
                    (
                        twitter_oauth_token  => $p->get_column('twitter_oauth_token'),
                        twitter_token_secret => $p->get_column('twitter_token_secret')
                    )
                ),

                ( $politician->has_votolegal_integration ?
                (
                    votolegal_integration => {
                        map {
                            my $vl = $_;

                            my $url;
                            if ( $vl->custom_url ) {
                                $url = $vl->custom_url
                            }
                            else {
                                $url = $vl->website_url;
                            }

                            votolegal_username => $vl->get_column("username"),
                            votolegal_url      => $url . '?ref=mandatoaberto#doar',
                        } $p->politician_votolegal_integrations->all()
                    }
                ) : ()
                ),

                party => {
                    name    => $p->party->get_column('name'),
                    acronym => $p->party->get_column('acronym'),
                },
                office => {
                    name => $p->office->get_column('name'),
                },
                contact => {
                    map {
                        my $c = $_;

                        cellphone => $c->get_column('cellphone'),
                        email     => $c->get_column('email'),
                        facebook  => $c->get_column('facebook'),
                        url       => $c->get_column('url'),
                        twitter   => $c->get_column('twitter'),
                    } $p->politician_contacts->all()
                },
                greeting => $politician_greeting ? $politician_greeting->on_facebook : undef
            }

        } $c->stash('collection')->search(undef)

    );
}

1;
