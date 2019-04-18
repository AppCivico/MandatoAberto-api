package MandatoAberto::Controller::API::Office;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoListGET";

__PACKAGE__->config(
    # AutoBase.
    result     => "DB::Office",

    list_key => "office",
    build_row  => sub {
        return { $_[0]->get_columns() };
    }
);

sub root : Chained('/api/root') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('office') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    my $gender = $c->req->params->{gender};
    die \["gender", "must be specified"] unless $gender;

    return $self->status_ok(
        $c,
        entity => {
            offices => [
                map {
                    my $o = $_;
                    +{
                        id      => $o->get_column('id'),
                        name    => $o->get_column('name'),
                    }
                } $c->stash->{collection}->search( { gender => $gender } )->all()
            ]
        }
    );
}

1;