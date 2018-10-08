package MandatoAberto::Schema::ResultSet::Log;
use common::sense;
use Moose;
use namespace::autoclean;

use DateTime::Format::DateParse;

extends "DBIx::Class::ResultSet";

with "MandatoAberto::Role::Verification";
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use Data::Verifier;

sub resultset {
	my $self = shift;

	return $self->result_source->schema->resultset(@_);
}

sub verifiers_specs {
    my $self = shift;

    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                timestamp => {
                    required   => 1,
                    type       => 'Str',
                },
                politician_id => {
                    required   => 1,
                    type       => 'Int',
                    post_check => sub {
                        my $politician_id = $_[0]->get_value('politician_id');

                        $self->result_source->schema->resultset('Politician')->search( { 'me.user_id' => $politician_id } )->count;
                    }
                },
                recipient_fb_id => {
                    required   => 1,
                    type       => "Str",
                    post_check => sub {
                        my $recipient_fb_id = $_[0]->get_value('recipient_fb_id');
                        my $politician_id   = $_[0]->get_value('politician_id');

                        $self->result_source->schema->resultset("Recipient")->search(
                            {
                                'me.fb_id'         => $recipient_fb_id,
                                'me.politician_id' => $politician_id
                            }
                        )->count;
                    }
                },
                action_id => {
                    required   => 1,
                    type       => "Int",
                    post_check => sub {
                        my $action_id = $_[0]->get_value('action_id');

                        $self->result_source->schema->resultset("LogAction")->search( { 'me.id' => $action_id } )->count;
                    }

                },
                field_id => {
                    required => 0,
                    type     => 'Int'
                },
                payload => {
                    required => 0,
                    type     => 'Str'
                },
                human_name => {
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

            my $log;
            $self->result_source->schema->txn_do(sub {
                # Tratando timestamp
                my $ts = DateTime::Format::DateParse->parse_datetime($values{timestamp});

				die \['timestamp', 'invalid'] unless $ts;

                $values{timestamp} = $ts;

                # Tratando recipient_fb_id
                my $recipient_fb_id = delete $values{recipient_fb_id};
                my $recipient       = $self->result_source->schema->resultset('Recipient')->search( { fb_id => $recipient_fb_id } )->next;

                $values{recipient_id} = $recipient->id;

                # Tratando field_id e payload/human_name
                my $action = $self->resultset('LogAction')->find( $values{action_id} );

                if ($action->has_field) {
                    my $field_id = $values{field_id};

                    my $rs;
                    if ( $action->name eq 'WENT_TO_FLOW' ) {

                        $rs = $self->resultset('ChatbotStep');

                        my @required = qw( payload human_name );
                        defined $values{$_} or die \["$_", 'missing'] for @required;

                        my $field = $rs->upsert_step( delete $values{payload}, delete $values{human_name} );
                        die \['payload', 'internal server error'] unless $field;

                        $values{field_id} = $field->id;
                    }
                    elsif ( $action->name eq 'ANSWERED_POLL' ) {
                        $rs = $self->resultset('PollQuestionOption');

						my @required = qw( field_id );
						defined $values{$_} or die \["$_", 'missing'] for @required;

                        my $field = $rs->find($field_id);
                        die \['field_id', 'invalid'] unless $field;
                    }
					elsif ( $action->name eq 'ASKED_ABOUT_ENTITY' ) {
						$rs = $self->resultset('PoliticianEntity');

						my @required = qw( field_id );
						defined $values{$_} or die \["$_", 'missing'] for @required;

						my $field = $rs->find($field_id);
						die \['field_id', 'invalid'] unless $field;
					}
                    else {
                        die \['action_id', 'invalid'];
                    }

                }
                else {
                    die \['field_id', 'invalid'] if $values{field_id};
                }

                $log = $self->create(\%values);
            });

            return $log;
        }
    };
}

1;