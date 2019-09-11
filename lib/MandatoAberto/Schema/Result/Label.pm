use utf8;
package MandatoAberto::Schema::Result::Label;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::Label

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

=head1 TABLE: C<label>

=cut

__PACKAGE__->table("label");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'label_id_seq'

=head2 organization_chatbot_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
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
    sequence          => "label_id_seq",
  },
  "organization_chatbot_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
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

=head2 C<label_organization_chatbot_id_name_key>

=over 4

=item * L</organization_chatbot_id>

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "label_organization_chatbot_id_name_key",
  ["organization_chatbot_id", "name"],
);

=head1 RELATIONS

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

=head2 recipient_labels

Type: has_many

Related object: L<MandatoAberto::Schema::Result::RecipientLabel>

=cut

__PACKAGE__->has_many(
  "recipient_labels",
  "MandatoAberto::Schema::Result::RecipientLabel",
  { "foreign.label_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2019-04-12 10:16:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ktbsIwIK2m2vjk7J+lmfRQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub verifiers_specs {
    my $self = shift;

    return {
        update => Data::Verifier->new(
            filters => [ qw(trim) ],
            profile => {
                name => {
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

            return $self->update(\%values);
        }
    };
}

sub label_GET {
    my ($self) = @_;

    return {
        map { $_ => $self->$_ } qw( id name created_at updated_at )
    }
}

__PACKAGE__->meta->make_immutable;
1;
