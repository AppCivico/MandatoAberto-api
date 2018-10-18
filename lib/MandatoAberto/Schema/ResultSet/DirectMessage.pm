package MandatoAberto::Schema::ResultSet::DirectMessage;
use common::sense;
use Moose;
use namespace::autoclean;

extends "DBIx::Class::ResultSet";

with "MandatoAberto::Role::Verification";
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use Data::Verifier;
use MandatoAberto::Utils;
use MandatoAberto::Types qw/URI/;
use MandatoAberto::Messager::Template;
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
                    required   => 1,
                    type       => "Int",
                    post_check => sub {
                        my $politician_id = $_[0]->get_value('politician_id');

                        $self->result_source->schema->resultset("Politician")->search( { user_id => $politician_id } )->count == 1;
                    }
                },
                content => {
                    required   => 0,
                    type       => "Str",
                    max_length => 1000,
                    post_check => sub {
                        my $content = $_[0]->get_value('content');
                        my $type    = $_[0]->get_value('type');

                        die \['content', 'must not send content if direct message type is attachment'] if $type eq 'attachment';

                        return 1;
                    }
                },
                name => {
                    required  => 0,
                    type      => "Str",
                    max_length => 50,
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
                type => {
                    required   => 1,
                    type       => 'Str',
                    post_check => sub {
                        my $type    = $_[0]->get_value('type');
                        my $content = $_[0]->get_value('content');

                        die \['type', 'invalid'] unless $type =~ m/^(text|attachment)$/;

                        if ( $type eq 'text' && !$content ) {
                            die \['content', 'missing']
                        }

                        return 1;
                    }
                },
                attachment_type => {
                    required   => 0,
                    type       => 'Str',
                    post_check => sub {
                        my $direct_message_type = $_[0]->get_value('type');
                        my $attachment_type     = $_[0]->get_value('attachment_type');

                        die \['attachment_type', 'not allowed when direct message type is text'] if $direct_message_type eq 'text';

                        die \['attachment_type', 'invalid'] unless $attachment_type =~ m/^(image|audio|file|video|template)$/;

                        return 1;
                    }
                },
                attachment_template => {
                    required   => 0,
                    type       => 'Str',
                    post_check => sub {
                        my $attachment_type     = $_[0]->get_value('attachment_type');
                        my $attachment_template = $_[0]->get_value('attachment_template');

                        die \['attachment_template', 'not allowed unless attachment type is template'] unless $attachment_type eq 'template';

                        die \['attachment_template', 'invalid'] unless $attachment_type =~ m/^(generic|button|receipt|list)$/;

                        return 1;
                    }
                },
                attachment_url => {
                    required   => 0,
                    type       => URI,
                    post_check => sub {
                        my $direct_message_type = $_[0]->get_value('type');
                        my $attachment_url      = $_[0]->get_value('attachment_url');

                        die \['attachment_url', 'not allowed when direct message type is text'] if $direct_message_type eq 'text';

                        return 1;
                    }
                },
                saved_attachment_id => {
                    required => 0,
                    type     => 'Str'
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

            my $direct_message;
            $self->result_source->schema->txn_do(sub{
                my $politician_id = delete $values{politician_id};
                my $politician    = $self->result_source->schema->resultset("Politician")->find($politician_id);

                my $access_token = $politician->fb_page_access_token;
                die \['politician_id', 'politician does not have active Facebook page access_token'] unless $access_token;

                my $campaign = $politician->campaigns->create(
                    {
                        type_id => 1,
                        count   => 0,
                        groups  => delete $values{groups}
                    }
                );
                $values{campaign_id} = $campaign->id;

                $direct_message = $self->create(\%values);
            });

            return $direct_message;
        }
    };
}


sub _build__httpcb { WebService::HttpCallback::Async->instance }

1;
