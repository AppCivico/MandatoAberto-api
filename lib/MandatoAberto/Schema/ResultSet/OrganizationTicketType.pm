package MandatoAberto::Schema::ResultSet::OrganizationTicketType;
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
                    id               => $_->id,
                    description      => $_->description,
                    name             => $_->ticket_type->name,
                    can_be_anonymous => $_->ticket_type->can_be_anonymous,
                }
            } $self->all()
        ]
    }
}

1;
