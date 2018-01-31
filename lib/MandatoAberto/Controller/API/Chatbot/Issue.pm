package MandatoAberto::Controller::API::Chatbot::Issue;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoListPOST";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Issue",
    no_user => 1,

    prepare_params_for_create => sub {
        my ($self, $c, $params) = @_;

        my $recipient_fb_id = $c->req->params->{fb_id};
        die \["fb_id", "missing"] unless $recipient_fb_id;

        my $recipient = $c->model("DB::Recipient")->search( { fb_id => $recipient_fb_id } )->next;
        die \["fb_id", "could not find recipient with that fb_id"] unless $recipient;

        $params->{recipient_id} = $recipient->id;

        my $page_id = $c->req->params->{page_id};
        die \["page_id", "missing"] unless $page_id;

        my $politician = $c->model("DB::politician")->search( { fb_page_id => $page_id } )->next;
        die \["page_id", "could not find politician with that page_id"] unless $politician;

        $params->{politician_id} = $politician->id;

        return $params;
    },
);

sub root : Chained('/api/chatbot/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('issue') : CaptureArgs(0) {  }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST { }

__PACKAGE__->meta->make_immutable;

1;