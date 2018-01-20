use utf8;
package MandatoAberto::Schema::Result::Tag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::Tag

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

=head1 TABLE: C<tag>

=cut

__PACKAGE__->table("tag");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'tag_id_seq'

=head2 politician_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 filter

  data_type: 'json'
  is_nullable: 0

=head2 calc

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 last_calc_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "tag_id_seq",
  },
  "politician_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "filter",
  { data_type => "json", is_nullable => 0 },
  "calc",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "last_calc_at",
  { data_type => "timestamp", is_nullable => 1 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
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


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2018-01-16 13:13:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:h+h8C5njECv8CRPCWn8t1Q

__PACKAGE__->load_components("InflateColumn::Serializer", "Core");
__PACKAGE__->remove_column('filter');
__PACKAGE__->add_columns(
    filter => {
        'data_type'        => 'json',
        is_nullable        => 0,
        'serializer_class' => 'JSON',
    },
);

use Data::Printer;

sub update_recipients {
    my ($self) = @_;

    my $recipients_rs = $self->politician->recipients;

    $self->result_source->schema->txn_do(sub {
        # 'Zerando' todos os contatos dessa lista antes de recalcular.
        # TODO Testar essa parte no 010-tag.t.
        my $id = $self->id;
        $recipients_rs
            ->search( \[ "EXIST(tags, '$id')" ] )
            ->update( { tags => \"DELETE(tags, '$id')" } );

        my $filter = $self->filter;
        $recipients_rs = $self->politician->recipients->search_by_tag_filter($filter);
    });

    return $recipients_rs->count ;
}


__PACKAGE__->meta->make_immutable;

1;

