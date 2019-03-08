package MandatoAberto::Controller::API::Chatbot::Politician;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

sub root : Chained('/api/chatbot/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('politician') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{collection} = $c->model('DB::Politician');
}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $politician_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { user_id => $politician_id } );

    my $politician = $c->stash->{collection}->find($politician_id);
    $c->detach("/error_404") unless ref $politician;

    $c->stash->{politician} = $politician;
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    my $page_id = $c->req->params->{fb_page_id};
    die \["fb_page_id", "missing"] unless $page_id;

    my $chatbot_config = $c->model('DB::OrganizationChatbotFacebookConfig')->search( { page_id => $page_id } )->next
    or die \['fb_page_id', 'could not find politician with that fb_page_id'];

    my $organization_chatbot = $chatbot_config->organization_chatbot;
    my $user                 = $organization_chatbot->organization->users->next;
    my $politician           = $user->user->politician;

    my $politician_greeting = $politician->user->organization_chatbot->politicians_greeting->next;

    return $self->status_ok(
        $c,
        entity =>
            map {
                my $p = $_;

                +{
                    user_id        => $p->get_column('user_id'),
                    id             => $p->get_column('user_id'),
                    name           => $p->get_column('name'),
                    gender         => $p->get_column('gender'),
                    address_city   => $p->get_column('address_city_id'),
                    address_state  => $p->get_column('address_state_id'),
                    picframe_url   => $p->get_column('share_url'),
                    picframe_text  => $p->get_column('share_text'),
                    use_dialogflow => $p->user->organization->chatbot->general_config->use_dialogflow,
                    issue_active   => $p->user->chatbot->general_config->issue_active,

                    organization_chatbot_id => $p->user->organization_chatbot_id,

                    share => {
                        url  => $p->get_column('share_url'),
                        text => $p->get_column('share_text')
                    },

                    (
                        fb_access_token => $p->get_column('fb_page_access_token')
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

                    (
                        $p->party ?
                        (
                            party => {
                                name    => $p->party->get_column('name'),
                                acronym => $p->party->get_column('acronym'),
                            },
                        ) : ( )
                    ),
                    (
                        $p->office ?
                        (
                            office => {
                                name => $p->office->get_column('name'),
                            },
                        ) : ( )
                    ),
                    contact => {
                        map {
                            my $c = $_;

                            cellphone => $c->get_column('cellphone'),
                            email     => $c->get_column('email'),
                            facebook  => $c->get_column('facebook'),
                            url       => $c->get_column('url'),
                            twitter   => $c->get_column('twitter'),
                        } $p->user->organization_chatbot->politician_contacts->search( { 'me.active' => 1 } )->all()
                    },
                    greeting => $politician_greeting ? $politician_greeting->on_facebook : undef
                }

            } $c->stash->{collection}->search(
                { fb_page_id => $page_id },
                { prefetch => [ qw/party office / ] }
            )
    )
}

__PACKAGE__->meta->make_immutable;

1;
