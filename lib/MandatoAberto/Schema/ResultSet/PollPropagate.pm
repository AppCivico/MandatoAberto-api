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
                        my $groups = $_[0]->get_value('groups');

                        for (my $i = 0; $i < @{ $groups }; $i++) {
                            my $group_id = $groups->[$i];

                            my $group = $self->result_source->schema->resultset("Group")->search(
                                {
                                   'me.id'            => $group_id,
                                   'me.politician_id' => $_[0]->get_value('politician_id'),
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

            my $campaign = $self->result_source->schema->resultset("Campaign")->create( { type_id => 1 } );
            $values{campaign_id} = $campaign->id;

            my $politician   = $self->result_source->schema->resultset("Politician")->find($values{politician_id});
            my $access_token = $politician->fb_page_access_token;

            my $poll_id                 = $values{poll_id};
            my $poll_question_option_rs = $self->result_source->schema->resultset("PollQuestionOption");
            my @poll_question_options   = $poll_question_option_rs->search(
                { 'poll.id' => $poll_id },
                { prefetch => [ 'poll_question' , { 'poll_question' => "poll" } ] }
            )->all();

            my $question      = $poll_question_options[0]->poll_question->content;
            my $first_option  = $poll_question_options[0];
            my $second_option = $poll_question_options[1];

            # Depois de criada a messagem direta, devo adicionar uma entrada
            # na fila para cada recipient atrelado ao rep. público
            # levando em consideração os grupos, se adicionados
            my @group_ids = @{ $values{groups} || [] };
            my $recipient_rs = $politician->recipients
                ->only_opt_in
                ->search_by_group_ids(@group_ids)
                ->search(
                    {},
                    {
                        '+select' => [ \"COUNT(1) OVER(PARTITION BY 1)" ],
                        '+as'     => [ 'total' ],
                    }
                )
            ;

            while (my $recipient = $recipient_rs->next()) {
                # Mando para o httpcallback

                if (is_test()) {
                    next;
                } else {
                    $self->_httpcb->add(
                        url     => $ENV{FB_API_URL} . '/me/messages?access_token=' . $access_token,
                        method  => "post",
                        headers => 'Content-Type: application/json',
                        body    => encode_json {
                            recipient => {
                                id => $recipient->fb_id
                            },
                            message => {
                                text          => $question,
                                quick_replies => [
                                    {
                                        content_type => 'text',
                                        title        => $first_option->content,
                                        payload      => 'pollAnswerPropagate_' . $first_option->id
                                    },
                                    {
                                        content_type => 'text',
                                        title        => $second_option->content,
                                        payload      => 'pollAnswerPropagate_' . $second_option->id
                                    },
                                ]
                            }
                        }
                    );

                    $values{count} //= $recipient->get_column('total');
                }
            }

            if (!$values{count}) {
                $values{count} = 0;
            }

            $self->_httpcb->wait_for_all_responses();

            return $self->create(\%values);
        }
    };
}

sub _build__httpcb { WebService::HttpCallback::Async->instance }

1;