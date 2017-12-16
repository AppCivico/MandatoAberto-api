package MandatoAberto::Controller::API::Chatbot::Citizen;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoListPOST";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Citizen",
    no_user => 1,

    list_key => "citizen",
    build_row  => sub {
        return { $_[0]->get_columns() };
    },

    # AutoResultPUT.
    object_key     => "citizen",
    result_put_for => "update",

    prepare_params_for_create => sub {
        my ($self, $c, $params) = @_;

        my $citizen_fb_id = $c->req->params->{fb_id};
        die \["fb_id", "missing"] unless $citizen_fb_id;

        my $politician = $c->model("DB::PoliticianChatbot")->find($c->user->id)->politician;

        $params->{politician_id} = $politician->user_id;
        $params->{fb_id}         = $citizen_fb_id;

        return $params;
    },
);

sub root : Chained('/api/chatbot/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('citizen') : CaptureArgs(0) {  }

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

                id        => $c->get_column('id'),
                gender    => $c->get_column('gender'),
                email     => $c->get_column('email'),
                cellphone => $c->get_column('cellphone'),
            } $c->stash->{collection}->search( { fb_id => $fb_id } )->next
        }
    )
}

__PACKAGE__->meta->make_immutable;

1;