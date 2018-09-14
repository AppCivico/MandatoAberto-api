use utf8;
package MandatoAberto::Schema::Result::PoliticianKnowledgeBase;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::PoliticianKnowledgeBase

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

=head1 TABLE: C<politician_knowledge_base>

=cut

__PACKAGE__->table("politician_knowledge_base");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'politician_knowledge_base_id_seq'

=head2 politician_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 entities

  data_type: 'integer[]'
  is_nullable: 0

=head2 active

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 answer

  data_type: 'text'
  is_nullable: 1

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 saved_attachment_id

  data_type: 'text'
  is_nullable: 1

=head2 saved_attachment_type

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "politician_knowledge_base_id_seq",
  },
  "politician_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "entities",
  { data_type => "integer[]", is_nullable => 0 },
  "active",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "answer",
  { data_type => "text", is_nullable => 1 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "saved_attachment_id",
  { data_type => "text", is_nullable => 1 },
  "saved_attachment_type",
  { data_type => "text", is_nullable => 1 },
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


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-09-14 11:24:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mLemE036rquaQxAAlD84Bw


# You can replace this text with custom code or comments, and it will be preserved on regeneration

with 'MandatoAberto::Role::Verification';
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

sub verifiers_specs {
    my $self = shift;

    return {
        update => Data::Verifier->new(
            filters => [ qw(trim) ],
            profile => {
                answer => {
                    required   => 0,
                    type       => 'Str',
                    max_lenght => 300
                },
                active => {
                    required => 0,
                    type     => 'Bool'
                },
                saved_attachment_type => {
                    required => 0,
                    type     => 'Str'
                },
                saved_attachment_id => {
                    required => 0,
                    type     => 'Str'
                },
            },
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

            my @entities = @{ $self->entities };
            my $active_knowledge_base_entry = $self->result_source->schema->resultset('PoliticianKnowledgeBase')->search(
                {
                    politician_id => $self->politician->id,
                    entities      => "{@entities}",
                    active        => 1,
                }
            )->next;

            if ( $values{active} == 1 && $active_knowledge_base_entry && $active_knowledge_base_entry->id != $self->id ) {
                $active_knowledge_base_entry->update( { active => 0 } );
            }

            $self->update({
                %values,
                updated_at => \'NOW()',
            });
        }
    };
}

sub issue_rs {
    my ($self) = @_;

    return $self->politician->issues->search(
        {
            'me.id' => { 'in' => $self->issues ? $self->issues : 0 },
        }
    );
}

sub entity_rs {
    my ($self) = @_;

    return $self->politician->politician_entities->search(
        {
            'me.id' => { 'in' => $self->entities ? $self->entities : 0 },
        }
    );
}

__PACKAGE__->meta->make_immutable;
1;
