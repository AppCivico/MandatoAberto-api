package MandatoAberto::Controller;
use Mojo::Base 'Mojolicious::Controller';

use Moose::Role;
use Moose::Util::TypeConstraints;
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

        $c->app->log->error( Dumper $an_error->message, @other_errors );

        return $c->render(
            json   => { error => "Internal server error" },
            status => 500,
        );
    }
}



sub validate_request_params {
    my ($c, %fields) = @_;

    foreach my $key (keys %fields) {
        my $me   = $fields{$key};
        my $type = $me->{type};

        my $val  = $c->req->params->to_hash->{$key};
        $val = '' if !defined $val && $me->{clean_undef};
        if (!defined $val && $me->{required} && !( $me->{undef_is_valid} && !defined $val ) ) {
            $c->render(
                json   => { error => 'form_error', form_error => { $key => 'missing' } },
                status => 400,
            );
            return $c->detach();
        }

        if (
               defined $val
            && $val eq ''
            && (   $me->{empty_is_invalid}
                || $type eq 'Bool'
                || $type eq 'Int'
                || $type eq 'Num'
                || ref $type eq 'MooseX::Types::TypeDecorator' )
          ) {

            $c->render(
                json   => { error => 'form_error', form_error => { $key => 'empty_is_invalid' } },
                status => 400,
            );
            return $c->detach;
        }

        next unless $val;

        my $cons = Moose::Util::TypeConstraints::find_or_parse_type_constraint($type);

        if (!defined $cons) {
            $c->render(
                json   => { error => 'form_error', error => "Unknown type constraint '$type'" },
                status => 400,
            );
            return $c->detach;
        }

        if ( !$cons->check($val) ) {
            $c->render(
                json   => { error => 'form_error', form_error => { $key => 'invalid' } },
                status => 400,
            );
            return $c->detach;
        }
    }
}

1;
