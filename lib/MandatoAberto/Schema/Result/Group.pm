use utf8;
package MandatoAberto::Schema::Result::Group;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::Group

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

=head1 TABLE: C<group>

=cut

__PACKAGE__->table("group");

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

=head2 last_recipients_calc_at

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

=head2 recipients_count

  data_type: 'integer'
  is_nullable: 1

=head2 status

  data_type: 'text'
  default_value: 'processing'
  is_nullable: 0

=head2 deleted

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 deleted_at

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
  "last_recipients_calc_at",
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
  "recipients_count",
  { data_type => "integer", is_nullable => 1 },
  "status",
  { data_type => "text", default_value => "processing", is_nullable => 0 },
  "deleted",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "deleted_at",
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


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2018-02-07 11:22:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FrPolk6g3E+rZVSSmHns7w

__PACKAGE__->load_components("InflateColumn::Serializer", "Core");
__PACKAGE__->remove_column('filter');
__PACKAGE__->add_columns(
    filter => {
        'data_type'        => 'json',
        is_nullable        => 0,
        'serializer_class' => 'JSON',
    },
);

use MandatoAberto::Utils;

with 'MandatoAberto::Role::Verification';
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

sub verifiers_specs {
    my $self = shift;

    return {
        update => Data::Verifier->new(
            filters => [ qw/ trim / ],
            profile => {
                name => {
                    required => 0,
                    type     => 'Str',
                },

                filter => {
                    required => 0,
                    type     => 'HashRef',
                    post_check => sub {
                        my $filter = $_[0]->get_value('filter');

                        my %allowed_operators = map { $_ => 1 } qw/ AND OR /;
                        my %allowed_data      = map { $_ => 1 } qw/ field value /;
                        my %allowed_rules     = map { $_ => 1 }
                            qw/
                            QUESTION_ANSWER_EQUALS QUESTION_ANSWER_NOT_EQUALS QUESTION_IS_NOT_ANSWERED
                            QUESTION_IS_ANSWERED
                            /
                        ;

                        return 0 unless $allowed_operators{$filter->{operator}};

                        ref($filter->{rules}) eq 'ARRAY' or return 0;

                        for my $rule (@{ $filter->{rules} }) {
                            $allowed_rules{$rule->{name}} or return 0;

                            if (defined($rule->{data})) {
                                ref $rule->{data} eq 'HASH' or return 0;

                                for my $k (keys %{ $rule->{data} }) {
                                    $allowed_data{$k} or return 0;
                                    ref($rule->{data}->{$k}) eq "" or return 0;
                                }
                            }
                        }

                        return 1;
                    },
                },
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

            if ($self->get_column('status') eq 'processing') {
                die { error_code => 400, message => 'already processing.', msg => '' };
            }

            $self->update(
                {
                    %values,
                    status           => 'processing',
                    recipients_count => undef,
                    updated_at       => \'NOW()',
                },
            );
        },
    };
}

sub update_recipients {
    my ($self) = @_;

    my $recipients_rs = $self->politician->recipients;

    my $count;
    $self->result_source->schema->txn_do(sub {
        # 'Zerando' todos os contatos dessa lista antes de recalcular.
        $recipients_rs
            ->search( \[ "EXIST(groups, ?)", $self->id ] )
            ->update( { groups => \[ "DELETE(groups, ?)", $self->id ] } );

        my $filter = $self->filter;
        my $recipients_with_filter_rs = $recipients_rs->search_by_filter($filter);

        $count = $recipients_rs->search(
            {
                id => { '-in' => $recipients_with_filter_rs->get_column('id')->as_query }
            }
        )
        ->update( { groups => \[ "COALESCE(groups, '') || HSTORE(?, '1')", $self->id ] } );
    });

    return $count;
}

__PACKAGE__->meta->make_immutable;

1;

