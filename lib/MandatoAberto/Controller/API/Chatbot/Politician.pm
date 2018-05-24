package MandatoAberto::Controller::API::Chatbot::Politician;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::PoliticianChatbot",
);

sub root : Chained('/api/chatbot/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('politician') : CaptureArgs(0) {  }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    my $page_id = $c->req->params->{fb_page_id};
    die \["fb_page_id", "missing"] unless $page_id;

    my $politician = $c->model("DB::Politician")->search( { fb_page_id => $page_id } )->next;

    return $self->status_ok(
        $c,
        entity => {
            map {
                my $p = $_;

                user_id               => $p->get_column('user_id'),
                name                  => $p->get_column('name'),
                gender                => $p->get_column('gender'),
                address_city          => $p->get_column('address_city_id'),
                address_state         => $p->get_column('address_state_id'),
                fb_access_token       => $p->get_column('fb_page_access_token'),

                votolegal_integration => {
                    map {
                        my $vl = $_;

                        votolegal_username => $vl->get_column("username"),
                        votolegal_url      => $vl->get_column("website_url")
                    } $p->politician_votolegal_integrations->all()
                },

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
                greeting =>
                    map {
                        my $g = $_;

                        $g->greeting->get_column('content');
                    } $p->politicians_greeting->all()

            } $c->model("DB::Politician")->search(
                { fb_page_id => $page_id },
                { prefetch => [ qw/politician_contacts party office /, { 'politicians_greeting' => 'greeting' } ] }
            )
        }
    )
}

__PACKAGE__->meta->make_immutable;

1;