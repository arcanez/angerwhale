# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Content::Filter::Author;
use strict;
use warnings;
use Angerwhale::User::Anonymous;

=head2 filter

Adds author information.

=cut

sub filter {
    return
      sub {
          my ( $self, $context, $item ) = @_;

          my $id = $item->metadata->{raw_author} = $item->metadata->{author};
          my $author = eval {
              $context->model('UserStore')->get_user_by_id($id)
                if $id;
          };
          $author ||= Angerwhale::User::Anonymous->new;
          $item->metadata->{author} = $author;
          return $item;
      };
}


1;

