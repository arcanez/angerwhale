#!/usr/bin/perl
# Textile.pm
# Copyright (c) 2007 Florian Ragwitz <rafl@debian.org>

package Angerwhale::Format::Textile;
use strict;
use warnings;
use Text::Textile;

=head1 Angerwhale::Format::Textile

Format Textile formatted text into HTML.

=head1 METHODS

Standard methods implemented

=head2 new

=head2 can_format

Can format *.textile

=head2 types

Handles 'textile', which is Textile formatted text.

=head2 format

=head2 format_text

=cut

sub new {
    my $class = shift;

    my $textile = Text::Textile->new;
    $textile->charset('utf-8');

    my $self = \$textile;
    bless $self, $class;
}

sub can_format {
    my $self    = shift;
    my $request = shift;

    return 100 if defined $request && $request eq 'textile';
}

sub types {
    my $self = shift;
    return
        ({type        => 'textile',
          description => 'Textile formatted text'});
}

sub format {
    my $self = shift;
    my $text = shift;
    my $type = shift;

    return $$self->process($text);
}

1;

__END__

