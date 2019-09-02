use utf8;
package MandatoAberto::Schema::Result::QuestionnaireStash;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::QuestionnaireStash

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

=head1 TABLE: C<questionnaire_stash>

=cut

__PACKAGE__->table("questionnaire_stash");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'questionnaire_stash_id_seq'

=head2 recipient_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 questionnaire_map_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 value

  data_type: 'json'
  default_value: '{}'
  is_nullable: 0

=head2 finished

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

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
    sequence          => "questionnaire_stash_id_seq",
  },
  "recipient_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "questionnaire_map_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "value",
  { data_type => "json", default_value => "{}", is_nullable => 0 },
  "finished",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
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

=head2 C<questionnaire_stash_recipient_id_questionnaire_map_id_key>

=over 4

=item * L</recipient_id>

=item * L</questionnaire_map_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "questionnaire_stash_recipient_id_questionnaire_map_id_key",
  ["recipient_id", "questionnaire_map_id"],
);

=head1 RELATIONS

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


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2019-09-02 15:25:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/0kT8217EYXUXA6R2i4wJA


# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub parsed {
	my ($self) = @_;

	return from_json( $self->value );
}

sub answered_questions {
    my ($self) = @_;

    return $self->recipient->questionnaire_answers->search(
        { 'me.questionnaire_map_id' => $self->questionnaire_map_id },
        { join => 'question' }
    )->get_column('question.code')->all();
}

sub next_pending_question {
    my $self = shift;

    my ($next_question, %flags);
    my $has_more   = 0;
    my $count_more = 0;

    if ( $self->finished ) {

    }
    else {
        my $question_map       = $self->questionnaire_map->parsed;
        my @answered_questions = $self->answered_questions;

        my @pending_questions  = sort { $a <=> $b } grep { my $k = $_; !grep { $question_map->{$k} eq $_ } @answered_questions } sort keys %{ $question_map };

        if (scalar @pending_questions > 0) {
            $has_more   = 1;
            $count_more = scalar @pending_questions - 1;

            my $next_question_code = scalar @pending_questions > 0 ? $question_map->{ $pending_questions[0] } : undef;
            my $question_rs        = $self->questionnaire_map->questionnaire_questions;

            $next_question = $question_rs->search( { code => $next_question_code } )->next;
            $next_question = $next_question->decoded;
        }

    }

    return {
        question   => $next_question,
        has_more   => $has_more,
        count_more => $count_more,
        %flags
    };
}

sub remove_question {
    my ($self, $code) = @_;

    die \['code', 'missing'] unless $code;

    my $map = $self->parsed;

    my %r_map = reverse %{$map};
    my $key   = $r_map{$code};
    die \['code', 'invalid'] unless $key;

    delete $map->{$key};

    # Deletando qualquer pergunta atrelada por salto de lógica
    my $question = $self->result_source->schema->resultset('QuestionnaireQuestion')->search(
        {
            code                 => $code,
            questionnaire_map_id => $self->questionnaire_map_id
        }
    )->next;
    my $question_rules = $question->rules_parsed;

    if ( $question_rules && $question_rules->{logic_jumps} && scalar @{ $question_rules->{logic_jumps} } > 0 ) {
        for my $logic_jump ( @{ $question_rules->{logic_jumps} } ) {
            $key = $r_map{ $logic_jump->{code} };

            delete $map->{$key} if $key;
        }
    }

    return $self->update( { value => to_json( $map ) } );
}

__PACKAGE__->meta->make_immutable;
1;
