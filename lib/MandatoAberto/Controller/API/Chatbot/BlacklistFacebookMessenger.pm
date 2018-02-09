package MandatoAberto::Controller::API::Chatbot::BlacklistFacebookMessenger;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoListPOST";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::BlacklistFacebookMessenger",

    prepare_params_for_create => sub {
        my ($self, $c, $params) = @_;

        my $fb_id = $c->req->params->{fb_id};
        die ["fb_id", "missing"] unless $fb_id;

        my $recipient_id = $c->model("DB::Recipient")->search( fb_id => $fb_id )->next;
        die ["fb_id", "could not find recipient with that fb_id"] unless $recipient_id;

        $params->{recipient_id} = $recipient_id;

        return $params;
    },
);

sub root : Chained('/api/chatbot/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('blacklist') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST { }

sub list_GET {
    my ($self, $c) = @_;

    my $recipient_fb_id = $c->req->params->{fb_id};
    die \["fb_id", "missing"] unless $recipient_fb_id;

    my $recipient = $c->model("DB::Recipient")->search( { fb_id => $recipient_fb_id } )->next;
    die \["fb_id", "could not find recipient with that fb_id"] unless $recipient;

    my $blacklist_entry = $c->stash->{collection}->search( { recipient_id => $recipient->id } )->next;

    return $self->status_ok(
        $c,
        entity => {
            opt_in => $blacklist_entry ? 0 : 1
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;