package MandatoAberto::Controller::API::Politician::Dashboard;
use Moose;
use namespace::autoclean;

use MandatoAberto::Utils qw( get_metric_name_for_dashboard get_metric_text_for_dashboard );
with "CatalystX::Eta::Controller::TypesValidation";

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

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->detach("/api/forbidden") unless $c->stash->{is_me};

    eval { $c->assert_user_roles(qw/politician/) };
    if ($@) {
        $c->forward("/api/forbidden");
    }
}

sub base : Chained('root') : PathPart('dashboard') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    my $politician = $c->stash->{politician};

    my $recipients = $politician->recipients;

    my $ever_had_poll = $politician->polls->count > 0 ? 1 : 0;

    my $active_poll = $politician->polls->get_active_politician_poll_with_data;

    my $last_active_poll;
    if ($ever_had_poll && !$active_poll) {
        $last_active_poll = $politician->polls->search(
            { status_id => 3 },
            {
                order_by => { -desc => qw/updated_at/ },
                prefetch => [ 'poll_questions' , { 'poll_questions' => { "poll_question_options" => 'poll_results' } } ]
            }
        )->next;
    }

    my $has_greeting      = $politician->politicians_greeting->count;
    my $has_contacts      = $politician->politician_contacts->count;
    my $has_dialogs       = $politician->user->chatbot->answers->count > 0 ? 1 : 0;
    my $has_facebook_auth = $politician->fb_page_access_token ? 1 : 0;

    my $first_access = $politician->user->user_sessions->count > 1 ? 0 : 1;

    # Dados de genero
    # my $recipients_by_gender = $politician->recipients->get_recipient_by_gender;

    # my $citizen_gender = {
    #     name     => "Gênero",
    #     title    => "Gênero",
    #     subtitle => "Número de pessoas por gênero",
    #     labels   => [ 'Feminino', 'Masculino' ],
    #     data     => [ $recipients_by_gender->{female_recipient_count}, $recipients_by_gender->{male_recipient_count} ]
    # };

    # Pegando dados do analytics do Facebook
    # my $range = $c->req->params->{range};
    # $range = 8 if !$range;
    # die \["range", 'invalid'] if $range !~ m/^(8|16|31)/;

    # my $citizen_interaction;
    # if ($has_facebook_auth) {
    #     $citizen_interaction = $politician->get_citizen_interaction($range);
    # }

    my $issues       = $politician->issues;
    my $campaigns    = $politician->campaigns;
    my $groups       = $politician->groups->search( { deleted => 0 } );
    my $polls        = $politician->polls;
    my $poll_results = $recipients->get_recipients_poll_results;

    my $issue_response_view = $c->model('DB::ViewAvgIssueResponseTime')->search( undef, { bind => [ $politician->user->organization_chatbot_id ] } )->next;

    # Condição para puxar dados dos últimos 7 dias
    my $last_week_issue_response_view = $c->model('DB::ViewAvgIssueResponseTimeLastWeek')->search( undef, { bind => [ $politician->user->organization_chatbot_id ] } )->next;
    my $last_week_cond = { created_at => { '>=' => \"NOW() - interval '7 days'" } };

    my $last_week_issues     = $issues->search( $last_week_cond );
    my $last_week_recipients = $recipients->search($last_week_cond);
    my $last_week_campaigns  = $campaigns->search($last_week_cond);

    return $self->status_ok(
        $c,
        entity => {
            first_access        => $first_access,
            has_greeting        => $has_greeting,
            has_contacts        => $has_contacts,
            has_dialogs         => $has_dialogs,
            has_facebook_auth   => $has_facebook_auth,
            has_active_poll     => $active_poll ? 1 : 0,
            ever_had_poll       => $ever_had_poll,
            # citizen_interaction => $citizen_interaction,
            # citizen_gender      => $citizen_gender,
            # group_count         => $group_count,
            last_week_data => {
                issues => {
                    avg_response_time => $issue_response_view ? $issue_response_view->avg_response_time : 0,
                    count             => $last_week_issues->count,
                    count_open        => $last_week_issues->search( { open => 1 } )->count,
                    count_ignored     => $last_week_issues->search( { open => 0, reply => \'IS NULL' } )->count,
                },
                recipients => {
                    count => $last_week_recipients->count
                },
                campaigns => {
                    count                => $last_week_campaigns->count,
                    count_direct_message => $last_week_campaigns->search( { type_id => 1 } )->count,
                    count_poll_propagate => $last_week_campaigns->search( { type_id => 2 } )->count
                }
            },
            recipients => {
                count                          => $recipients->count,
                count_with_email               => $recipients->search( { email => \'IS NOT NULL' } )->count,
                count_with_cellphone           => $recipients->search( { cellphone => \'IS NOT NULL' } )->count,
                count_facebook                 => $recipients->search( { platform => 'facebook' } )->count,
                count_twitter                  => $recipients->search( { platform => 'twitter' } )->count,
                count_segmented_recipients     => $recipients->search( { groups => { '!=' => '' } } )->count,
                count_non_segmented_recipients => $recipients->search( { groups => '' } )->count,
            },
            issues => {
                count                    => $issues->count(),
                count_open               => $issues->get_politician_open_issues->count,
                count_ignored            => $issues->search( { open => 0, reply => \'IS NULL' } )->count,
                count_replied            => $issues->search( { open => 0, reply => \'IS NOT NULL' } )->count,
                count_open_last_24_hours => $issues->get_open_issues_created_today->count,
                avg_response_time        => $issue_response_view ? $issue_response_view->avg_response_time : 0,
            },
            campaigns => {
                count                => $politician->campaigns->count,
                count_direct_message => $politician->campaigns->search( { type_id => 1 } )->count,
                count_poll_propagate => $politician->campaigns->search( { type_id => 2 } )->count,

                reach                => $politician->campaigns->get_politician_campaign_reach_count(),
                reach_direct_message => $politician->campaigns->get_politician_campaign_reach_dm_count(),
                reach_poll_propagate => $politician->campaigns->get_politician_campaign_reach_poll_propagate_count(),
            },
            groups => {
                count                => $groups->count,
                count_all_recipients => $recipients->count,
                count_empty          => $groups->search( { recipients_count => 0 } )->count,
                count_populated      => $groups->search( { recipients_count => { '!=' => 0 } } )->count,

                top_3_groups_by_recipients => [
                    map {
                        my $g = $_;

                        {
                            id              => $g->id,
                            name            => $g->name,
                            recipient_count => $g->recipients_count
                        }
                    } $groups->get_groups_ordered_by_recipient_count->all()
                ]
            },
            polls => {
                count                => $polls->count,
                count_propagated     => $politician->poll_propagates->count,
                count_non_propagated => $polls->get_non_propagated_polls( $politician->user_id )->count,

                # reach            => $poll_results->count,
                # reach_dialog     => $poll_results->search( { 'poll_results.origin' => 'dialog' } )->count,
                # reach_propagated => $poll_results->search( { 'poll_results.origin' => 'propagate' } )->count
            }

        }
    );
}

sub list_new : Chained('base') : PathPart('new') : Args(0) : ActionClass('REST') { }

sub list_new_GET {
    my ($self, $c) = @_;

	$self->validate_request_params(
		$c,
		range => {
			type     => 'Int',
			required => 0,
		},
	);

    my $range = $c->req->params->{range};

    my $politician = $c->stash->{politician};

    my @relations = qw( issues campaigns groups recipients politician_entities );

    my $recipients = $politician->recipients;

    my $has_facebook_auth = $politician->fb_page_access_token ? 1 : 0;

    my $first_access = $politician->user->user_sessions->count > 1 ? 0 : 1;

	my $facebook_active_page = {};
	if ($politician->fb_page_id) {
		$facebook_active_page = $politician->get_current_facebook_page();
	}

    return $self->status_ok(
        $c,
        entity => {
            first_access         => $first_access,
            has_facebook_auth    => $has_facebook_auth,
            facebook_active_page => $facebook_active_page,

			metrics => [
				map {
					my $r = $_;

					my $metrics = $politician->$r->extract_metrics(range => $range, politician_id => $politician->user_id);

					+{
						name => get_metric_name_for_dashboard($_),
						text => get_metric_text_for_dashboard($_),
						%$metrics,
					}
				} @relations
			]
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
