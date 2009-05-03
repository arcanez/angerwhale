# User.pm
# Copyright (c) 2006 Jonathan T. Rockway

package Angerwhale::User;
use strict;
use warnings;
use Crypt::GpgME;
use Carp;

=head1 SYNOPSIS

Don't create an instance of this class directly; it's returned from
the UserStore when you need a user.

=head1 ACCESSORS

=head2 id

Returns the ID of the key as a 64-bit integer (actually, it returns
the binary representation of that integer as a string of eight bytes)

=cut

sub id {
    my $self = shift;
    return $self->{id};
}

=head2 _keyserver

Returns the name of the keyserver to refresh the key from.  Set when
initialized by UserStore.

=cut

sub _keyserver {
    my $self      = shift;
    my $keyserver = shift;
    $self->{keyserver} = $keyserver if $keyserver;
    return $self->{keyserver};
}

=head2 fullname

Returns the full name associated with the primary UID.

=cut

sub fullname {
    my ( $self, $id ) = @_;

    return $self->{fullname} if $self->{fullname};

    $id ||= $self->{id};
    my $name = eval { return ( $self->{fullname} = [grep { !$_->{invalid} && !$_->{revoked} } Crypt::GpgME->new->get_key($id)->uids]->[0]->{name} ) };

    return $@ ? 'Unknown Name' : $name;
}

=head2 email

Returns the e-mail address associated with the primary UID.

=cut

sub email {
    my ( $self, $id ) = @_;

    return $self->{email} if defined $self->{email};

    $id ||= $self->{id};
    my $email = eval { return ( $self->{email} = [grep { !$_->{invalid} && !$_->{revoked} } Crypt::GpgME->new->get_key($id)->uids]->[0]->{email} ) };

    return $@ ? 'Unknown Email' : $email;
}

=head2 photo

Returns the first photo block in the key.  NOT IMPLEMENTED.

=cut

sub photo {
    die "nyi";
}

=head2 refresh

Refreshes the key from the network.

=cut

sub refresh {
    my $self = shift;

    my $id  = $self->id;
    $self->{fullname}    = $self->fullname($id);
    $self->{email}       = $self->email($id);
    $self->{fingerprint} = $self->id;
#    $self->{photo} = $self->photo($id);
}

# only for testing
sub _new {
    my ( $class, $id ) = @_;
    my $user = {};
    die 'specify id' if !$id;
    $user->{id} = $id;
    $user = bless $user, $class;
    $user->_keyserver('stinkfoot.org');
    $user->refresh;
    return $user;
}

1;
