package MandatoAberto::Controller::API::Chatbot::PrivateReply;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoListPOST";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::PrivateReply",
    no_user => 1,

    prepare_params_for_create => sub {
        my ($self, $c, $params) = @_;

        my $page_id = $c->req->params->{page_id};
        die \["page_id", "missing"] unless $page_id;

        my $politician = $c->model("DB::Politician")->search( { fb_page_id => $page_id } )->next;
        die \["page_id", "could not find politician with that page id"] unless $politician;

        $params->{politician_id} = $politician->id;

        return $params;
    },
);

sub root : Chained('/api/chatbot/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('private-reply') : CaptureArgs(0) {  }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST { }

__PACKAGE__->meta->make_immutable;

1;