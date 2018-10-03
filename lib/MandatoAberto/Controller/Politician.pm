package MandatoAberto::Controller::Politician;
use Mojo::Base 'Mojolicious::Controller';

# __PACKAGE__->config(
#     # AutoBase.
#     result => "DB::Politician",

#     # AutoResultPUT.
#     object_key     => "politician",
#     result_put_for => "update",
#     prepare_params_for_update => sub {
#         my ($self, $c, $params) = @_;

#         my $share_url  = $c->req->params->{picframe_url}  || $c->req->params->{share_url};
#         my $share_text = $c->req->params->{picframe_text} || $c->req->params->{share_text};

#         $params->{share_url}  = $share_url;
#         $params->{share_text} = $share_text;

#         if ( (defined $c->req->params->{picframe_url} && $c->req->params->{picframe_url} eq '') || (defined $c->req->params->{share_url} && $c->req->params->{share_url} eq '') ) {
#             $params->{share_url} = 'SET_NULL';
#         }
# 		if ( (defined $c->req->params->{picframe_text} && $c->req->params->{picframe_text} eq '') || (defined $c->req->params->{share_text} && $c->req->params->{share_text} eq '') ) {
#             $params->{share_text} = 'SET_NULL';
# 		}

#         return $params;
#     },
# );

sub stuff {
    my $c = shift;

    my $politician = $c->schema->resultset('Politician')->search( { 'me.user_id' => $c->param('politician_id') } )->next;
    if (ref($politician)) {
        $c->stash(politician => $politician);
        return $c;
    };
    $c->reply_not_found;
    $c->detach();
}

sub get {
    my $c = shift;

    my $facebook_active_page = {};
    if ($c->stash('politician')->fb_page_id) {
        $facebook_active_page = $c->stash('politician')->get_current_facebook_page();
    }

    my $votolegal_integration = $c->stash('politician')->get_votolegal_integration if $c->stash('politician')->has_votolegal_integration;

    my $has_movement = $c->stash('politician')->movement ? 1 : 0;

    return $c->render(
        status => 200,
        json   => {
            (
                map { $_ => $c->stash('politician')->get_column($_) }
                qw/name gender premium twitter_id/
            ),
            picframe_url  => $c->stash('politician')->share_url,
            picframe_text => $c->stash('politician')->share_text,
            share_url     => $c->stash('politician')->share_url,
            share_text    => $c->stash('politician')->share_text,

            fb_page_id => $facebook_active_page ? $c->stash('politician')->fb_page_id : undef,

            ( $has_movement ? ( movement => { map { $_ => $c->stash('politician')->movement->$_ } qw/name id/  } ) : () ),

            ( state => { map { $_ => $c->stash('politician')->address_state->$_ } qw/name code/  } ),

            ( city => {map { $_ => $c->stash('politician')->address_city->$_ } qw/name id/}  ),

            ( party => { map { $_ => $c->stash('politician')->party->$_ } qw/acronym name id/ } ),

            ( office => { map { $_ => $c->stash('politician')->office->$_ } qw/id name/ } ),

            (
                contact => {
                    map {
                        my $contact = $_;

                        id        => $contact->get_column('id'),
                        twitter   => $contact->get_column('twitter'),
                        facebook  => $contact->get_column('facebook'),
                        email     => $contact->get_column('email'),
                        cellphone => $contact->get_column('cellphone'),
                        url       => $contact->get_column('url'),
                    } $c->schema->resultset('PoliticianContact')->search( { politician_id => $c->current_user->id } )
                }
            ),

            (
                greeting => {
                    map {
                        my $g = $_;

                        id          => $g->get_column('id'),
                        on_facebook => $g->get_column('on_facebook'),
                        on_website  => $g->get_column('on_website')
                    } $c->schema->resultset('PoliticianGreeting')->search(
                        { politician_id => $c->current_user->id },
                        { prefetch => 'greeting' }
                    )
                }
            ),

            ( map { $_ => $c->stash('politician')->user->get_column($_) } qw/id email approved created_at/ ),

            facebook_active_page => $facebook_active_page,

            ( $votolegal_integration ?
                (
                    votolegal_integration => {
                        votolegal_email => $votolegal_integration->votolegal_email,
                        greeting        => $votolegal_integration->greeting
                    }
                ) : ()
            )
        }
    );
}

sub result_PUT { }

1;
