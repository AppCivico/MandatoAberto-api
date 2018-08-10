package MandatoAberto::Schema::ResultSet::PoliticianKnowledgeBase;
use common::sense;
use Moose;
use namespace::autoclean;

extends "DBIx::Class::ResultSet";

with "MandatoAberto::Role::Verification";
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use Data::Verifier;


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
                # entities => {
                #     required   => 1,
                #     type       => 'ArrayRef[Int]',
                #     post_check => sub {
                #         my $entities = $_[0]->get_value('entities');

                #         for ( my $i = 0; $i < @{ $entities }; $i++ ) {
                #             my $entity_id = $entities->[$i];

                #             my $count = $self->result_source->schema->resultset('PoliticianEntity')->search(
                #                 {
                #                     id            => $entity_id,
                #                     politician_id => $_[0]->get_value('politician_id'),
                #                 }
                #             )->count;
                #             die \['entities', "could not find entity with id $entity_id"] if $count == 0;
                #         }

                #         return 1;
                #     }
                # }
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

            my $issue_rs = $self->result_source->schema->resultset('Issue');

            my @entities;
            for my $issue_id ( @{ $values{issues} } ) {
                my $issue = $issue_rs->find($issue_id);

                push @entities, $issue->entities
            }

            my $politician_knowledge_base = $self->create(
                {
                    %values,
                    entities => @entities
                }
            );
            return $politician_knowledge_base;
        },
    };
}

1;
