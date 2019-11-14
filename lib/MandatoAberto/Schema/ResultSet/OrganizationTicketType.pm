package MandatoAberto::Schema::ResultSet::OrganizationTicketType;
use common::sense;
use Moose;
use namespace::autoclean;

use DateTime::Format::Pg;

extends "DBIx::Class::ResultSet";

sub build_list {
    my ($self, %opts) = @_;

    if ($opts{build_for_front_end}) {
        my $page = 1  if !defined $opts{page};
        my $rows = 20 if !defined $opts{rows};


        $self = $self->search_rs(undef, { page => $page, rows => $rows });
    }


    my $dt_parser = DateTime::Format::Pg->new();

    return {
        itens_count  => $self->count,
        ticket_types => [
            map {
                my $usual_response_interval = $_->usual_response_interval;
                $usual_response_interval = $dt_parser->parse_interval($usual_response_interval);

                my $usual_response_time; # String

                if ( $usual_response_interval->months > 0 ) {
                    my $months = $usual_response_interval->months;

                    $usual_response_time .= "$months ";
                    $usual_response_time .= $months == 1 ? ' mês' : ' meses';
                }

                if ($usual_response_interval->days > 0) {
                    my $days = $usual_response_interval->days;

                    $usual_response_time .= ' e ' if length $usual_response_time > 0;

                    $usual_response_time .= "$days ";
                    $usual_response_time .= $days == 1 ? ' dia' : 'dias'
                }

                if ($usual_response_interval->hours > 0) {
                    my $hours = $usual_response_interval->hours;

                    $usual_response_time .= ' e ' if length $usual_response_time > 0;

                    $usual_response_time .= "$hours ";
                    $usual_response_time .= $hours == 1 ? ' hora' : 'horas'
                }

                if ($usual_response_interval->minutes > 0) {
                    my $minutes = $usual_response_interval->minutes;

                    $usual_response_time .= ' e ' if length $usual_response_time > 0;

                    $usual_response_time .= "$minutes ";
                    $usual_response_time .= $minutes == 1 ? ' minuto' : 'minutos'
                }

                +{
                    id                      => $_->id,
                    description             => $_->description,
                    name                    => $_->ticket_type->name,
                    can_be_anonymous        => $_->ticket_type->can_be_anonymous,
                    usual_response_time     => $usual_response_time,
                    usual_response_interval => $_->usual_response_interval,
                    ticket_type_id          => $_->ticket_type_id
                }
            } $self->all()
        ]
    }
}

1;
