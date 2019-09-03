use utf8;
package MandatoAberto::Schema::Result::QuestionnaireMap;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::QuestionnaireMap

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

=head1 TABLE: C<questionnaire_map>

=cut

__PACKAGE__->table("questionnaire_map");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'questionnaire_map_id_seq'

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 map

  data_type: 'json'
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "questionnaire_map_id_seq",
  },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "map",
  { data_type => "json", is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 questionnaire_answers

Type: has_many

Related object: L<MandatoAberto::Schema::Result::QuestionnaireAnswer>

=cut

__PACKAGE__->has_many(
  "questionnaire_answers",
  "MandatoAberto::Schema::Result::QuestionnaireAnswer",
  { "foreign.questionnaire_map_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 questionnaire_questions

Type: has_many

Related object: L<MandatoAberto::Schema::Result::QuestionnaireQuestion>

=cut

__PACKAGE__->has_many(
  "questionnaire_questions",
  "MandatoAberto::Schema::Result::QuestionnaireQuestion",
  { "foreign.questionnaire_map_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 questionnaire_stashes

Type: has_many

Related object: L<MandatoAberto::Schema::Result::QuestionnaireStash>

=cut

__PACKAGE__->has_many(
  "questionnaire_stashes",
  "MandatoAberto::Schema::Result::QuestionnaireStash",
  { "foreign.questionnaire_map_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 type

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::QuestionnaireType>

=cut

__PACKAGE__->belongs_to(
  "type",
  "MandatoAberto::Schema::Result::QuestionnaireType",
  { id => "type_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2019-09-02 15:25:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bs8sjcqqNcAtVOT4uOYYnw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
use JSON;

sub parsed {
	my ($self) = @_;

	return from_json( $self->map );
}

__PACKAGE__->meta->make_immutable;
1;
