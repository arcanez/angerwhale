# Signature.pm
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Signature;
use strict;
use warnings;
use Crypt::GpgME;
use Angerwhale::User::Anonymous;
use File::Attributes qw(get_attribute set_attribute);
use Carp;
use YAML::Syck;

=head1 METHODS

=head2 signor

Returns the key id of the message's signor, or 0 if the message is not
signed.

=cut

sub signor {
    my $self = shift;
    my ( $result, $plain ) = $self->_signed_text( $self->raw_text(1) );
    return lc($result->{signatures}->[0]->{fpr});
}

=head2 signed

Returns true if the signature is good, false otherwise.

More detail:

=over 4

=item C<1> 

means the signature was actually checked

=item C<2>

means "signed=yes" was read as an attribute from cache

=item C<0>

BAD SIGNATURE!

=item C<undef>

message was not signed

=back

=cut

sub signed {
    my $self     = shift;
    my $raw_text = $self->raw_text(1);
    return if $self->raw_text eq $raw_text;

    my $result = eval {

        my $signed = $self->_cached_signature;

        if ( defined $signed && $signed eq "yes" ) {

            # good signature
            return 2;
        }

        my $id;
        if ( $id = $self->_check_signature( $self->raw_text(1) ) ) {

            # and fix the author info if needed
            $self->_cache_signature;
            $self->_fix_author($id);
            return 1;
        }
        else {
            die "Bad signature";
        }
    };

    return 0 if $@;
    return $result;
}

=head2 _check_signature($message)

Checks the pgp signature on $message.  Returns the fingerprint
if the signature is valid.  Raises an exception on error.

=cut

sub _check_signature {
    my ( $self, $message ) = @_;

    my ( $result, $plain ) = eval { Crypt::GpgME->new->verify( $message ) };

    die "$@" if !defined $plain or $@;

    return $plain ? lc($result->{signatures}->[0]->{fpr}) : 0;
}

=head2 signed_text($message)

Given PGP-signed $message, returns the plaintext of that message.
Throws an exception on error.

In array context, returns an list (plain, result), where plain is a
plaintext representtion of $message and result is a hash containing
signature information

=cut

sub _signed_text {
    my ( $self, $message ) = @_;

    my ( $result, $plain ) = eval { Crypt::GpgME->new->verify( $message ) };

    croak "$@" if !defined $plain or $@;

    return wantarray ? ( $plain, $result ) : $plain;
}

=head1 _cached_signature

Returns the cached signature; true for "signature ok", false for
"signature not ok" (or no signature).

=cut

sub _cached_signature {
    my $self = shift;
    return eval { get_attribute( $self->location, 'signed' ) };
}

=head1 _cached_signature

Sets the cached signature to true.

=cut

sub _cache_signature {
    my $self = shift;

    # set the "signed" attribute
    set_attribute( $self->location, 'signed', "yes" );
}

# if a user posts a comment with someone else's key, ignore the login
# and base the author on the signature

sub _fix_author {
    my ( $self, $id ) = @_;

    set_attribute( $self->location, 'author', $id );
}

1;
