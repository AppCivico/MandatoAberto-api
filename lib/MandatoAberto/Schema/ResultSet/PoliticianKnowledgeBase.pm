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
                    max_lenght => 300
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

                if ( $values{saved_attachment_id} ) {
                    die \['saved_attachment_type', 'missing'] unless $values{saved_attachment_type};
                }

                my $active_knowledge_base_entry = $self->search(
                    {
                        politician_id => $values{politician_id},
                        entities      => "{@entities}",
                    }
                )->next;

                if ( $active_knowledge_base_entry ) {
                    die \['politician_id', 'politician alredy has knowledge base for that entity']
                }

                $politician_knowledge_base = $self->create(
                    {
                        %values,
                        entities => "{@entities}"
                    }
                );
            });

            return $politician_knowledge_base;
        },
    };
}

sub get_knowledge_base_by_entity_name {
    my ($self, @entity_names) = @_;

    my $politician_entity_rs = $self->result_source->schema->resultset('PoliticianEntity');

    my @ids = map { $_->id } $politician_entity_rs->search( { name => { -in => \@entity_names } } )->all;

    return $self->search(
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

1;
