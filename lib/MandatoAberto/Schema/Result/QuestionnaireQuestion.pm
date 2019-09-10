use utf8;
package MandatoAberto::Schema::Result::QuestionnaireQuestion;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::QuestionnaireQuestion

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

=head1 TABLE: C<questionnaire_question>

=cut

__PACKAGE__->table("questionnaire_question");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'questionnaire_question_id_seq'

=head2 questionnaire_map_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 code

  data_type: 'varchar'
  is_nullable: 0
  size: 4

=head2 type

  data_type: 'text'
  is_nullable: 0

=head2 text

  data_type: 'text'
  is_nullable: 0

=head2 multiple_choices

  data_type: 'json'
  is_nullable: 1

=head2 extra_quick_replies

  data_type: 'json'
  is_nullable: 1

=head2 rules

  data_type: 'json'
  is_nullable: 1

=head2 send_flags

  data_type: 'text[]'
  is_nullable: 1

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

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
    sequence          => "questionnaire_question_id_seq",
  },
  "questionnaire_map_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "code",
  { data_type => "varchar", is_nullable => 0, size => 4 },
  "type",
  { data_type => "text", is_nullable => 0 },
  "text",
  { data_type => "text", is_nullable => 0 },
  "multiple_choices",
  { data_type => "json", is_nullable => 1 },
  "extra_quick_replies",
  { data_type => "json", is_nullable => 1 },
  "rules",
  { data_type => "json", is_nullable => 1 },
  "send_flags",
  { data_type => "text[]", is_nullable => 1 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
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

=head1 UNIQUE CONSTRAINTS

=head2 C<questionnaire_question_code_map_key>

=over 4

=item * L</questionnaire_map_id>

=item * L</code>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "questionnaire_question_code_map_key",
  ["questionnaire_map_id", "code"],
);

=head1 RELATIONS

=head2 questionnaire_answers

Type: has_many

Related object: L<MandatoAberto::Schema::Result::QuestionnaireAnswer>

=cut

__PACKAGE__->has_many(
  "questionnaire_answers",
  "MandatoAberto::Schema::Result::QuestionnaireAnswer",
  { "foreign.question_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 questionnaire_map

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::QuestionnaireMap>

=cut

__PACKAGE__->belongs_to(
  "questionnaire_map",
  "MandatoAberto::Schema::Result::QuestionnaireMap",
  { id => "questionnaire_map_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2019-09-10 10:50:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Qk8JTWPYJMUBV5RCkYIYfA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
use JSON;

sub decoded {
    my ($self) = @_;

    return {
        id                  => $self->id,
        code                => $self->code,
        type                => $self->type,
        text                => $self->text,
        multiple_choices    => $self->multiple_choices    ? from_json( $self->multiple_choices )    : undef,
        extra_quick_replies => $self->extra_quick_replies ? from_json( $self->extra_quick_replies ) : undef,
        updated_at          => $self->updated_at,
        created_at          => $self->created_at
    }
}

sub rules_parsed {
    my ($self) = @_;

    return from_json( $self->rules ) if $self->rules;
}

sub multiple_choices_score_map {
    my ($self) = @_;

    my $rules = $self->rules_parsed or die \['question', 'does not have any rules'];
    return undef unless $rules->{multiple_choice_score_map} && ref $rules->{multiple_choice_score_map} eq 'HASH';

    return $rules->{multiple_choice_score_map};
}

__PACKAGE__->meta->make_immutable;
1;
