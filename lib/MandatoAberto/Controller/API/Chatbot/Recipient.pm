package MandatoAberto::Controller::API::Chatbot::Recipient;
use common::sense;
use Moose;
use namespace::autoclean;

use JSON;

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

        if ( $c->req->params->{chatbot_id} ) {
            my $chatbot = $c->model('DB::OrganizationChatbot')->find($c->req->params->{chatbot_id})
              or die \['chatbot_id', 'invalid'];

            $params->{page_id} = $chatbot->fb_config->page_id;

            return $params;
        }

        my $politician = $c->model("DB::Politician")->find($c->req->params->{politician_id});
        die \["politician_id", 'could not find politician with that id'] unless $politician;

        $params->{page_id} = $politician->user->chatbot->fb_config->page_id;

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
    my $cpf   = $c->req->params->{cpf};

    if (!$fb_id && !$cpf)  {
        die \['fb_id', 'missing']
    }
    elsif ($fb_id) {
        $c->stash->{collection} = $c->stash->{collection}->search_rs( { fb_id => $fb_id } );
    }
    elsif (!$fb_id && $cpf) {
        $c->stash->{collection} = $c->stash->{collection}->search_rs( { cpf => $cpf } );
    }
    else {
        die \['fb_id', 'missing']
    }

    return $self->status_ok(
        $c,
        entity => {
            map {
                my $c = $_;

                id                     => $c->get_column('id'),
                cpf                    => $c->get_column('cpf'),
                gender                 => $c->get_column('gender'),
                email                  => $c->get_column('email'),
                cellphone              => $c->get_column('cellphone'),
                extra_fields           => $c->extra_fields,
                session                => $c->session ? from_json($c->session) : undef
            } $c->stash->{collection}->next
        }
    )
}

sub list_all : Chained('base') : PathPart('all') : Args(0) : ActionClass('REST') { }

sub list_all_GET {
    my ($self, $c) = @_;

    my $organization_chatbot_id = $c->req->params->{organization_chatbot_id};
    die \['organization_chatbot_id', 'missing'] unless $organization_chatbot_id;

    return $self->status_ok(
        $c,
        entity => {
            recipients => [
                map {
                    my $r = $_;

                    +{
                        id                 => $r->get_column('id'),
                        fb_id              => $r->get_column('fb_id'),
                        gender             => $r->get_column('gender'),
                        cpf                => $r->get_column('cpf'),
                        email              => $r->get_column('email'),
                        cellphone          => $r->get_column('cellphone'),
                        session            => $r->session,
                        session_updated_at => $r->session_updated_at,
                        created_at         => $r->created_at->set_time_zone( 'America/Sao_Paulo' )->subtract( hours => 3 )
                    }
                } $c->stash->{collection}->search( { organization_chatbot_id => $organization_chatbot_id } )->all()
            ]
        }
    )
}

__PACKAGE__->meta->make_immutable;

1;
