package MandatoAberto::Controller::API::Politician::Citizen;
use Moose;
use namespace::autoclean;

use Scalar::Util qw(looks_like_number);

BEGIN { extends "CatalystX::Eta::Controller::REST" }

with "CatalystX::Eta::Controller::AutoBase";

__PACKAGE__->config(
    result  => "DB::Recipient",
    no_user => 1,
);

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('citizen') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    my $politician_id = $c->stash->{politician}->user_id;

    return $self->status_ok(
        $c,
        entity => {
            citizens => [
                map {
                    my $c = $_;

                    my $gender = $c->get_column('gender');

                    +{
                        id            => $c->get_column('id'),
                        name          => $c->get_column('name'),
                        email         => $c->get_column('email'),
                        cellphone     => $c->get_column('cellphone'),
                        gender        => $gender eq 'F' ? 'Feminino' : 'Masculino',
                        origin_dialog => $c->get_column('origin_dialog'),
                        created_at    => $c->get_column('created_at'),
                    }
                } $c->stash->{collection}->search( { politician_id => $politician_id } )->all()
            ]
        }
    )
}

__PACKAGE__->meta->make_immutable;

1;
