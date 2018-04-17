package MandatoAberto::Controller::API::Politician::Recipients::Group;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Recipient",
);

sub root : Chained('/api/politician/recipients/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('group') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST {
    my ($self, $c) = @_;

    my $politician = $c->stash->{politician};
    my $recipient  = $c->stash->{recipient};

    my $groups = $c->req->params->{groups};
    die \['groups[]', 'missing'] unless $groups;

    $groups =~ s/(\[|\]|(\s))//g;

    my @groups = split(',', $groups);

    for my $group_id (@groups) {
        my $group = $c->model("DB::Group")->search(
            {
               'me.id'            => $group_id,
               'me.politician_id' => $politician->id,
            }
        )->next;

        die \['groups', "group $group_id does not exists or does not belongs to this politician"] unless ref $group;
        die \['groups', "group $group_id isn't ready"] unless $group->get_column('status') eq 'ready';

        $recipient->add_to_group($group->id);
    }

    return $self->status_ok(
        $c,
        entity => {
            id => $recipient->id
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
