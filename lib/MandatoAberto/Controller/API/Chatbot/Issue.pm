package MandatoAberto::Controller::API::Chatbot::Issue;
use common::sense;
use Moose;
use namespace::autoclean;

use JSON;
use Encode;

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
        my $recipient_id    = $c->req->params->{recipient_id};
        die \["fb_id", "missing"] unless $recipient_fb_id || $recipient_id;

        my $recipient = $c->model("DB::Recipient")->search( { ($recipient_fb_id ? (fb_id => $recipient_fb_id) : (id => $recipient_id) ) } )->next;
        die \["fb_id", "could not find recipient with that fb_id"] unless $recipient;

        $params->{recipient_id} = $recipient->id;

        my $entities = $c->req->params->{entities};

        if ( $entities && $entities ne '{}' ) {
            $entities = decode_json(Encode::encode_utf8($entities)) or die \['entities', 'could not decode json'];

            my @required_json_fields = qw (queryText intent);
            die \['entities', "missing 'queryResult' param"] unless $entities->{queryResult};

            for (@required_json_fields) {
                die \['entities', "missing '$_' param"] unless $entities->{queryResult}->{$_}
            }

            $params->{entities} = $entities;
        }

        $params->{entities} = undef if $params->{entities} && $params->{entities} eq '{}';

        return $params;
    },
);

sub root : Chained('/api/chatbot/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('issue') : CaptureArgs(0) {  }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST { }

__PACKAGE__->meta->make_immutable;

1;