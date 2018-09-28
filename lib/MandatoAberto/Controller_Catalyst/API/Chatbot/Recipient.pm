package MandatoAberto::Controller::API::Chatbot::Recipient;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoListPOST";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Recipient",
    no_user => 1,

    list_key => "recipient",
    build_row  => sub {
        return { $_[0]->get_columns() };
    },

    # AutoResultPUT.
    object_key     => "recipient",
    result_put_for => "update",

    prepare_params_for_create => sub {
        my ($self, $c, $params) = @_;

        my $platform = $c->req->params->{platform} || 'facebook';
        die \['platform', 'invalid'] unless $platform =~ m/^(facebook|twitter)$/;

        my ( $id_param, $recipient_id );
        if ( $platform eq 'facebook' ) {
            $recipient_id = $c->req->params->{fb_id};
            die \["fb_id", "missing"] unless $recipient_id;

            $id_param = 'fb_id';
        }
        else {
            $recipient_id = $c->req->params->{twitter_id};
            die \["twitter_id", "missing"] unless $recipient_id;

            $id_param = 'twitter_id';
        }

        # TODO não aceitar politician_id
        my $politician_id = $c->req->params->{politician_id};
        die \["politician_id", "missing"] unless $politician_id;

        my $politician = $c->model("DB::Politician")->find($politician_id);
        die \["politician_id", 'could not find politician with that id'] unless $politician;

        $params->{platform}          = $platform;
        $params->{politician_id}     = $politician_id;
        $params->{"$id_param"}       = $recipient_id;
        $params->{page_id}           = $platform eq 'facebook' ? $politician->fb_page_id : $politician->twitter_id;
        $params->{twitter_origin_id} = $platform eq 'twitter' ? $politician->twitter_id : ();

        return $params;
    },
);

sub root : Chained('/api/chatbot/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('recipient') : CaptureArgs(0) {  }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST { }

sub list_GET {
    my ($self, $c) = @_;

    my $fb_id = $c->req->params->{fb_id};
    die \['fb_id', 'missing'] unless $fb_id;

    return $self->status_ok(
        $c,
        entity => {
            map {
                my $c = $_;

                id                     => $c->get_column('id'),
                gender                 => $c->get_column('gender'),
                email                  => $c->get_column('email'),
                cellphone              => $c->get_column('cellphone'),
                poll_notification_sent => $c->poll_notification ? $c->poll_notification->sent : 0,
            } $c->stash->{collection}->search( { fb_id => $fb_id } )->next
        }
    )
}

__PACKAGE__->meta->make_immutable;

1;
