#!/usr/bin/perl
# PreviewComment.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Blog::Model::Filesystem::PreviewComment;
use strict;
use warnings;
use base qw(Blog::Model::Filesystem::Comment);
use Blog::DateFormat;
use Blog::User::Anonymous;

sub new {
    my $class = shift;
    
    my $c     = shift;
    my $title = shift;
    my $body  = shift;
    my $type  = shift;
    
    my $self = {
		context => $c,
		title   => $title,
		body    => $body,
		type    => $type,
	       };
    
    bless $self, $class;
    
    return $self;
}

sub type {
    my $self = shift;
    return $self->{type};
}

sub creation_time {
    return Blog::DateFormat->now(time_zone => "America/Chicago");
}

sub modification_time {
    return $_[0]->creation_time;
}

sub raw_text {
    my $self = shift;
    my $want_pgp = shift;
    return $self->SUPER::raw_text($want_pgp, $self->{body});
}

sub title {
    my $self = shift;
    
    return $self->{title};
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
    
    return; 
}

sub checksum {
    return;
}

sub author {
    my $self = shift;
    my $user = $self->{context}->stash->{user};
    if (defined $user && $user->can('nice_id')){
	return $user;
    }
    elsif ($self->signed){
	my $id = $self->signor;
	return $self->{context}->model('UserStore')->get_user_by_real_id($id);
    }
    else {
	return Blog::User::Anonymous->new;
    }
}

sub id {
    return q!??!;
}

sub comments {}
sub comment_count {}
sub add_comment {}
sub post_uri {}
sub set_tag {}
sub tags {}
sub tag_count {0;}
sub name {}
1;
