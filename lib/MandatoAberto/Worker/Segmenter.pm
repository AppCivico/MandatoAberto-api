package MandatoAberto::Worker::Segmenter;
use common::sense;
use Moose;

with 'MandatoAberto::Worker';

use DDP;

has timer => (
    is      => "rw",
    default => 60,
);

has schema => (
    is       => "rw",
    required => 1,
);

sub listen_queue {
    my $self = shift;

    $self->logger->debug("Buscando itens na fila...") if $self->logger;

    my @items = $self->schema->resultset('Group')->search(
        { 'me.status' => 'processing' },
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
    my ($self, $group_id) = @_;

    my $group_rs = $self->schema->resultset('Group')->search( { 'me.status' => 'processing' }, { for => 'update' } );

    my $group;
    if ($group_id) {
        $group = $group_rs->search( { 'me.id' => $group_id } )->next;
    }
    else {
        $group = $group_rs->search( {}, { rows => 1 } )->next;
    }

    if (ref $group) {
        return $self->exec_item($group);
    }

    return 0;
}

sub exec_item {
    my ($self, $group) = @_;

    $self->logger->info(sprintf("Contabilizando o grupo id '%d'.", $group->id)) if $self->logger;

    $self->schema->txn_do(sub {
        my $recipients_count;
        eval {
            $recipients_count = $group->update_recipients();
        };
        if ($@) {
            $self->logger->logdie(sprintf("Erro ao segmentar o grupo id '%d'!", $group->id)) if $self->logger;

            $group->update(
                {
                    recipients_count        => undef,
                    last_recipients_calc_at => \'NOW()',
                    status                  => \'error',
                },
            );
            return 0;
        }

        $group->update(
            {
                recipients_count        => int($recipients_count),
                last_recipients_calc_at => \'NOW()',
                status                  => 'ready',
            }
        );
    });

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;

