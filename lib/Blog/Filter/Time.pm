#!/usr/bin/perl
# Time.pm
# Copyright (c) 2006 Jonathan T. Rockway

package Blog::Filter::Time;
use strict;
use warnings;
use base qw(Template::Plugin::Filter);
use utf8;

my @daynames = qw(日 月 火 水 木 金 土);

# Historical note.  I am an idiot for using DateTime for this!!!

sub init {
    my $self = shift;
    $self->{ _DYNAMIC } = 1;

    # first arg can specify filter name
    $self->install_filter($self->{ _ARGS }->[0] || 'foobarfoo');
    
    return $self;
}

# converts seconds past the epoch, localtime, to a pretty string
sub filter {
    my ($self, $text, $args, $config) = @_;
    my $text   = shift;
    my $time   = [localtime($time)];
    my $year   = $time[5]+1900;
    my $month  = $time[4];
    my $day    = $time[3];
    my $wkday  = $time[6];
    
    my $hour   = $time[2];
    my $minute = $time[1]; 
    $minute = "0$minute" if $minute < 10;
    
    my $ampm   = ($hour < 11) ? "am" : "pm";
    $hour %= 12;
    $hour =~ s/^0+$/12/;
    
    $wkday = $daynames[$wkday%7];
    
    return "$month-$day-$year ($wkday) $hour:$minute $ampm";
}

1;
