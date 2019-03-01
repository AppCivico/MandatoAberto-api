use utf8;
package MandatoAberto::Schema::Result::Recipient;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::Recipient

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

=head1 TABLE: C<recipient>

=cut

__PACKAGE__->table("recipient");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'citizen_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 fb_id

  data_type: 'text'
  is_nullable: 1

=head2 gender

  data_type: 'text'
  is_nullable: 1

=head2 email

  data_type: 'text'
  is_nullable: 1

=head2 cellphone

  data_type: 'text'
  is_nullable: 1

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 groups

  data_type: 'hstore'
  default_value: (empty string)
  is_nullable: 1

=head2 picture

  data_type: 'text'
  is_nullable: 1

=head2 fb_opt_in

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 page_id

  data_type: 'text'
  is_nullable: 0

=head2 session

  data_type: 'json'
  is_nullable: 1

=head2 session_updated_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 entities

  data_type: 'integer[]'
  default_value: '{}'::integer[]
  is_nullable: 0

=head2 organization_chatbot_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "citizen_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "fb_id",
  { data_type => "text", is_nullable => 1 },
  "gender",
  { data_type => "text", is_nullable => 1 },
  "email",
  { data_type => "text", is_nullable => 1 },
  "cellphone",
  { data_type => "text", is_nullable => 1 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "groups",
  { data_type => "hstore", default_value => "", is_nullable => 1 },
  "picture",
  { data_type => "text", is_nullable => 1 },
  "fb_opt_in",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "page_id",
  { data_type => "text", is_nullable => 0 },
  "session",
  { data_type => "json", is_nullable => 1 },
  "session_updated_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "entities",
  {
    data_type     => "integer[]",
    default_value => \"'{}'::integer[]",
    is_nullable   => 0,
  },
  "organization_chatbot_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 blacklist_facebook_messengers

Type: has_many

Related object: L<MandatoAberto::Schema::Result::BlacklistFacebookMessenger>

=cut

__PACKAGE__->has_many(
  "blacklist_facebook_messengers",
  "MandatoAberto::Schema::Result::BlacklistFacebookMessenger",
  { "foreign.recipient_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 issues

Type: has_many

Related object: L<MandatoAberto::Schema::Result::Issue>

=cut

__PACKAGE__->has_many(
  "issues",
  "MandatoAberto::Schema::Result::Issue",
  { "foreign.recipient_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 logs

Type: has_many

Related object: L<MandatoAberto::Schema::Result::Log>

=cut

__PACKAGE__->has_many(
  "logs",
  "MandatoAberto::Schema::Result::Log",
  { "foreign.recipient_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
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

=head2 politician_entity_stats

Type: has_many

Related object: L<MandatoAberto::Schema::Result::PoliticianEntityStat>

=cut

__PACKAGE__->has_many(
  "politician_entity_stats",
  "MandatoAberto::Schema::Result::PoliticianEntityStat",
  { "foreign.recipient_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 poll_results

Type: has_many

Related object: L<MandatoAberto::Schema::Result::PollResult>

=cut

__PACKAGE__->has_many(
  "poll_results",
  "MandatoAberto::Schema::Result::PollResult",
  { "foreign.recipient_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 poll_self_propagation_queues

Type: has_many

Related object: L<MandatoAberto::Schema::Result::PollSelfPropagationQueue>

=cut

__PACKAGE__->has_many(
  "poll_self_propagation_queues",
  "MandatoAberto::Schema::Result::PollSelfPropagationQueue",
  { "foreign.recipient_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2019-03-01 15:05:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:B9oVNITDjiYwCmEqGB1gbA

__PACKAGE__->load_components("InflateColumn::Serializer", "Core");
__PACKAGE__->remove_column('groups');
__PACKAGE__->add_columns(
    groups => {
        'data_type'        => 'hstore',
        is_nullable        => 1,
        default_value      => "",
        'serializer_class' => 'Hstore',
    },
);

with 'MandatoAberto::Role::Verification';
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use MandatoAberto::Types qw(EmailAddress PhoneNumber);

sub verifiers_specs {
    my $self = shift;

    return {
        update => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                email => {
                    required => 0,
                    type     => EmailAddress
                },
                cellphone => {
                    required => 0,
                    type     => PhoneNumber,
                }
            }
        ),
    };
}

sub action_specs {
    my ($self) = @_;

    return {
        update => sub {
            my $r = shift;

            my %values = $r->valid_values;
            not defined $values{$_} and delete $values{$_} for keys %values;

            $self->update(\%values);
        }
    };
}

sub add_to_group {
    my ($self, $group_id) = @_;

    my $ret;
    $self->result_source->schema->txn_do(sub {
        # Verificando se este recipient já estava no grupo.
        my $recipients_rs = $self->organization_chatbot->recipients;

        my $already_in_this_group = $recipients_rs->search(
            {
                '-and' => [
                    'me.id' => $self->id,
                    \[ 'EXIST(groups, ?)', $group_id ],
                ],
            },
            { select => [ \1 ] },
        )->next;

        $ret = $self->update( { groups => \[ "COALESCE(groups, '') || HSTORE(?, '1')", $group_id ] } );

        return if $already_in_this_group;

        $self->organization_chatbot->groups
        ->search( { 'me.id' => $group_id } )
        ->update(
            {
                recipients_count        => \'recipients_count + 1',
                last_recipients_calc_at => \'NOW()',
            }
        );
    });

    return $ret;
}

sub groups_rs {
    my ($self) = @_;

    return $self->organization_chatbot->groups->search(
        {
            'me.id' => { 'in' => [ keys %{ $self->groups || {} } ] },
            deleted => 0
        }
    );
}

sub entity_rs {
    my ($self) = @_;

    return $self->organization_chatbot->politician_entities->search(
        {
            'me.id' => { 'in' => $self->entities ? $self->entities : 0 },
        }
    );
}

sub add_to_politician_entity {
    my ($self, $politician_entity_id) = @_;

    my $ret;
    $self->result_source->schema->txn_do(
        sub {
            # Verificando se este recipient já estava na entidade.
            my $recipients_rs = $self->organization_chatbot->recipients;

			my $already_in_this_group = $recipients_rs->search(
                {
                    -and => [
                        'me.id' => $self->id,
                        \[ "? =ANY(entities)" => $politician_entity_id ],
                    ]
                },
            );

            return if $already_in_this_group->count > 0;

            $ret = $self->update( { entities => \[ "array_append(entities, ?)", $politician_entity_id ] } );

            $self->organization_chatbot->politician_entities->search( { 'me.id' => $politician_entity_id } )->update(
                {
                    recipient_count => \'recipient_count + 1',
                    updated_at      => \'NOW()',
                }
            );
        }
    );

    return $ret;

}

__PACKAGE__->meta->make_immutable;

1;

