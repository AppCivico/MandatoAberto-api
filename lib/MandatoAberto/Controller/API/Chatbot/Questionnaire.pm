package MandatoAberto::Controller::API::Chatbot::Questionnaire;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::TypesValidation";

sub root : Chained('/api/chatbot/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('questionnaire') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $self->validate_request_params(
        $c,
        type => {
            type     => "Str",
            required => 1,
        },
        fb_id => {
            type     => 'Str',
            required => 1
        }
    );

    my $recipient = $c->model("DB::Recipient")->search( { fb_id => $c->req->params->{fb_id} } )->next;
    die \["fb_id", "could not find recipient with that fb_id"] unless $recipient;

    $c->stash->{recipient} = $recipient;

    my $type = $c->model("DB::QuestionnaireType")->search( { name => $c->req->params->{type} } )->next
        or die \['type', 'invalid'];

    my $latest_questionnaire = $c->model('DB::QuestionnaireMap')->search(
        { 'me.type_id' => $type->id },
        { order_by => { -desc => 'created_at' } }
    )->next;

    $c->stash->{collection} = $c->model("DB::QuestionnaireStash")->search_rs(
        {
            'me.recipient_id'         => $recipient->id,
            'me.questionnaire_map_id' => $latest_questionnaire->id
        },
    );

    if ( $c->stash->{collection}->count == 0 ) {

        $c->stash->{questionnaire_stash} = $c->stash->{collection}->create(
            {
                recipient_id         => $recipient->id,
                questionnaire_map_id => $latest_questionnaire->id,
                value                => $latest_questionnaire->map
            }
        );
    }
    else {
        $c->stash->{questionnaire_stash} = $c->stash->{collection}->next;
    }
}

__PACKAGE__->meta->make_immutable;

1;
