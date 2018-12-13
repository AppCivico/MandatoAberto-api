package MandatoAberto::Controller::API::Politician::Persona;
use Moose;
use namespace::autoclean;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

with "CatalystX::Eta::Controller::TypesValidation";

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->detach("/api/forbidden") unless $c->stash->{is_me};

    eval { $c->assert_user_roles(qw/politician/) };
    if ($@) {
        $c->forward("/api/forbidden");
    }
}

sub base : Chained('root') : PathPart('persona') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{collection} = $c->model('DB::OrganizationChatbotPersona');
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST {
    my ($self, $c) = @_;

    my $organization = $c->stash->{politician}->user->organization;
    my $organization_chatbot = $organization->organization_chatbots->next;

    my $persona = $c->stash->{collection}->execute(
        $c,
        for  => 'create',
        with => {
            %{ $c->req->params },
            organization_chatbot_id => $organization_chatbot->id
        }
    );

    return $self->status_created(
        $c,
        location => $c->uri_for($c->controller("API::Politician::Persona"), [ $persona->id ]),
        entity   => { id => $persona->id }
    )
}

sub list_GET {
    my ($self, $c) = @_;

	my $page    = $c->req->params->{page}    || 1;
	my $results = $c->req->params->{results} || 20;
	$results    = $results <= 20 ? $results : 20;

    return $self->status_ok(
        $c,
        entity => {
            itens_count => $c->stash->{collection}->count,
            personas    => [
                map {
                    my $p = $_;

                    +{
                        id                      => $p->id,
                        facebook_id             => $p->facebook_id,
                        name                    => $p->name,
                        picture                 => $p->facebook_picture_url,
                        organization_chatbot_id => $p->organization_chatbot_id
                    }
                } $c->stash->{collection}->search(
                    { 'user.id' => $c->stash->{politician}->user_id },
                    {
                        prefetch => { 'organization_chatbot' => { 'organization' => { 'user_organizations' => 'user' } } },
                        page     => $page,
                        rows     => $results,
                    }
                  )
            ]
        }
    )
}

__PACKAGE__->meta->make_immutable;

1;