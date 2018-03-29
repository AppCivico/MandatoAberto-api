use utf8;
package MandatoAberto::Schema::Result::Dialog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::Dialog

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

=head1 TABLE: C<dialog>

=cut

__PACKAGE__->table("dialog");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'dialog_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 created_by_admin_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 updated_by_admin_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "dialog_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "created_by_admin_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "updated_by_admin_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 created_by_admin

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "created_by_admin",
  "MandatoAberto::Schema::Result::User",
  { id => "created_by_admin_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 questions

Type: has_many

Related object: L<MandatoAberto::Schema::Result::Question>

=cut

__PACKAGE__->has_many(
  "questions",
  "MandatoAberto::Schema::Result::Question",
  { "foreign.dialog_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 updated_by_admin

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "updated_by_admin",
  "MandatoAberto::Schema::Result::User",
  { id => "updated_by_admin_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-03-28 17:17:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Q1+bhvmBIqbejCt1Qd8ymQ


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
                description => {
                    required => 0,
                    type     => "Str",
                },
                admin_id => {
                    required   => 1,
                    type       => "Int",
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

            $values{updated_by_admin_id} = delete $values{admin_id};

            $self->update(
                \%values,
                updated_at => \'NOW()'
            );
        }
    };
}

__PACKAGE__->meta->make_immutable;
1;
