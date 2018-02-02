use utf8;
package MandatoAberto::Schema::Result::Issue;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::Issue

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

=head1 TABLE: C<issue>

=cut

__PACKAGE__->table("issue");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'issue_id_seq'

=head2 politician_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 recipient_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 message

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

=head2 reply

  data_type: 'text'
  is_nullable: 1

=head2 open

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "issue_id_seq",
  },
  "politician_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "recipient_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "message",
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
  "reply",
  { data_type => "text", is_nullable => 1 },
  "open",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
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


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-01-31 09:14:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ifYVFfmRGQkBd+RJoGgejA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
use MandatoAberto::Utils;
use WebService::HttpCallback;

use JSON::MaybeXS;

has _httpcb => (
    is         => "ro",
    isa        => "WebService::HttpCallback",
    lazy_build => 1,
);

with 'MandatoAberto::Role::Verification';
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

sub verifiers_specs {
    my $self = shift;

    return {
        update => Data::Verifier->new(
            filters => [ qw(trim) ],
            profile => {
                open => {
                    required   => 1,
                    type       => "Bool",
                    post_check => sub {
                        my $open_boolean = $_[0]->get_value('open');

                        if (!$self->open) {
                            die \["open", "issue is alredy closed"];
                        }

                        return 1;
                    }
                },
                reply => {
                    required   => 0,
                    type       => "Str",
                    max_length => 250
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

            my $access_token = $self->politician->fb_page_access_token || '';
            my $recipient    = $self->recipient;

            if ($values{reply}) {
                $self->_httpcb->add(
                    url     => $ENV{FB_API_URL} . '/me/messages?access_token=' . $access_token,
                    method  => "post",
                    headers => 'Content-Type:application/json',
                    body    => encode_json {
                        recipient => {
                            id => $recipient->fb_id
                        },
                        message => {
                            text          => $values{reply},
                            quick_replies => [
                                {
                                    content_type => 'text',
                                    title        => 'Voltar para o início',
                                    payload      => 'greetings'
                                }
                            ]
                        }
                    }
                );
            }

            $self->update({
                %values,
                updated_at => \'NOW()',
            });
        }
    };
}

sub _build__httpcb { WebService::HttpCallback->instance }

__PACKAGE__->meta->make_immutable;
1;
