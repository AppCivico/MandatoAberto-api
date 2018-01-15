package MandatoAberto::Worker::DirectMessage;
use common::sense;
use Moose;

with "MandatoAberto::Worker";

use MandatoAberto::Messager;

has timer => (
    is      => "rw",
    default => 60,
);

has messager => (
    is         => "ro",
    isa        => "MandatoAberto::Messager",
    lazy_build => 1,
);

has schema => (
    is       => "rw",
    required => 1,
);

sub listen_queue {
    my $self = shift;

    $self->logger->debug("Buscando itens na fila...") if $self->logger;

    my @items = $self->schema->resultset('DirectMessageQueue')->search(
        undef,
        {
            rows   => 20,
            column => [ qw(me.id me.direct_message_id) ],
        },
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
    my ($self, $item_id) = @_;

    my $item ;
    if (defined($item_id)) {
        $item = $self->schema->resultset('DirectMessageQueue')->find($item_id);
    }
    else {
        $item = $self->schema->resultset('DirectMessageQueue')->search(
            undef,
            {
                rows   => 1,
                column => [ qw(me.id me.content) ],
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

    my $direct_message       = $self->schema->resultset("DirectMessage")->find($item->direct_message_id);
    my $fb_page_access_token = $self->schema->resultset("Politician")->find($direct_message->politician_id)->fb_page_access_token;
    my @citizens             = $self->schema->resultset("Recipient")->search( { politician_id => $direct_message->politician_id } );

    $self->logger->debug($direct_message->content) if $self->logger;

    if ($self->messager->send($direct_message->content, $fb_page_access_token, @citizens)) {
        $item->delete();
        return 1;
    }

    return 0;
}

sub _build_messager {
    my $self = shift;

    return MandatoAberto::Messager->new( fb_api_url => $ENV{FB_API_URL} );
}

__PACKAGE__->meta->make_immutable;

1;
