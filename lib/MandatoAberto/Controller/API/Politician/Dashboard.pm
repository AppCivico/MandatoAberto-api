package MandatoAberto::Controller::API::Politician::Dashboard;
use Moose;
use namespace::autoclean;

use MandatoAberto::Utils qw( get_metric_name_for_dashboard get_metric_text_for_dashboard empty_metric );
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

    eval { $c->assert_user_roles(qw/politician metrics_read/) };
    if ($@) {
        $c->forward("/api/forbidden");
    }
}

sub base : Chained('root') : PathPart('dashboard') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

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

    my @relations = qw( issues campaigns recipients politician_entities );

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

                    my $chatbot = $politician->user->organization_chatbot;

                    if ( $chatbot ) {
                        my $metrics = $chatbot->$r->extract_metrics(range => $range, politician_id => $politician->user_id);

                        +{
                            name => get_metric_name_for_dashboard($_),
                            text => get_metric_text_for_dashboard($_),
                            %$metrics,
                        }
                    }
                    else {
                        empty_metric($r)
                    }
                } @relations
            ]
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
