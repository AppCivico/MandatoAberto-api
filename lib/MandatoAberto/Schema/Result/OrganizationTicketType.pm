use utf8;
package MandatoAberto::Schema::Result::OrganizationTicketType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::OrganizationTicketType

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::PassphraseColumn>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "PassphraseColumn");

=head1 TABLE: C<organization_ticket_type>

=cut

__PACKAGE__->table("organization_ticket_type");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'organization_ticket_type_id_seq'

=head2 organization_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 ticket_type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 can_be_anonymous

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 send_email_to

  data_type: 'text'
  is_nullable: 1

=head2 usual_response_interval

  data_type: 'interval'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "organization_ticket_type_id_seq",
  },
  "organization_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "ticket_type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "can_be_anonymous",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "send_email_to",
  { data_type => "text", is_nullable => 1 },
  "usual_response_interval",
  { data_type => "interval", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 organization

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Organization>

=cut

__PACKAGE__->belongs_to(
  "organization",
  "MandatoAberto::Schema::Result::Organization",
  { id => "organization_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 ticket_type

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::TicketType>

=cut

__PACKAGE__->belongs_to(
  "ticket_type",
  "MandatoAberto::Schema::Result::TicketType",
  { id => "ticket_type_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 tickets

Type: has_many

Related object: L<MandatoAberto::Schema::Result::Ticket>

=cut

__PACKAGE__->has_many(
  "tickets",
  "MandatoAberto::Schema::Result::Ticket",
  { "foreign.organization_ticket_type_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2019-11-14 12:07:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WWAhzznw0WqcSkvaq1Xm7g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
with 'MandatoAberto::Role::Verification';
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use MandatoAberto::Types qw(EmailAddress);
use DateTime::Format::Pg;

sub verifiers_specs {
    my $self = shift;

    return {
        update => Data::Verifier->new(
            filters => [ qw/ trim / ],
            profile => {
                can_be_anonymous => {
                    required => 0,
                    type     => 'Bool',
                },

                description => {
                    required => 0,
                    type     => 'Str'
                },

                send_email_to => {
                    required => 0,
                    type     => EmailAddress
                },

                usual_response_interval => {
                    required => 0,
                    type     => 'Str'
                },

                delete_send_email_to => {
                    required => 0,
                    type     => 'Bool'
                }
            }
        )
    };
}

sub action_specs {
    my ($self) = @_;

    return {
        update => sub {
            my $r = shift;

            my %values = $r->valid_values;
            not defined $values{$_} and delete $values{$_} for keys %values;

            if ( $values{usual_response_interval} && $values{usual_response_interval} eq '__DELETE__' ) {
                $values{usual_response_interval} = undef;
            }

            if ( $values{delete_send_email_to} ) {
                $values{send_email_to} = undef;
                delete $values{delete_send_email_to};
            }

            if ( $values{usual_response_interval} && $values{usual_response_interval} ne '__DELETE__' ) {
                my $usual_response_interval = delete $values{usual_response_interval};

                my $dt_parser = DateTime::Format::Pg->new();

                my $parsed_interval;
                eval { $parsed_interval = $dt_parser->parse_interval($usual_response_interval) };

                die \['usual_response_interval', 'invalid'] if $@;

                $values{usual_response_interval} = $usual_response_interval;
            }

            return $self->update(\%values);
        },
    };
}

sub build_list {
    my ($self) = @_;

    my $dt_parser = DateTime::Format::Pg->new();

    my $usual_response_interval = $self->usual_response_interval;
    $usual_response_interval = $dt_parser->parse_interval($usual_response_interval);

    my $usual_response_time; # String

    if ( $usual_response_interval->months > 0 ) {
        my $months = $usual_response_interval->months;

        $usual_response_time .= "$months ";
        $usual_response_time .= $months == 1 ? ' mês' : ' meses';
    }

    if ($usual_response_interval->days > 0) {
        my $days = $usual_response_interval->in_units( 'days' );

        $usual_response_time .= ' e ' if $usual_response_time && length $usual_response_time > 0;

        $usual_response_time .= "$days ";
        $usual_response_time .= $days == 1 ? ' dia' : 'dias'
    }

    if ($usual_response_interval->hours > 0) {
        my $hours = $usual_response_interval->in_units( 'hours' );

        $usual_response_time .= ' e ' if $usual_response_time && length $usual_response_time > 0;

        $usual_response_time .= "$hours ";
        $usual_response_time .= $hours == 1 ? ' hora' : 'horas'
    }

    if ($usual_response_interval->minutes > 0) {
        my $minutes = $usual_response_interval->minutes;

        $usual_response_time .= ' e ' if $usual_response_time && length $usual_response_time > 0;

        $usual_response_time .= "$minutes ";
        $usual_response_time .= $minutes == 1 ? ' minuto' : 'minutos'
    }

    return {
        id                      => $self->id,
        name                    => $self->ticket_type->name,
        description             => $self->description,
        send_email_to           => $self->send_email_to,
        can_be_anonymous        => $self->can_be_anonymous,
        usual_response_interval => $self->usual_response_interval,
        usual_response_time     => $usual_response_time,
    }
}

__PACKAGE__->meta->make_immutable;
1;
