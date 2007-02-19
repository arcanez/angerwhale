#!/usr/bin/perl
# PreviewComment.pm
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::ContentItem::PreviewComment;
use strict;
use warnings;
use base qw(Angerwhale::ContentItem::Comment Class::Accessor);
use Angerwhale::User::Anonymous;
use Angerwhale::Format;
use Carp;

__PACKAGE__->mk_accessors(
    qw|title preview_body type
      cache userstore context|
);

=head1 PreviewComment

A fake comment to display to the user as a preview.  Backed
by memory instead of a file, but otherwise works like a 
regular comment (formatting, PGP, etc. works).

=head1 METHODS

=head2 new({body => ..., cache => ..., userstore => ...})

All args are required.  Body is the text to format.  Cache is the
cache object C<< $c->cache >> (so that if the user submits the comment
unmodified we don't have to recache it).  userstore is
C<< $c->model('UserStore') >> so we can look up PGP info.

=cut

sub new {
    my $class = shift;
    my $self  = shift;
    bless $self, $class;

    $self->{type} ||= 'text';
    $self->preview_body( $self->{body} );
    $self->cache( $self->context->cache );
    $self->userstore( $self->context->model('UserStore') );
    
    return $self;
}

sub creation_time {
    return time();
}

sub modification_time {
    return $_[0]->creation_time;
}

sub raw_text {
    my $self     = shift;
    my $want_pgp = shift;
    return $self->SUPER::raw_text( $want_pgp, $self->preview_body );
}

sub uri {
    my $self = shift;
    return;
}

# a few hacks here to prevent setting attributes on this fake comment

sub _fix_author {
    # no-op
}

sub _cached_signature {
    return;
}

sub _cache_signature {
    # i'll get right on that...
}

sub author {
    my $self = shift;
    my $user = $self->context->stash->{user};
    if ( defined $user && $user->can('nice_id') ) {
        return $user;
    }
    elsif ( $self->signed ) {
        my $id = $self->signor;
        return $self->userstore->get_user_by_real_id($id);
    }
    else {
        return Angerwhale::User::Anonymous->new;
    }
}

sub id {
    return q!??!;
}

# XXX: hack

sub _format {
    return if $_[0]->{_format};
    $_[0]->{_format} = 1;
    $_[0] = Angerwhale::Format::format($_[0]);
    return;
}

=head2 text

Invoke formatter, return HTML.

=head2 plain_text

Invoke formatter, return plain text.

=cut

sub text {
    my $self = shift;
    my $txt = shift;
    $self->{text} = $txt if $txt;
    $self->_format();
    return $self->{text};
}

sub plain_text {
    my $self = shift;
    my $txt = shift;
    $self->{plain_text} = $txt if $txt;
    $self->_format();
    return $self->{plain_text};
}

# here so that SUPER doesn't get called
sub comments      { }
sub comment_count { }
sub add_comment   { }
sub post_uri      { }
sub set_tag       { }
sub tags          { }
sub tag_count     { 0; }
sub name          { }
1;

__END__

=head2 creation_time 

Now

=head2 modification_time 

Now

=head2 uri 

Nothing

=head2 raw_text 

Passed body

=head2 uri 

Nothing

=head2 author 

Based on PGP, or Anonymous Coward otherwise

=head2 id

=head2 comment_count 

0

=head2 add_comment 

Disabled

=head2 set_tag 

Disabled

=head2 post_uri 

Nothing

=head2 comments 

C<[]>

=head2 tag_count 

0

=head2 tags

None

=head2 name 

None

=cut