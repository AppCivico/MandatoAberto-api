use utf8;
package MandatoAberto::Schema::Result::PoliticianKnowledgeBase;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::PoliticianKnowledgeBase

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

=head1 TABLE: C<politician_knowledge_base>

=cut

__PACKAGE__->table("politician_knowledge_base");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'politician_knowledge_base_id_seq'

=head2 politician_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 issues

  data_type: 'integer[]'
  is_nullable: 0

=head2 entities

  data_type: 'integer[]'
  is_nullable: 0

=head2 active

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 question

  data_type: 'text'
  is_nullable: 0

=head2 answer

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
    sequence          => "politician_knowledge_base_id_seq",
  },
  "politician_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "issues",
  { data_type => "integer[]", is_nullable => 0 },
  "entities",
  { data_type => "integer[]", is_nullable => 0 },
  "active",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "question",
  { data_type => "text", is_nullable => 0 },
  "answer",
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


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-08-03 16:45:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EAaVHn6ASk4B+mfmqtdXaQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration

with 'MandatoAberto::Role::Verification';
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

sub verifiers_specs {
    my $self = shift;

    return {
        update => Data::Verifier->new(
            filters => [ qw(trim) ],
            profile => {
                question => {
					required   => 1,
					type       => 'Str',
					max_lenght => 300
				},
				answer => {
					required   => 1,
					type       => 'Str',
					max_lenght => 300
				},
                issues => {
                    required   => 1,
                    type       => 'ArrayRef[Int]',
                    post_check => sub {
                        my $issue = $_[0]->get_value('issues');

                        for (my $i = 0; $i < @{ $issue }; $i++) {
                            my $issue_id = $issue->[$i];

                            my $count = $self->result_source->schema->resultset('Issue')->search(
                                {
                                    id            => $issue_id,
                                    politician_id => $_[0]->get_value('politician_id'),
                                }
                            )->count;
                            die \['issue', "could not find issue with id $issue_id"] if $count == 0;
                        }

                        return 1;
                    }
                },
                entities => {
                    required   => 1,
                    type       => 'ArrayRef[Int]',
                    post_check => sub {
                        my $entities = $_[0]->get_value('entities');

                        for ( my $i = 0; $i < @{ $entities }; $i++ ) {
                            my $entity_id = $entities->[$i];

                            my $count = $self->result_source->schema->resultset('PoliticianEntity')->search(
                                {
                                    id            => $entity_id,
                                    politician_id => $_[0]->get_value('politician_id'),
                                }
                            )->count;
                            die \['entities', "could not find entity with id $entity_id"] if $count == 0;
                        }

                        return 1;
                    }
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

            if ($values{ignore} == 1 && $values{reply}) {
                die \['ignore', 'must not have reply'];
            } elsif ($values{ignore} == 0 && !$values{reply}) {
                die \['reply', 'missing'];
            }
            delete $values{ignore};

            my $access_token = $self->politician->fb_page_access_token;
            my $recipient    = $self->recipient;

            # Adicionando recipient à um grupo
            if ($values{groups}) {
                my @group_ids = @{ $values{groups} || [] };

                for my $group_id (@group_ids) {
                    $recipient->add_to_group($group_id);
                }

                delete $values{groups};
            }

            if ($values{reply}) {
                my $message;
                # Tratando se a mensagem tem mais de 100 chars
                if (length $self->message > 100) {
                    $message = substr $self->message, 0, 97;
                    $message = $message . "...";
                }
                else {
                    $message = $self->message;
                }

                $self->_httpcb->add(
                    url     => $ENV{FB_API_URL} . '/me/messages?access_token=' . $access_token,
                    method  => "post",
                    headers => 'Content-Type: application/json',
                    body    => encode_json {
                        messaging_type => "UPDATE",
                        recipient => {
                            id => $recipient->fb_id
                        },
                        message => {
                            text          => "Voc\ê enviou: " . $message . "\n\nResposta: " . $values{reply},
                            quick_replies => [
                                {
                                    content_type => 'text',
                                    title        => 'Voltar ao início',
                                    payload      => 'mainMenu'
                                }
                            ]
                        }
                    }
                );
            }

            $self->_httpcb->wait_for_all_responses();

            $self->update({
                %values,
                updated_at => \'NOW()',
            });
        }
    };
}

__PACKAGE__->meta->make_immutable;
1;
