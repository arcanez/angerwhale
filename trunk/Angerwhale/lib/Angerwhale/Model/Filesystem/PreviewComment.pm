#!/usr/bin/perl
# PreviewComment.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Model::Filesystem::PreviewComment;
use strict;
use warnings;
use base qw(Angerwhale::Model::Filesystem::Comment Class::Accessor);
use Angerwhale::User::Anonymous;
use Carp;

__PACKAGE__->mk_accessors(qw|title preview_body type
			     cache userstore|);

sub new {
    my $class	 = shift;
    my $self     = shift;
    bless $self, $class;    
    
    $self->preview_body($self->{body});
    $self->cache($self->context->cache);
    $self->userstore($self->context->model('UserStore'));
    
    return $self;
}


sub creation_time {
    return time();
}

sub modification_time {
    return $_[0]->creation_time;
}

sub raw_text {
    my $self = shift;
    my $want_pgp = shift;
    return $self->SUPER::raw_text($want_pgp, $self->preview_body);
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

sub author {
    my $self = shift;
    my $user = $self->context->stash->{user};
    if (defined $user && $user->can('nice_id')){
	return $user;
    }
    elsif ($self->signed){
	my $id = $self->signor;
	return $self->context->model('UserStore')->
	  get_user_by_real_id($id);
    }
    else {
	return Angerwhale::User::Anonymous->new;
    }
}

sub id {
    return q!??!;
}

# here so that SUPER doesn't get called
sub comments {}
sub comment_count {}
sub add_comment {}
sub post_uri {}
sub set_tag {}
sub tags {}
sub tag_count {0;}
sub name {}
1;
