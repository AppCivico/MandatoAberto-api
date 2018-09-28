package MandatoAberto::Controller::API::City;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoListGET";

__PACKAGE__->config(
    # AutoBase.
    result     => "DB::City",

    list_key => "city",
    build_row  => sub {
        return { $_[0]->get_columns() };
    }
);

sub root : Chained('/api/root') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('city') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    my $state_id = $c->req->params->{state_id};

    return $self->status_ok(
        $c,
        entity => {
            city => [
                map {
                    my $c = $_;
                    +{
                        id      => $c->get_column('id'),
                        name    => $c->get_column('name'),
                        cep     => $c->get_column('cep'),
                    }
                } $c->stash->{collection}->search( { state_id => $state_id } )->all()
            ]
        }
    );
}

1;