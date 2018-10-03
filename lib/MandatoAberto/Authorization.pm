package MandatoAberto::Authorization;
use strict;
use warnings;

sub user_privs {
    my ($self, $c) = @_;

    my $user = $c->current_user;
    if (ref $user) {
        return [ map { $_->role->get_column('name') } $user->user_roles->all() ];
    }
    return;
}

sub has_priv {
    my ($self, $c, $roles) = @_;

    my $user = $c->current_user;
    if (ref $user) {
        my @roles = 'ARRAY' eq ref $roles ? @{ $roles } : ($roles);
        my @user_roles = map { $_->role->get_column('name') } $user->user_roles->all();

        for my $role (@roles) {
            if( grep { $role eq $_ } @user_roles ) {
                return 1;
            }
        }
    }
    return 0;
}

sub is_role    { ... }
sub user_role  { ... }

sub fail_render {
    return {
        json   => { error => 'Forbidden' },
        status => 403,
    };
}

1;
