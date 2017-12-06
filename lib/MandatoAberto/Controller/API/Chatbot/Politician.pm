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

    my $politician_chatbot = $c->stash->{collection}->find($c->user->id);

    return $self->status_ok(
        $c,
        entity => {
            map {
                my $p = $_;

                user_id       => $p->get_column('user_id'),
                name          => $p->get_column('name'),
                gender        => $p->get_column('gender'),
                address_city  => $p->get_column('address_city'),
                address_state => $p->get_column('address_state'),
                party         => {
                    name    => $p->party->get_column('name'),
                    acronym => $p->party->get_column('acronym'),
                },
                office        => {
                    name => $p->office->get_column('name'),
                },
                contact       => {
                    map {
                        my $c = $_;

                        cellphone => $c->get_column('cellphone'),
                        email     => $c->get_column('email'),
                        facebook  => $c->get_column('facebook'),
                        twitter   => $c->get_column('twitter'),
                    } $p->politician_contacts->all()
                },
                greeting       =>
                    map {
                        my $g = $_;

                        $g->get_column('text')
                    } $p->politicians_greeting->all()

            } $c->model("DB::Politician")->search(
                { user_id  => $politician_chatbot->politician_id },
                { prefetch => [ qw/politician_contacts politicians_greeting party office/ ] }
            )
        }
    )
}

__PACKAGE__->meta->make_immutable;

1;