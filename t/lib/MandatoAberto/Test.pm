package MandatoAberto::Test;
use Test::More;
use Test::Mojo;

use Data::Fake qw/ Core Company Dates Internet Names Text /;
use Data::Printer;
use MandatoAberto::Utils;

sub import {
    strict->import;
    warnings->import;

    no strict 'refs';

    my $caller = caller;

    while (my ($name, $symbol) = each %{__PACKAGE__ . '::'}) {
        next if $name eq 'BEGIN';
        next if $name eq 'import';
        next unless *{$symbol}{CODE};

        my $imported = $caller . '::' . $name;
        *{$imported} = \*{$symbol};
    }
};

my $t = Test::Mojo->new('MandatoAberto');

sub test_instance { $t }

sub app { $t->app }

sub get_schema { $t->app->schema }

sub db_transaction (&) {
    my ($code) = @_;

    my $schema = get_schema;
    eval {
        $schema->txn_do(sub {
            $code->();
            die 'rollback';
        });
    };
    die $@ unless $@ =~ m{rollback};
};

sub api_auth_as {
    my (%args) = @_;

    my $user_id = $args{user_id} or die "missing 'user_id'";

    my $schema = get_schema;
    my $user = $schema->resultset('User')->find($user_id);

    my $user_session = $user->create_session();

    $t->ua->on(start => sub {
        my ($ua, $tx) = @_;

        $tx->req->headers->header( 'X-Api-Key' => $user_session->get_column('api_key') );
    });

    return $user_session;
}

sub create_politician {
    my (%opts) = @_;

    my %params = (
        email            => fake_email()->(),
        password         => 'foobarpass',
        name             => fake_name()->(),
        address_state_id => 26,
        address_city_id  => 9508,
        party_id         => fake_int(1, 35)->(),
        office_id        => fake_int(1, 8)->(),
        gender           => fake_pick(qw/F M/)->(),
        movement_id      => fake_int(1, 7)->(),
        %opts
    );

    return $t->post_ok(
        '/api/register/politician',
        form => {
            name                => 'add politician',
            automatic_load_item => 0,
            stash               => "politician",
            %params,
        },
    )
    ->status_is(201)
    ->json_has('/id');
}

1;

