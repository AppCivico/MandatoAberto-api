use utf8;
package MandatoAberto::Schema::Result::Ticket;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::Ticket

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

=head1 TABLE: C<ticket>

=cut

__PACKAGE__->table("ticket");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'ticket_id_seq'

=head2 organization_chatbot_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 recipient_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 assignee_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 assigned_by

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 status

  data_type: 'text'
  is_nullable: 0

=head2 assigned_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 message

  data_type: 'text[]'
  is_nullable: 1

=head2 response

  data_type: 'text[]'
  is_nullable: 1

=head2 progress_started_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 closed_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 status_last_updated_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 data

  data_type: 'json'
  default_value: '{}'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "ticket_id_seq",
  },
  "organization_chatbot_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "recipient_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "assignee_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "assigned_by",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "status",
  { data_type => "text", is_nullable => 0 },
  "assigned_at",
  { data_type => "timestamp", is_nullable => 1 },
  "message",
  { data_type => "text[]", is_nullable => 1 },
  "response",
  { data_type => "text[]", is_nullable => 1 },
  "progress_started_at",
  { data_type => "timestamp", is_nullable => 1 },
  "closed_at",
  { data_type => "timestamp", is_nullable => 1 },
  "status_last_updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "data",
  { data_type => "json", default_value => "{}", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 assigned_by

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "assigned_by",
  "MandatoAberto::Schema::Result::User",
  { id => "assigned_by" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 assignee

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "assignee",
  "MandatoAberto::Schema::Result::User",
  { id => "assignee_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 organization_chatbot

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::OrganizationChatbot>

=cut

__PACKAGE__->belongs_to(
  "organization_chatbot",
  "MandatoAberto::Schema::Result::OrganizationChatbot",
  { id => "organization_chatbot_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 recipient

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Recipient>

=cut

__PACKAGE__->belongs_to(
  "recipient",
  "MandatoAberto::Schema::Result::Recipient",
  { id => "recipient_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 ticket_logs

Type: has_many

Related object: L<MandatoAberto::Schema::Result::TicketLog>

=cut

__PACKAGE__->has_many(
  "ticket_logs",
  "MandatoAberto::Schema::Result::TicketLog",
  { "foreign.ticket_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 type

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::TicketType>

=cut

__PACKAGE__->belongs_to(
  "type",
  "MandatoAberto::Schema::Result::TicketType",
  { id => "type_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2019-08-30 15:02:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dYlTqEU/7hzBxc9HuYfkww


# You can replace this text with custom code or comments, and it will be preserved on regeneration

__PACKAGE__->load_components("InflateColumn::Serializer", "Core");
__PACKAGE__->remove_columns(qw/data/);
__PACKAGE__->add_columns(
    data => {
        'data_type'        => "json",
        is_nullable        => 1,
        'serializer_class' => 'JSON'
    },
);

with 'MandatoAberto::Role::Verification';
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use JSON;

sub verifiers_specs {
    my $self = shift;

    return {
        update => Data::Verifier->new(
            filters => [ qw(trim) ],
            profile => {
                user_id => {
                    required => 0,
                    type     => 'Int'
                },

                assignee_id => {
                    required => 0,
                    type     => 'Int'
                },

                response => {
                    required => 0,
                    type     => 'ArrayRef'
                },

                status => {
                    required => 0,
                    type     => 'Str'
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

            my $log_action_rs = $self->result_source->schema->resultset('TicketLogAction');
            my $actions = {
                'ticket criado'    => 1,
                'ticket designado' => 2,
                'ticket movido'    => 3,
                'ticket cancelado' => 4
            };

            my $ticket;
            $self->result_source->schema->txn_do( sub {
                my $log_action;
                my @logs;

                my $user_id = delete $values{user_id};
                my $user = $self->organization_chatbot->organization->users->search( { user_id => $user_id } )->next
                    or die \['user_id', 'invalid'];
                $user = $user->user;

                if ( my $assignee_id = $values{assignee_id} ) {
                    my $assignee = $self->organization_chatbot->organization->users->search( { user_id => $assignee_id } )->next
                    or die \['assignee_id', 'invalid'];

                    $values{assigned_by} = $user_id or die \['user_id', 'missing'];
                    $values{assigned_at} = \'NOW()';

                    my $assignee_name = $assignee->user->name;
                    my $assignor_name = $user->name;

                    push @logs, {
                        text      => "Ticket designado para: $assignee_name, por: $assignor_name",
                        action_id => $actions->{'ticket designado'},
                        data => to_json(
                            {
                                action    => 'ticket designado',
                                impact    => 'neutral',
                                user_name => $assignor_name
                            }
                        )
                    };
                    # $self->ticket_logs->create( { text => "Ticket designado para: $assignee_name, por: $assignor_name" } );
                }

                if ( my $status = $values{status} ) {
                    die \['status', 'invalid'] unless $status =~ /^(pending|closed|progress)$/;
                    $values{status_last_updated_at} = \'NOW()';

                    my $ticket_rs = $self->result_source->schema->resultset('Ticket');

                    my $current_status = $ticket_rs->human_status($self->status);
                    my $next_status    = $ticket_rs->human_status($status);
                    my $user_name      = $user->name;

                    if ( $current_status ne $next_status ) {
                        my $impact;

                        if ($next_status eq 'pending') {
                            $impact = 'negative'
                        }
                        else {
                            $impact = 'positive';
                        }

                        push @logs, {
                            text      => "Ticket movido de '$current_status', para '$next_status', por: $user_name",
                            action_id => $actions->{'ticket movido'},
                            data => to_json(
                                {
                                    action    => 'ticket movido',
                                    impact    => $impact,
                                    user_name => $user_name,
                                    status    => $next_status
                                }
                            )
                        };
                    }
                }

                $self->ticket_logs->populate(\@logs);
                $ticket = $self->update(\%values);
            });

            return $ticket;
        }
    };
}

sub build_list {
    my $self = shift;

    return {
        (map { $_ => $self->$_ } qw(id status message response created_at closed_at assigned_at data)),
        (
            logs => [
                map {
                    +{
                        text       => $_->text,
                        created_at => $_->created_at,
                        data       => from_json($_->data)
                    }
                } $self->ticket_logs->search(undef, { order_by => { '-desc' => 'me.created_at' } })->all()
            ]
        ),

        (
            recipient => {
                id      => $self->recipient->id,
                name    => $self->recipient->name,
                picture => $self->recipient->picture
            }
        ),

        (
            assignee => {
                id      => $self->assignee ? $self->assignee->id : undef,
                name    => $self->assignee ? $self->assignee->name : undef,
                picture => $self->assignee ? $self->assignee->picture : undef,
            }
        ),

        (
            assignor => {
                id      => $self->assigned_by ? $self->assigned_by->id : undef,
                name    => $self->assigned_by ? $self->assigned_by->name : undef,
                picture => $self->assigned_by ? $self->assigned_by->picture : undef,
            }
        ),

        (
            type => {
                id => $self->type_id,
                name => $self->type->name
            }
        )
    }
}

__PACKAGE__->meta->make_immutable;
1;
