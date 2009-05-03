# PGPAuthor.pm 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Content::Filter::PGP;
use Angerwhale::Signature;
use Crypt::GpgME;
use Encode;
use strict;
use warnings;

=head2 filter

Convert PGP-encoded body to plain text equivalent, and store raw text
in the metadata area as C<raw_text>.

If the signature is valid (or cached), set the C<author> metadata item
appropriately.

=cut

sub filter {
    return 
      sub {
          my ( $self, $context, $item ) = @_;

          my $text;
          eval {
              # PGP wants octets, not characters
              my $data = $item->data;
              $data = Encode::encode('utf8', $data) if utf8::is_utf8($data);
              $text = Angerwhale::Signature->_signed_text($data);
              $text = Encode::decode('utf8', $text) if !utf8::is_utf8($text);
          };
          
          if($text){
              $item->metadata->{raw_text} = $item->data;
              $item->data($text);
          }
          else {
              return $item; # we're done.  nothing to do.
          }

          if($item->metadata->{raw_author} && $item->metadata->{signed} eq 'yes') {
              # signature is cached, so restore user without checking sig
              $item->metadata->{author} = $context->model('UserStore')->get_user_by_id($item->metadata->{raw_author});
              $item->metadata->{signor} = $item->metadata->{raw_author};
          }
          else {
              # no cached signature, check the signature
              my $author = get_user_signature($item->metadata->{raw_text});
              
              if(!$author) {
                  # bad signature!
                  $item->metadata->{author} = Angerwhale::User::Anonymous->new;
              }
              else {
                  # good signature
                  # cache the signature so we don't have to verify again
                  $item->store_attribute('signed', 'yes');
                  $item->store_attribute('author', $author);
                  $item->metadata->{raw_author} = $item->metadata->{author};
                  
                  # setup the "inflated" author
                  $item->metadata->{author} = $context->model('UserStore')->get_user_by_id($author);
                  $item->metadata->{signor} = $author;
              }
          }
          
          return $item;
      };
}

=head2 get_user_signature

Returns keyid of signature, or false if the signature is invalid.

=cut

sub get_user_signature {
    my $message = shift;

    my ( $result, $plain ) = eval { Crypt::GpgME->new->verify( $message ) };
    
    die "$@" if !defined $plain or $@;
    return $plain ? lc($result->{signatures}->[0]->{fpr}) : 0;
}

1;
