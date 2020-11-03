package MandatoAberto::Controller::API::Chatbot::Politician;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

sub root : Chained('/api/chatbot/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('politician') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{collection} = $c->model('DB::Politician');
}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $politician_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { user_id => $politician_id } );

    my $politician = $c->stash->{collection}->find($politician_id);
    $c->detach("/error_404") unless ref $politician;

    $c->stash->{politician} = $politician;
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    my $organization_chatbot;
    if (my $page_id = $c->req->params->{fb_page_id}) {
        my $chatbot_config = $c->model('DB::OrganizationChatbotFacebookConfig')->search( { page_id => $page_id } )->next
          or die \['fb_page_id', 'could not find politician with that fb_page_id'];

        $organization_chatbot = $chatbot_config->organization_chatbot;
    }
    elsif (my $organization_chatbot_id = $c->req->params->{chatbot_id}) {

        $organization_chatbot = $c->model('DB::OrganizationChatbot')->find($organization_chatbot_id)
          or die \['chatbot_id', 'invalid'];
    }
    else {
        die \['fb_page_id', 'missing'];
    }

    my $user       = $organization_chatbot->organization->users->next;
    my $politician = $user->user->politician;

    return $self->status_ok(
        $c,
        entity => {
            user_id                 => $user->user->id,
            id                      => $user->user->id,
            name                    => $user->user->name,
            use_dialogflow          => $organization_chatbot->general_config->use_dialogflow,
            issue_active            => $organization_chatbot->general_config->issue_active,
            organization_chatbot_id => $organization_chatbot->id,
            chatbot_picture         => $organization_chatbot->picture,
            answers                 => [
                map {
                    my $a = $_;

                    +{
                        code    => $a->organization_question->name,
                        content => $a->content
                    }
                } $organization_chatbot->answers->search( { 'me.active' => 1 } )->all()
            ],

            ( $organization_chatbot->fb_config ? ( fb_access_token => $organization_chatbot->fb_config->access_token ) : ( ) )
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
