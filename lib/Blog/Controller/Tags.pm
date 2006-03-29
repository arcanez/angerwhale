package Blog::Controller::Tags;

use strict;
use warnings;
use base 'Catalyst::Controller';
use URI::Escape;

=head1 NAME

Blog::Controller::Tags - Catalyst Controller

=head1 SYNOPSIS

See L<Blog>

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut
  
sub do_tag : LocalRegex('do_tag/.+') {
    my ($self, $c) = @_;

    my $uri = uri_unescape($c->request->uri);
    $uri =~ m{tag/(.+)};
    my $article_name = $1;
    my $tags = $c->request->param("value");
    my @tags = split /(?:\s|[_;,!.])+/, $tags;

    my $article;
    eval {
	$article = $c->stash->{root}->get_article($article_name);
    };
    if($@){
	$c->response->status(404);
	$c->stash->{template} = "error.tt";
	return;
    }


    if(!$tags){
	# get a list for the InPlaceEditor
	@tags = $article->tags;
	my $string = join " ", @tags;
	$string =~ s/^\s+//g;
	$string =~ s/\s+$//g;
	$c->response->body($string);
    }
    else {
	# actually do the tagging, and return HTML
	$c->stash->{template} = "ajax_tags.tt";
	$c->stash->{tags} = [$article->set_tag(@tags)];
    }
}

sub tag : LocalRegex('[^/]$') {
    my ($self, $c) = @_;
    my $uri = uri_unescape($c->request->uri);
    $uri =~ m{tags/(.+)/?$};
    
    my @tags  = map {lc} split /(?:\s|[_;,!.])/, $1; 

    $c->stash->{template} = "search_results.tt";

    $c->stash->{title} = "Articles tagged with ". join ', ', @tags[0..$#tags-1];

    # make a nice-looking comma/and -separated list ("foo, bar, and baz"
    # or "foo and bar")
    if($#tags == 0){
	$c->stash->{title} .= $tags[-1];
    } # nop
    elsif($#tags == 1){
	$c->stash->{title} .= " and ". $tags[-1];
    }
    else {
	$c->stash->{title} .= ", and " . $tags[-1];
    }

    $c->stash->{articles} = [$c->stash->{root}->get_by_tag(@tags)];
    $c->stash->{article_count} = scalar @{$c->stash->{articles}};
}

sub tag_list : Private {
    my ($self, $c) = @_;
    $c->response->body("You made it!");
}

sub default : Private {
    my ( $self, $c ) = @_;

    if($c->request->uri !~ m{tags/$}){
	$c->response->redirect("/tags/");
    }
    else {
	$c->forward("tag_list");
    }
}


=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
