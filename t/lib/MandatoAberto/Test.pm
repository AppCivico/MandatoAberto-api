package Mojo::Transaction::Role::PrettyDebug {
    use Mojo::Base -role;
    use Mojo::Util 'term_escape';

    use constant PRETTY => $ENV{TRACE} || $ENV{MOJO_CLIENT_PRETTY_DEBUG} || 0;

    after client_read => sub {
        my ( $self, $chunk ) = @_;
        my $url = $self->req->url->to_abs;
        my $err = $chunk =~ /1\.1\s[45]0/ ? '31' : '32';
        warn "\x{1b}[${err}m" . term_escape("-- Client <<< Server ($url)\n$chunk") . "\x{1b}[0m\n" if PRETTY;
    };

    around client_write => sub {
        my $orig  = shift;
        my $self  = shift;
        my $chunk = $self->$orig(@_);
        my $url   = $self->req->url->to_abs;
        warn "\x{1b}[32m" . term_escape("-- Client >>> Server ($url)\n$chunk") . "\x{1b}[0m\n" if PRETTY;
        return $chunk;
    };
};

package MandatoAberto::Test;
use Mojo::Base -strict;
use FindBin qw($RealBin);
use Test2::V0;
use Test2::Tools::Subtest qw(subtest_buffered subtest_streamed);
use Test::Mojo;

use DateTime;
use MandatoAberto::Utils;
use Data::Fake qw/ Core Company Dates Internet Names Text /;
use Data::Printer;
use Mojo::Util qw(monkey_patch);
use Mojo::JSON qw(to_json encode_json decode_json true false);

sub import {
    strict->import;

    no strict 'refs';

    my $caller = caller;

    while (my ( $name, $symbol ) = each %{ __PACKAGE__ . '::' }) {
        next if $name eq 'BEGIN';
        next if $name eq 'import';
        next unless *{$symbol}{CODE};

        my $imported = $caller . '::' . $name;
        *{$imported} = \*{$symbol};
    }
}

my $t = Test::Mojo->with_roles('+StopOnFail')->new('MandatoAberto');
$t->ua->on(
    start => sub {
        my ( $ua, $tx ) = @_;
        $tx->with_roles('Mojo::Transaction::Role::PrettyDebug');
    }
);

sub test_instance { $t }
sub t             { $t }

sub app { $t->app }

sub get_schema { $t->app->schema }

sub resultset { get_schema->resultset(@_) }

sub db_transaction (&) {
    my ($code) = @_;

    my $schema = get_schema;
    eval {
        $schema->txn_do(
            sub {
                $code->();
                die "rollback\n";
            }
        );
    };
    die $@ unless $@ =~ m{rollback};
}

sub api_auth_as {
    my (%args) = @_;

    my $user_session;
    if (exists $args{user_id}) {
        my $user_id = $args{user_id};

        my $schema = get_schema;
        my $user = $schema->resultset('User')->find($user_id);

        $user_session = $user->new_session();

        $t->ua->on(start => sub {
            my ($ua, $tx) = @_;
            $tx->req->headers->header('X-API-Key' => $user_session->{api_key});
        });
    }
    elsif (exists $args{nobody}) {
        $t->ua->on(start => sub {
            my ($ua, $tx) = @_;
            $tx->req->headers->remove('X-API-Key');
        });
    }
    else {
        die __PACKAGE__ . ": invalid params for 'api_auth_as'";
    }

    return $user_session;
}

sub create_user {
    my (%args) = @_;

    my $email = fake_email->();

    my $t = test_instance;

    my $res = $t->post_ok(
        '/user',
        form => {
            name     => fake_name->(),
            email    => $email,
            password => fake_words(2)->(),
            %args
        },
      )
      ->status_is(201)
      ->json_has('/id')
      ->tx->res->json;

    my $user = resultset('User')->find($res->{id});

    return $user;
}

1;

