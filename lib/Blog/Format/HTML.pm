#!/usr/bin/perl
# HTML.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Blog::Format::HTML;
use strict;
use warnings;
use HTML::TreeBuilder;
use Scalar::Util qw(blessed);
use YAML;
use URI;

sub new {
    my $class = shift;
    my $self  = \my $scalar;
    bless $self, $class;
}

sub can_format {
    my $self    = shift;
    my $request = shift;

    return 100 if($request =~ /html?/);
    return 0;
}

sub types {
    my $self = shift;
    return 
      ({type       => 'html', 
       description => 'HTML'});
    
}

sub format {
    my $self = shift;
    my $text = shift;
    my $type = shift;

    my $html = HTML::TreeBuilder->new;
    
    $html->parse($text);
    $html->eof;

    my $result =  _parse($html->guts);
    $html->delete;

    return "$result";
}

sub _parse {
    my @elements = @_;
    my $result;
    foreach my $element (@elements){
	my $type;
	if (blessed $element && $element->isa('HTML::Element')){
	    my @kids = $element->content_list;
	    my $type = $element->tag;
	    
	    # if it's a link
	    if($type eq 'a'){
		my $location = $element->attr('href');
		my $uri      = URI->new($location);
		
		my $scheme = $uri->scheme;
		if($scheme !~ /^(http|ftp|mailto)$/){
		    $result .= _parse(@kids); # not a link.
		}
		else {
		    $location = _escape($uri->as_string);
		    $result  .= qq{<a href="$location">};
		    $result  .= _parse(@kids);
		    $result  .= '</a>';
		}
	    }
	    
	    # one of these tags
	    elsif(grep {$type eq $_} qw(i b u pre blockquote code p ol ul li)){
		$result .= qq{<$type>};
		$result .= _parse(@kids);
		$result .= qq{</$type>};
	    }

	    # heading
	    elsif($type =~ /h(\d+)/){
		my $heading = $1;
		$heading += 2;
		$heading  = 6 if($heading > 6);
		$result  .= qq{<h$heading>};
		$result  .= _parse(@kids);
		$result  .= qq{</h$heading>};
	    }

	    # break
	    elsif($type eq 'br'){
		$result .= '<br />';
	    }

	    # something else
	    else {
		$result .= _parse(@kids);
	    }
	}

	# plain text
	else {
	    $result .= _escape($element);
	}
    }
    return $result;
}

sub _escape {
    my $text = shift;
    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    return $text;
}

1;

__END__
