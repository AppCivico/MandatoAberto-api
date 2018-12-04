package MandatoAberto::Controller::API::Chatbot::Poll;
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

sub base : Chained('root') : PathPart('poll') : CaptureArgs(0) {  }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    my $platform = $c->req->params->{platform} || 'facebook';
    die \['platform', 'invalid'] unless $platform =~ m/(facebook|twitter)/;

    my ( $page_id, $page_id_param );
    if ( $platform eq 'facebook' ) {
        $page_id_param = 'organization_chatbot_facebook_config.access_token';
        $page_id       = $c->req->params->{fb_page_id};
        die \["fb_page_id", "missing"] unless $page_id;
    }
    else {
        $page_id_param = 'politician.twitter_id';
        $page_id       = $c->req->params->{twitter_id};
        die \["twitter_id", "missing"] unless $page_id;
    }
    use DDP; p $c->model('DB::OrganizationChatbotFacebookConfig')->next;
    return $self->status_ok(
        $c,
        entity => {
            map {
                my $p = $_;
                use DDP; p $p;
                id        => $p->get_column('id'),
                name      => $p->get_column('name'),

                questions => [
                    map {
                        my $q = $_;

                        +{
                            id      => $q->get_column('id'),
                            content => $q->get_column('content'),

                            options => [
                                map {
                                    my $o = $_;

                                    +{
                                        id      => $o->get_column('id'),
                                        content => $o->get_column('content')
                                    }
                                } $q->poll_question_options->all()
                            ]
                        }
                    } $p->poll_questions->all()
                ],
            } $c->model("DB::Poll")->search(
                {
                    "$page_id_param" => $page_id,
                    status_id        => 1
                },
                { prefetch => [ 'poll_questions', { 'poll_questions' => "poll_question_options" }, { 'organization_chatbot' => 'organization_chatbot_facebook_config' } ] }
            )
        }
    )
}

__PACKAGE__->meta->make_immutable;

1;
