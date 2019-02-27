package MandatoAberto::Schema::ResultSet::PollPropagate;
use common::sense;
use Moose;
use namespace::autoclean;

extends "DBIx::Class::ResultSet";

with "MandatoAberto::Role::Verification";
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use Data::Verifier;
use MandatoAberto::Utils;
use WebService::HttpCallback::Async;

use JSON::MaybeXS;

has _httpcb => (
    is         => "ro",
    isa        => "WebService::HttpCallback::Async",
    lazy_build => 1,
);


sub verifiers_specs {
    my $self = shift;

    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                politician_id => {
                    required => 1,
                    type     => "Int",
                    post_check => sub {
                        my $politician_id = $_[0]->get_value("politician_id");
                        $self->result_source->schema->resultset("Politician")->search({ user_id => $politician_id })->count;
                    },
                },
                poll_id => {
                    required => 1,
                    type     => "Int",
                    post_check => sub {
                        my $poll_id = $_[0]->get_value("poll_id");
                        $self->result_source->schema->resultset("Poll")->search({ id => $poll_id })->count;
                    },
                },
                groups => {
                    required   => 0,
                    type       => "ArrayRef[Int]",
                    post_check => sub {
                        my $groups        = $_[0]->get_value('groups');
                        my $politician_id = $_[0]->get_value('politician_id');

                        my $politician = $self->result_source->schema->resultset('Politician')->find($politician_id);
                        my $organization_chatbot_id = $politician->user->organization_chatbot_id;

                        for (my $i = 0; $i < @{ $groups }; $i++) {
                            my $group_id = $groups->[$i];

                            my $group = $self->result_source->schema->resultset("Group")->search(
                                {
                                   'me.id'                      => $group_id,
                                   'me.organization_chatbot_id' => $organization_chatbot_id
                                }
                            )->next;

                            die \['groups', "group $group_id does not exists or does not belongs to this politician"] unless ref $group;
                            die \['groups', "group $group_id isn't ready"] unless $group->get_column('status') eq 'ready';
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

            $self->result_source->schema->txn_do( sub {
                my $politician_id        = delete $values{politician_id};
                my $politician           = $self->result_source->schema->resultset('Politician')->find($politician_id);
                my $organization_chatbot = $politician->user->organization_chatbot;

                my $campaign         = $organization_chatbot->campaigns->create( { type_id => 2, count => 0 } );
                $values{campaign_id} = $campaign->id;
            });

            return $self->create(\%values);
        }
    };
}

sub _build__httpcb { WebService::HttpCallback::Async->instance }

1;
