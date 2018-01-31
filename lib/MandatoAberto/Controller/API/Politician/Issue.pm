package MandatoAberto::Controller::API::Politician::Issue;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoListGET";
with "CatalystX::Eta::Controller::AutoResultPUT";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Issue",

    # AutoListGET
    list_key  => "issues",
    build_row => sub {
        return { $_[0]->get_columns() };
    },

    # AutoResultPUT.
    object_key                => "issue",
    result_put_for            => "update",
    prepare_params_for_update => sub {
        my ($self, $c, $params) = @_;

        $params->{open} = 0;

        return $params;
    }
);

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->detach("/api/forbidden") unless $c->stash->{is_me};

    eval { $c->assert_user_roles(qw/politician/) };
    if ($@) {
        $c->forward("/api/forbidden");
    }
}

sub base : Chained('root') : PathPart('issue') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $issue_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $issue_id } );

    my $issue = $c->stash->{collection}->find($issue_id);
    $c->detach("/error_404") unless ref $issue;

    $c->stash->{issue} = $issue;
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET { }

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_PUT { }

__PACKAGE__->meta->make_immutable;

1;