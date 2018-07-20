package MandatoAberto::Schema::ResultSet::Campaign;
use common::sense;
use Moose;
use namespace::autoclean;

extends "DBIx::Class::ResultSet";

sub get_politician_campaign_reach_count {
    my ($self) = @_;

    my $sum = 0;
    while ( my $campaign = $self->next() ) {
        my $type = $campaign->type_id == 1 ? 'direct_message' : 'poll_propagate';

        $sum += $campaign->$type->count;
    }

    return $sum;
}

sub get_politician_campaign_reach_dm_count {
	my ($self) = @_;

	my $sum = 0;
	while ( my $campaign = $self->next() ) {

		$sum += $campaign->direct_message->count;
	}

	return $sum;
}

sub get_politician_campaign_reach_poll_propagate_count {
	my ($self) = @_;

	my $sum = 0;
	while ( my $campaign = $self->next() ) {

		$sum += $campaign->poll_propagate->count;
	}

	return $sum;
}

1;