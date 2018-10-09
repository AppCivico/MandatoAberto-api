package MandatoAberto::Schema::ResultSet::ChatbotStep;
use common::sense;
use Moose;
use namespace::autoclean;

extends "DBIx::Class::ResultSet";

sub resultset {
    my $self = shift;

    return $self->result_source->schema->resultset(@_);
}

sub upsert_step {
    my ($self, $payload, $human_name) = @_;

    my $step = eval {
        $self->update_or_create(
            {
                payload    => $payload,
                human_name => $human_name
            },
            { key => 'chatbot_steps_payload_key' }
        )
    };

    die \['payload', 'invalid'] if $@;

    return $step;
}

1;