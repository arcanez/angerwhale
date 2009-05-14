package Angerwhale::Model::UserStore;

use base qw(Catalyst::Model);
use Moose;
use Angerwhale::User;
use File::Slurp qw(read_file write_file);
use Carp;

has 'update_interval' => (isa => 'Int', is => 'rw', default => 3600, lazy => 1);
has 'users_dir' => (isa => 'Str', is => 'rw', builder => '_users_dir');

sub BUILD {
    my $self = shift;

    my $dir = $self->users_dir;
    mkdir $dir;
    if ( !-d $dir || !-w _ ) {
      die "No user store at $dir";
    }
}

=head1 NAME

Angerwhale::Model::UserStore - Manages Blog users.

=head1 SYNOPSIS

Keeps track of the blog's users.

See also L<Angerwhale::User|Angerwhale::User>.  Note that users are cached; they
are refreshed from the keyserver according to the config's
C<update_interval> in seconds.  Defaults to one hour.

If a user exists, but a keyserver can't be contacted, the old data
will still be used.

=head1 CONFIGURATION

=head2 update_interval

Try to update user info from C<keyserver> after this many
seconds. Defaults to 3600, one hour.

=cut

=head1 METHODS

=head2 new

Called by Catalyst to create and initialize userstore.

=cut

sub _users_dir {
    my $self = shift;
  
    #return $self->_application->{config}->{base} . '/.users';
    return '/opt/local/Angerwhale/root/posts/.users';
}

=head2 create_user_by_id

Creates a new user in the user store
Returns the C<Angerwhale::User> on success, exception on failure.

=cut

sub create_user_by_id {
    my ( $self, $id ) = @_;
    return $self->get_user_by_id($id);
}

=head2 get_user_by_id

Retrieves the user, creating it if necessary.

=cut

sub get_user_by_id {
    my ( $self, $id ) = @_;

    my $dir          = $self->users_dir;
    my $base         = "$dir/$id";
    my $data         = {};

    $data->{id} = $id;
    eval { $data->{fullname}     = read_file("$base/fullname") };
    eval { $data->{fingerprint}  = read_file("$base/fingerprint") };
    eval { $data->{email}        = read_file("$base/email") };
    eval { $data->{last_updated} = read_file("$base/last_updated") || 0 };

    my $user = Angerwhale::User->new($data);

    my $outdated = ( ( time() - $data->{last_updated} ) > $self->update_interval );

    return $user if !$@ && !$outdated;

    # create a user if the data was bad
    # or it's time to update

    $user = Angerwhale::User->new({ id => $id });
    eval {
        $user->refresh;
        $self->store_user($user);
    };

    warn "Could not refresh or retrieve user $id: $@" if $@;
    die "User isn't of type Angerwhale::User" if !$user->isa('Angerwhale::User');
    
    return $user;
}
=cut
sub _user_ok {
    my $user = shift;
    die "no name"        if !$user->fullname;
    die "no email"       if !$user->email;
    die "no fingerprint" if !$user->id;
    return 1;
}
=cut

=head2 refresh_user

Refresh the user's details from the keyserver

=cut

sub refresh_user {
    my ( $self, $user ) = @_;

    $user->refresh;
    $self->store_user($user);
}

=head2 store_user

Write the user's data to disk, so that attributes can be
changed and so that the blog will work if the keyserver goes
offline.

=cut

sub store_user {
    my ( $self, $user ) = @_;

    my $dir = $self->users_dir;
    my $uid = $user->id;

    my $base = "$dir/$uid";
    mkdir $base                                  if !-d $base;
    die "couldn't create userdir $base for $uid" if !-d $base;
    eval {
        write_file( "$base/fullname",     $user->fullname );
        write_file( "$base/fingerprint",  $user->id );
        write_file( "$base/email",        $user->email );
        write_file( "$base/last_updated", time() );
    };
    if ($@) {
        die "Error writing user: $@";
    }

    return 1;
}

=head2 last_updated

Returns the time of the most recent refresh of all users.

=cut

sub last_updated {
    my ( $self, $user ) = @_;

    my $dir  = $self->users_dir;
    my $uid  = $user->id;
    my $base = "$dir/$uid";

    my $updated;
    eval { $updated = read_file("$base/last_updated"); };
    return $updated;
}

=head2 users

Returns a list of all the users (C<Angerwhale::Users>s) the system knows
about.  The users are refreshed if they've expired.

=cut

sub users {
    my $self = shift;

    my $dir  = $self->users_dir;
    my @users;
    opendir( my $dirhandle, $dir ) or die "Couldn't open $dir for reading";
    while ( my $uid = readdir $dirhandle ) {
        next if $uid =~ /^[.][.]?$/;    # .. and . aren't users :)
        eval {
            my $user = $self->get_user_by_id($uid);
            push @users, $user;
        };
    }
    return @users;

}

=head1 NAME

Angerwhale::Model::UserStore - Catalyst Model

=head1 SYNOPSIS

See L<Angerwhale>

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
