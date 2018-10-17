package MandatoAberto::Schema::ResultSet::PoliticianKnowledgeBase;
use common::sense;
use Moose;
use namespace::autoclean;

extends "DBIx::Class::ResultSet";

with "MandatoAberto::Role::Verification";
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use Data::Verifier;
use List::Flatten;

sub verifiers_specs {
    my $self = shift;

    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                politician_id => {
                    required   => 1,
                    type       => "Int",
                },
                answer => {
                    required   => 0,
                    type       => 'Str',
                    max_lenght => 2000
                },
                saved_attachment_type => {
                    required => 0,
                    type     => 'Str'
                },
                saved_attachment_id => {
                    required => 0,
                    type     => 'Str'
                },
                entities => {
                    required   => 1,
                    type       => 'ArrayRef[Int]',
                    post_check => sub {
                        my $entity = $_[0]->get_value('entities');

                        for (my $i = 0; $i < @{ $entity }; $i++) {
                            my $entity_id = $entity->[$i];

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
                },
                type => {
                    required   => 1,
                    type       => 'Str',
                    post_check => sub {
                        my $type = $_[0]->get_value('type');

                        my $available_type = $self->result_source->schema->resultset('AvailableType')->search( { name => $type } )->next;
                        die \['type', 'invalid'] unless $available_type;

                        return 1;
                    }
                }
            }
        ),
    };
}


sub action_specs {
    my ($self) = @_;

    return {
        create => sub {
            my $r = shift;

            my %values = $r->valid_values;
            not defined $values{$_} and delete $values{$_} for keys %values;

            my $politician_knowledge_base;
            $self->result_source->schema->txn_do(sub{
                my @entities = @{ $values{entities} };

                my $politician = $self->result_source->schema->resultset('Politician')->find($values{politician_id});

                if ( $values{saved_attachment_id} ) {
                    die \['saved_attachment_type', 'missing'] unless $values{saved_attachment_type};
                }

                my $active_knowledge_base_entry = $self->search(
                    {
                        politician_id => $values{politician_id},
                        entities      => "{@entities}",
                        type          => $values{type}
                    }
                )->next;

                if ( $active_knowledge_base_entry ) {
                    $politician_knowledge_base = $active_knowledge_base_entry->update(
                        {
                            %values,
                            updated_at => \'NOW()',
                            entities   => \@entities,
                        }
                    );

                    # $politician->logs->create(
                    #     {
                    #         timestamp => \'NOW()',
                    #         action_id => 13,
                    #         field_id  => $politician_knowledge_base->id
                    #     }
                    # )
                }
                else {
                    $politician_knowledge_base = $self->create(
                        {
                            %values,
                            entities => \@entities,
                        }
                    );

                    # $politician->logs->create(
                    #     {
                    #         timestamp => \'NOW()',
                    #         action_id => 13,
                    #         field_id  => $politician_knowledge_base->id
                    #     }
                    # )
                }
            });

            return $politician_knowledge_base;
        },
    };
}

sub get_knowledge_base_by_entity_name {
    my ($self, @entity_names) = @_;

    my $politician_entity_rs = $self->result_source->schema->resultset('PoliticianEntity');

    my $ret;
    my @ids = map { $_->id } $politician_entity_rs->search( { name => { -in => \@entity_names } } )->all;

    if ( scalar @ids == 0 ) {
        $ret = $self->search( { 'me.id' => \'IN (0)' } );
    }
    else {
        $ret = $self->search(
            {
                '-or' => [
                    map {
                        my $entity_id = $_;
                        \[ "? = ANY(entities)", $entity_id ] ## no critic
                    } @ids
                ],
            },
            { prefetch => { 'politician' => 'politician_entities' } }
        );
    }

    return $ret
}

1;
