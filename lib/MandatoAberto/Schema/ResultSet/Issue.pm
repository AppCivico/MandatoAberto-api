package MandatoAberto::Schema::ResultSet::Issue;
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
                    post_check => sub {
                        my $politician_id = $_[0]->get_value('politician_id');

                        $self->result_source->schema->resultset("Politician")->search({ user_id => $politician_id })->count;
                    }
                },
                recipient_id => {
                    required => 1,
                    type     => "Int"
                },
                message => {
                    required   => 1,
                    type       => "Str",
                },
                entities => {
                    required   => 1,
                    type       => 'HashRef'
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

            my $issue;
        	$self->result_source->schema->txn_do(sub {
                # Uma issue sempre é criada como aberta
                $values{open} = 1;

                my $politician = $self->result_source->schema->resultset('Politician')->find( $values{politician_id} );

                my $entity_val = $values{entities};
                my @entities_id;
                #$politician->politician_entities->search(
                 #   {  },
                #    { prefetch => [ 'entity', 'sub_entity' ] }
                #);

                my @entities = keys %{ $entity_val };
                for my $entity ( @entities ) {
                    my $upsert_entity = $politician->politician_entities->find_or_create(
                        {
                            sub_entity_id => undef,
                            entity        => { name => $entity },
                        }
                    );

                    push @entities_id, $upsert_entity->id;

                    if ( scalar @{ $entity_val->{$entity} } > 0 ) {
                        for my $sub_entity ( @{ $entity_val->{$entity} } ) {

                            my $upsert_sub_entity = $politician->politician_entities->find_or_create( { sub_entity  => { name => ['foo', 'bar'] } } );
                            use DDP; p $upsert_sub_entity; p $sub_entity;
                            push @entities_id, $upsert_sub_entity->id;
                        }
                    }
                }

                use DDP; p \@entities_id;
                $issue = $self->create(\%values);
            });

            return $issue;
        }
    };
}

sub get_politician_open_issues {
    my ($self) = @_;

    return $self->search( { open => 1 } );
}

sub get_open_issues_created_today {
    my ($self) = @_;

    return $self->search(
        {
            open       => 1,
            created_at => { '>=' => "yesterday()" }
        }
    );
}

1;