use utf8;
package MandatoAberto::Schema::Result::Question;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::Question

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

=head1 TABLE: C<question>

=cut

__PACKAGE__->table("question");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'question_id_seq'

=head2 dialog_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 content

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "question_id_seq",
  },
  "dialog_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "content",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 dialog

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Dialog>

=cut

__PACKAGE__->belongs_to(
  "dialog",
  "MandatoAberto::Schema::Result::Dialog",
  { id => "dialog_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2017-10-26 16:16:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UdH6aCfqZk5nCVgnu7VQfA


# You can replace this text with custom code or comments, and it will be preserved on regeneration

use MandatoAberto::Utils;

with 'MandatoAberto::Role::Verification';
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

sub verifiers_specs {
    my $self = shift;

    return {
        update => Data::Verifier->new(
            filters => [ qw(trim) ],
            profile => {
                name => {
                    required => 0,
                    type     => "Str",
                    post_check => sub {
                        my $r = shift;

                        $self->result_source->schema->resultset('Dialog')
                            ->search({ name => $r->get_value('name') })
                            ->count and die \["name", "alredy exists"];

                        return 1;
                    }
                },
                dialog_id => {
                    required   => 0,
                    type       => "Int",
                    post_check => sub {
                        my $r = shift;

                        $self->result_source
                    }
                }
            },
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

__PACKAGE__->meta->make_immutable;
1;
