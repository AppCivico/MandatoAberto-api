package MandatoAberto::Worker::PollNotification;
use common::sense;
use Moose;

with "MandatoAberto::Worker";

use WebService::Facebook;

has timer => (
    is      => "rw",
    default => 60,
);

has facebook => (
    is      => "ro",
    isa     => "WebService::Facebook",
    default => sub { WebService::Facebook->new() },
);

has schema => (
    is       => "rw",
    required => 1,
);

sub listen_queue {
    my $self = shift;

    $self->logger->debug("Buscando itens na fila...") if $self->logger;

    my @items = $self->schema->resultset('PollSelfPropagationQueue')->search( { sent => 0 } )->all;

    if (@items) {
        $self->logger->info(sprintf("'%d' itens serão processados.", scalar @items)) if $self->logger;

        for my $item (@items) {
            $self->exec_item($item);
        }

        $self->logger->info("Todos os items foram processados com sucesso") if $self->logger;
    }else {
        $self->logger->debug("Não há itens pendentes na fila.") if $self->logger;
    }
}


sub run_once {
    my ($self, $item_id) = @_;

    my $item;
    if (defined($item_id)) {
        $item = $self->schema->resultset('PollSelfPropagationQueue')->find($item_id);
    }else {
        $item = $self->schema->resultset('PollSelfPropagationQueue')->search(
            undef,
            {
                rows   => 1,
            },
        )->next;
    }

    if ($item) {
        return $self->exec_item($item);
    }
    return 0;
}


sub exec_item {
    my ($self, $item) = @_;

    my $recipient = $item->recipient;

    $self->logger->info("Enviando enquete para recipient") if $self->logger;

    my %opts = (
        access_token => $item->poll->politician->fb_page_access_token,
        content      => $item->poll->build_content_object( $recipient )
    );

    print STDERR "\n" . $opts{content} . "\n";

    if ( $self->facebook->send_message(%opts) ) {
        $item->delete();
        $self->logger->info("Enviado com sucesso") if $self->logger;
        return 1;
    }

    return 0;
}

__PACKAGE__->meta->make_immutable;

1;
