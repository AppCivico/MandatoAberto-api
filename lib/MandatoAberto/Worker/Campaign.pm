package MandatoAberto::Worker::Campaign;
use common::sense;
use Moose;

with 'MandatoAberto::Worker';

use DDP;

has timer => (
    is      => "rw",
    default => 10,
);

has schema => (
    is       => "rw",
    required => 1,
);

sub listen_queue {
    my $self = shift;

    $self->logger->debug("Buscando itens na fila...") if $self->logger;

    my @items = $self->schema->resultset('Campaign')->search(
        { 'me.status_id' => 1 },
        { for => 'update' }
    )->all;

    if (@items) {
        $self->logger->info(sprintf("'%d' itens serão processados.", scalar @items)) if $self->logger;

        for my $item (@items) {
            $self->exec_item($item);
        }

        $self->logger->info("Todos os items foram processados com sucesso") if $self->logger;
    }
    else {
        $self->logger->debug("Não há itens pendentes na fila.") if $self->logger;
    }
}

sub run_once {
    my ($self, $campaign_id) = @_;

    my $campaign_rs = $self->schema->resultset('Campaign')->search( { 'me.status_id' => 1 }, { for => 'update' } );

    my $campaign;
    if ($campaign_id) {
        $campaign = $campaign_rs->search( { 'me.id' => $campaign_id } )->next;
    }
    else {
        $campaign = $campaign_rs->search( {}, { rows => 1 } )->next;
    }

    if (ref $campaign) {
        return $self->exec_item($campaign);
    }

    return 0;
}

sub exec_item {
    my ($self, $campaign) = @_;

    $self->logger->info(sprintf("Contabilizando o grupo id '%d'.", $campaign->id)) if $self->logger;

    $self->schema->txn_do(sub {
        eval {
            $campaign->process_and_send();
        };
        if ($@) {
            $self->logger->logdie(sprintf("Erro ao enviar campanha id '%d'!", $campaign->id)) if $self->logger;

            # status_id 3 é 'error'
            $campaign->update(
                {
                    status_id  => 3,
                    updated_at => \'NOW()',
                },
            );
            return 0;
        }

        # status_id 3 é 'sent'
        $campaign->update(
            {
				status_id  => 2,
                updated_at => \'NOW()',
            }
        );
    });

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;

