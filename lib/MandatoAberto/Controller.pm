package MandatoAberto::Controller;
use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

sub reply_not_found {
    my $c = shift;

    return $c->render(
        json   => { error => 'Page not found' },
        status => 404
    );
}

sub reply_exception {
    my $c   = shift;
    my $err = shift;

    $err = [ $err ];
    if (scalar( @{ $err } )) {
        my ($an_error, @other_errors) = @{ $err };

        if (ref $an_error eq 'DBIx::Class::Exception' && $an_error->{msg} =~ /duplicate key value violates unique constraint/) {
            $c->log->info('Exception treated: ' . $an_error->{msg});

            return $c->render(
                json   => { error => 'You violated an unique constraint! Please verify your input fields and try again.' },
                status => 400,
            );
        }
        elsif (ref $an_error eq 'DBIx::Class::Exception' && $an_error->{msg} =~ /is not present/) {
            my ($match, $value) = $an_error->{msg} =~ /Key \((.+?)\)=(\(.+?)\)/;

            return $c->render(
                json   => { form_error => ( { $match => 'value=' . $value . ') cannot be found on our database' } ) },
                status => 400,
            );
        }
        elsif (ref $an_error eq 'HASH' && $an_error->{error_code}) {
            $c->log->info( 'Exception treated: ' . $an_error->{msg} );

            return $c->render(
                json   => { error => $an_error->{message} },
                status => $an_error->{error_code} || 500,
            );
        }
        elsif (ref $an_error eq 'REF' && ref $$an_error eq 'ARRAY' && @$$an_error == 2) {
            return $c->render(
                json   => { form_error => ( { $$an_error->[0] => $$an_error->[1] } ) },
                status => 400,
            );
        }

        $c->app->log->error( Dumper $an_error->message->message, @other_errors );

        return $c->render(
            json   => { error => "Internal server error" },
            status => 500,
        );
    }
}

1;
