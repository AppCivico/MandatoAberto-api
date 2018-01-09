package MandatoAberto::Controller::API::Politician::Dashboard;
use Moose;
use namespace::autoclean;

use utf8;
use Furl;
use JSON::MaybeXS;
use DateTime;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Politician",
);

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('dashboard') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    my $politician_id = $c->stash->{politician}->id;

    my $citizen_count = $c->model("DB::Citizen")->search( { politician_id => $politician_id } )->count;

    my $ever_had_poll = $c->model("DB::Poll")->search( { politician_id => $politician_id } )->count > 0 ? 1 : 0;

    # Sempre haverá apenas uma única enquete ativa 't/polls/000-register.t'
    # logo posso apenas contar quantas enquetes ativas (status_id 1) existem
    my $active_poll = $c->model("DB::Poll")->search(
        {
            politician_id => $politician_id,
            status_id     => 1
        },
        { prefetch => [ 'poll_questions' , { 'poll_questions' => { "question_options" => 'poll_results' } } ] }
    )->next;

    my $last_active_poll;
    if ($ever_had_poll && !$active_poll) {
        $last_active_poll = $c->model("DB::Poll")->search(
            {
                politician_id => $politician_id,
                status_id     => 3,
            },
            {
                order_by => { -desc => qw/updated_at/ },
                prefetch => [ 'poll_questions' , { 'poll_questions' => { "question_options" => 'poll_results' } } ]
            }
        )->next;
    }

    my $has_greeting      = $c->model("DB::PoliticianGreeting")->search( { politician_id => $politician_id } )->count;
    my $has_contacts      = $c->model("DB::PoliticianContact")->search( { politician_id => $politician_id } )->count;
    my $has_dialogs       = $c->model("DB::Answer")->search( { politician_id => $politician_id } )->count > 0 ? 1 : 0;
    my $has_facebook_auth = $c->stash->{politician}->fb_page_access_token ? 1 : 0;

    # Dados de genero
    my $female_citizen_count = $c->model("DB::Citizen")->search(
        {
            politician_id => $politician_id,
            gender        => 'F'
        }
    )->count;

    my $male_citizen_count = $c->model("DB::Citizen")->search(
        {
            politician_id => $politician_id,
            gender        => 'M'
        }
    )->count;

    my $citizen_gender = {
        name   => "Gênero",
        labels => [ 'F', 'M' ],
        data   => [ $female_citizen_count, $male_citizen_count ]
    };

    # Pegando dados do analytics do Facebook
    my $range = $c->req->params->{range};
    $range = 8 if !$range;
    die \["range", 'invalid'] if $range !~ m/^(8|16|31)/;

    my $citizen_interaction;
    if ($has_facebook_auth) {
        $citizen_interaction = $c->stash->{politician}->get_citizen_interaction($range);
    }

    return $self->status_ok(
        $c,
        entity => {
            citizens => $citizen_count,

            has_greeting        => $has_greeting,
            has_contacts        => $has_contacts,
            has_dialogs         => $has_dialogs,
            has_facebook_auth   => $has_facebook_auth,
            has_active_poll     => $active_poll ? 1 : 0,
            ever_had_poll       => $ever_had_poll,
            citizen_interaction => $citizen_interaction,
            citizen_gender      => $citizen_gender,

            poll => $active_poll ?
                    map {
                        my $p = $_;

                        {
                            id        => $p->get_column('id'),
                            name      => $p->get_column('name'),

                            questions => [
                                map {
                                    my $q = $_;

                                    +{
                                        content => $q->get_column('content'),

                                        options => [
                                            map {
                                                my $o = $_;

                                                +{
                                                    id      => $o->get_column('id'),
                                                    content => $o->get_column('content'),
                                                    count   => $o->poll_results->search()->count,
                                                }
                                            } $q->question_options->all()
                                        ]
                                    }
                                } $p->poll_questions->all()
                            ]
                        }
                    } $active_poll
                :
                (
                    $last_active_poll ?

                            map {
                                my $p = $_;

                                {
                                    id        => $p->get_column('id'),
                                    name      => $p->get_column('name'),

                                    questions => [
                                        map {
                                            my $q = $_;

                                            +{
                                                content => $q->get_column('content'),

                                                options => [
                                                    map {
                                                        my $o = $_;

                                                        +{
                                                            id      => $o->get_column('id'),
                                                            content => $o->get_column('content'),
                                                            count   => $o->poll_results->search()->count,
                                                        }
                                                    } $q->question_options->all()
                                                ]
                                            }
                                        } $p->poll_questions->all()
                                    ]
                                }
                            } $last_active_poll
                        :
                        { }
                )
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;