# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Content::Filter::Checksum;
use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub filter {
    return 
      sub {
          my $self    = shift;
          my $context = shift;
          my $item    = shift;
          my $text    = $item->data;
          utf8::encode($text);
          $item->metadata->{checksum} = md5_hex($text);
          return $item;
      };
}

1;

