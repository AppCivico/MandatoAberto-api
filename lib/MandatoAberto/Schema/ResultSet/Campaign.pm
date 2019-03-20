package MandatoAberto::Schema::ResultSet::Campaign;
use common::sense;
use Moose;
use namespace::autoclean;

extends "DBIx::Class::ResultSet";

sub get_politician_campaign_reach_count {
    my ($self) = @_;

    my $rs = $self->search(undef);

    my $sum = 0;
    while ( my $campaign = $rs->next ) {
        my $type = $campaign->type_id == 1 ? 'direct_message' : 'poll_propagate';

        $sum += $campaign->count if $campaign->$type;
    }

    return $sum;
}

sub get_politician_campaign_reach_dm_count {
    my ($self) = @_;

    my $rs = $self->search( { type_id => 1 } );

    my $sum = 0;
    while ( my $campaign = $rs->next() ) {

        $sum += $campaign->count if $campaign->direct_message;
    }

    return $sum;
}

sub get_politician_campaign_reach_poll_propagate_count {
    my ($self) = @_;

    my $rs = $self->search( { type_id => 2 } );

    my $sum = 0;
    while ( my $campaign = $rs->next() ) {

        $sum += $campaign->poll_propagate->count if $campaign->poll_propagate;
    }

    return $sum;
}

sub extract_metrics {
    my ($self, %opts) = @_;

    $self = $self->search_rs( { 'me.created_at' => { '>=' => \"NOW() - interval '$opts{range} days'" } } ) if $opts{range};

    return {
        # Contagem total de campanhas
        count             => $self->count,
        fallback_text     => 'Aqui ficam as métricas sobre as campanhas enviadas.',
        suggested_actions => [
            {
                alert             => '',
                alert_is_positive => 0,
                link              => '',
                link_text         => 'Ver campanhas'
            },
        ],
        sub_metrics => [
            # Métrica: alcance das campanhas
            (
                $self->count > 0 ?
                (
                    {
                        text              => $self->get_column('count')->sum ? $self->get_column('count')->sum . ' pessoas alcançadas' : undef,
                        suggested_actions => []
                    },
                ) : ( )
            )
        ]
    }
}

1;
