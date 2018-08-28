use utf8;
package MandatoAberto::Schema::Result::PoliticianEntity;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::PoliticianEntity

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

=head1 TABLE: C<politician_entity>

=cut

__PACKAGE__->table("politician_entity");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'politician_entity_id_seq'

=head2 politician_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 recipient_count

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 name

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "politician_entity_id_seq",
  },
  "politician_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "recipient_count",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "name",
  { data_type => "text", is_nullable => 0 },
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


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-08-23 10:07:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fLqIsKjnOl5idRdMfAv+/A


# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub get_recipients {
    my ($self) = @_;

    my $id = $self->id;

    my $cond = \[ <<'SQL_QUERY', $id ];
 @> ARRAY[?]::integer[]
SQL_QUERY

    return $self->result_source->schema->resultset('Recipient')->search( { entities => $cond } );
}

sub has_active_knowledge_base {
    my ($self) = @_;

	my $id = $self->id;

    my $knowledge_base_rs = $self->result_source->schema->resultset('PoliticianKnowledgeBase');
    $knowledge_base_rs    = $knowledge_base_rs->search( { politician_id => $self->politician->id } );

	my $cond = \[ <<'SQL_QUERY', $id ];
 @> ARRAY[?]::integer[]
SQL_QUERY

    return $knowledge_base_rs->search(
        {
            entities      => $cond,
        }
    )->count;
}

__PACKAGE__->meta->make_immutable;
1;
