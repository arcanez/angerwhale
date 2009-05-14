package Angerwhale::User;
use Moose;
use Crypt::GpgME;
use Carp;

has 'id' => (
    isa => 'Str', 
    is => 'rw', 
    required => 1
);

has 'fullname' => (
    isa => 'Str', 
    is => 'rw', 
    lazy => 1,
    builder => '_fullname',
);

has 'email' => (
    isa => 'Str',
    is => 'rw',
    lazy => 1,
    builder => '_email',
);

has 'photo' => (
    isa => 'Str',
    is => 'rw',
    required => 0
);

has 'last_updated' => (
    isa => 'Int',
    is => 'rw',
    lazy => 1,
    default => time(),
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub _fullname {
  my $self = shift;
  my $id = $self->id;
 
  my $name = eval { [grep { !$_->{invalid} && !$_->{revoked} } Crypt::GpgME->new->get_key($id)->uids]->[0]->{name} };
  $name = 'Unknown Name' if $@;

  return $name;
}

sub _email {
  my $self = shift;
  my $id = $self->id;

  my $email = eval { [grep { !$_->{invalid} && !$_->{revoked} } Crypt::GpgME->new->get_key($id)->uids]->[0]->{email} };
  $email = 'Unknown Email' if $@;

  return $email;
}

=head1 ACCESSORS

=head2 id

Returns the ID of the key as a 64-bit integer (actually, it returns
the binary representation of that integer as a string of eight bytes)

=cut

=head2 fullname

Returns the full name associated with the primary UID.

=cut

=head2 email

Returns the e-mail address associated with the primary UID.

=cut

=head2 photo

Returns the first photo block in the key.  NOT IMPLEMENTED.

=cut

=head2 refresh

Refreshes the key from the network.

=cut

sub refresh {
    my $self = shift;

    my $id  = $self->id;
    $self = Angerwhale::User->new({ id => $id });
#    $self->{fullname}    = $self->fullname($id);
#    $self->{email}       = $self->email($id);
#    $self->{fingerprint} = $self->id;
#    $self->{photo} = $self->photo($id);
}
