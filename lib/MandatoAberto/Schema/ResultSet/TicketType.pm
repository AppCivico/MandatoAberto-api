package MandatoAberto::Schema::ResultSet::TicketType;
use common::sense;
use Moose;
use namespace::autoclean;

extends "DBIx::Class::ResultSet";

sub build_list {
    my $self = shift;

    return {
        ticket_types => [
            map {
                +{
                    id   => $_->id,
                    name => $_->name
                }
            } $self->all()
        ]
    }
}

1;
