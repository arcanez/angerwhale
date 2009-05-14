package Angerwhale::User::Anonymous;
use base qw(Angerwhale::User);
use Moose;

has 'id' => (isa => 'Str', is => 'ro', default => 0);
has 'fullname' => (isa => 'Str', is => 'ro', default => 'Anonymous Coward');
has 'email' => (isa => 'Str', is => 'ro', default => '');

no Moose;
__PACKAGE__->meta->make_immutable;

=head1 NAME

Angerwhale::User::Anonymous - an anonymous uesr

=head1 SYNOPSIS

User that is un authenticated, like slashdot's Anonymous Coward.

=head1 METHODS

=head2 new

Create a new user

=head2 id

0

=head2 fullname

Anonymous Coward

=head2 email

(nothing)

=cut

1;

