package MandatoAberto::Controller::API::Politician::Campaign;
use common::sense;
use Moose;
use namespace::autoclean;

use MandatoAberto::Utils qw/ is_test /;

use WebService::Facebook;

use File::Basename;
use File::MimeInfo;
use DateTime;
use Crypt::PRNG qw(random_string);

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->detach("/api/forbidden") unless $c->stash->{is_me};

    eval { $c->assert_user_roles(qw/politician/) };
    if ($@) {
        $c->forward("/api/forbidden");
    }
}

sub base : Chained('root') : PathPart('direct-message') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{collection} = $c->model('DB::DirectMessage')->search(
        { 'campaign.politician_id' => $c->stash->{politician}->id },
        { prefetch => 'campaign' }
    );
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    my $page    = $c->req->params->{page}    || 1;
    my $results = $c->req->params->{results} || 20;

    return $self->status_ok(
        $c,
        entity => {
            campaigns => [
                map {
                    my $c = $_;

                    +{
                        id     => $c->id,
                        type   => $c->type->human_name,
                        status => $c->status->name,
                        count  => $c->count
                    }
                } $c->stash->{collection}->search(
                    { 'campaign.politician_id' => $c->stash->{politician}->id },
                    { prefetch => 'campaign' }
                  )->all()
            ]
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
