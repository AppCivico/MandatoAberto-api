use utf8;
package MandatoAberto::Schema::Result::Poll;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::Poll

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

=head1 TABLE: C<poll>

=cut

__PACKAGE__->table("poll");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'poll_id_seq'

=head2 politician_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 status_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 notification_sent

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "poll_id_seq",
  },
  "politician_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "status_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "notification_sent",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 politician

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Politician>

=cut

__PACKAGE__->belongs_to(
  "politician",
  "MandatoAberto::Schema::Result::Politician",
  { user_id => "politician_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 poll_notifications

Type: has_many

Related object: L<MandatoAberto::Schema::Result::PollNotification>

=cut

__PACKAGE__->has_many(
  "poll_notifications",
  "MandatoAberto::Schema::Result::PollNotification",
  { "foreign.poll_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 poll_propagates

Type: has_many

Related object: L<MandatoAberto::Schema::Result::PollPropagate>

=cut

__PACKAGE__->has_many(
  "poll_propagates",
  "MandatoAberto::Schema::Result::PollPropagate",
  { "foreign.poll_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 poll_questions

Type: has_many

Related object: L<MandatoAberto::Schema::Result::PollQuestion>

=cut

__PACKAGE__->has_many(
  "poll_questions",
  "MandatoAberto::Schema::Result::PollQuestion",
  { "foreign.poll_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 poll_self_propagation_queues

Type: has_many

Related object: L<MandatoAberto::Schema::Result::PollSelfPropagationQueue>

=cut

__PACKAGE__->has_many(
  "poll_self_propagation_queues",
  "MandatoAberto::Schema::Result::PollSelfPropagationQueue",
  { "foreign.poll_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 status

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::PollStatus>

=cut

__PACKAGE__->belongs_to(
  "status",
  "MandatoAberto::Schema::Result::PollStatus",
  { id => "status_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-09-10 13:31:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3HOo6MBQVh4H8r/dX/78yg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
use MandatoAberto::Utils;

use JSON::MaybeXS;

with 'MandatoAberto::Role::Verification';
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

sub verifiers_specs {
    my $self = shift;

    return {
        update => Data::Verifier->new(
            filters => [ qw(trim) ],
            profile => {
                status_id => {
                    required   => 0,
                    type       => "Int",
                    post_check => sub {
                        my $status_id = $_[0]->get_value("status_id");
                        $self->result_source->schema->resultset("PollStatus")->search( { id => $status_id } )->count == 1;
                    }
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

            if ($self->status_id == 3) {
                die \["status_id", "poll has been deactivated"];
            }

            if ($values{status_id} == 2 && $self->status_id == 1) {
                die \["status_id", "active poll cannot be inactive, must be deactivated"];
            }

            if ($values{status_id} == 1) {
                my $active_poll = $self->schema->resultset('Poll')->search(
                    {
                        status_id     => 1,
                        politician_id => $self->politician_id
                    }
                )->next;

                $active_poll->update( { status_id => 3 } ) if $active_poll;
            }

            $self->update({
                %values,
                updated_at => \'NOW()',
            });
        }
    };
}

sub question {
    my ($self) = @_;

    return $self->poll_questions->next;
}

sub options {
    my ($self) = @_;

    my $question = $self->question;
    my @options  = $question->poll_question_options->all();

    return @options;
}

sub build_content_object {
    my ($self, $recipient) = @_;

    my $question = $self->question;
    my @options  = $self->options;

	my $first_option  = $options[0];
	my $second_option = $options[1];

    my $res = {
        messaging_type => "UPDATE",
        recipient      => {
            id => $recipient->id
        },
        message        => {
            text => $question->content,
			quick_replies => [
				{
					content_type => 'text',
					title        => $first_option->content,
					payload      => 'pollAnswerPropagate_' . $first_option->id
				},
				{
					content_type => 'text',
					title        => $second_option->content,
					payload      => 'pollAnswerPropagate_' . $second_option->id
				},
			]
        }
    };

    return $res;
}

__PACKAGE__->meta->make_immutable;
1;
