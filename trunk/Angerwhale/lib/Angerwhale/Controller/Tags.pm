package Angerwhale::Controller::Tags;

use strict;
use warnings;
use base 'Catalyst::Controller';
use URI::Escape;
use Quantum::Superpositions;
use utf8;

=head1 NAME

Angerwhale::Controller::Tags - Catalyst Controller

=head1 SYNOPSIS

See L<Angerwhale>

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub check_tag_access : Private {
    my ($self, $c) = @_;
    
    if(!$c->stash->{user}){
	$c->response->status('401');
	$c->response->content_type('text/plain'); # maybe XML later
	$c->response->body('Log in to edit.');
	return 0;
    }
    else {
	return 1;
    }
}

# get a list for ajax if no params,
# otherwise apply the tags
sub do_tag : Local {
    my ($self, $c, @args) = @_;

    # we might want to handle the special case of
    # the user wanting to view articles tagged with "do_tag"
    
    return if !$c->forward('check_tag_access');

    my $article_name = shift @args;
    my $tags = $c->request->param('value');
    my @tags = split /\s+/, $tags;
    
    my $article;
    eval {
	$article = $c->stash->{root}->get_article($article_name);
    };
    if($@){
	$c->response->status(404);
	$c->response->body("Tagging error: $@");
	return;
    }


    if(!$tags){
	# get a list for the InPlaceEditor
	@tags = $article->tags;
	$c->stash->{tags} = "@tags";
	$c->stash->{template} = 'tags_as_text.tt';
    }
    else {
	# actually do the tagging, and return HTML
	$c->stash->{template} = 'ajax_tags.tt';
	$article->set_tag(@tags);
	$c->stash->{article} = $article;
    }
}

sub show_tagged_articles : Path(q{}) {
    my ($self, $c, @tags) = @_;

    map { Encode::_utf8_on($_) unless Encode::is_utf8($_)} @tags;
    $c->stash->{template} = 'search_results.tt';
    $c->stash->{title} = 'Articles tagged with '. join(', ', @tags[0..$#tags-1]);
    # make a nice-looking comma-separated list ("foo, bar, and baz"
    # or "foo and bar")
    if($#tags == 0){
	$c->stash->{title} .= $tags[-1];
    } # nop
    elsif($#tags == 1){
	$c->stash->{title} .= ' and '. $tags[-1];
    }
    else {
	$c->stash->{title} .= ', and ' . $tags[-1];
    }

    $c->stash->{tags}          = any(@tags); # for the navbar
    $c->stash->{tag_count}     = scalar @tags; # easier to deal with in TT
    $c->stash->{articles}      = [reverse sort
				  $c->stash->{root}->get_by_tag(@tags)];
    $c->stash->{article_count} = scalar @{$c->stash->{articles}};

}

sub tag_list : Private {
    my ($self, $c) = @_;
    my @articles = $c->model('Filesystem')->get_articles;
    my $tags = {};

    my $max_count = 1;
    my $total     = 0;
    
    foreach my $article (@articles){
	my @_tags = $article->tags;
	foreach my $tag (@_tags){
	    no warnings;
	    $tags->{$tag}->{articles}++;
	    
	    my $tag_count = 
	      ($tags->{$tag}->{count} += $article->tag_count($tag));
	    $max_count = $tag_count if($tag_count > $max_count);
	    $total += $tag_count;
	}
    }
    my $average_count = 1;
    my $tag_count = (scalar (keys %{$tags}));
    $average_count = $total / $tag_count if $tag_count > 0;
    
    foreach my $tag (values %{$tags}){
	$tag->{count} = int(($tag->{count} - $average_count)*15 + 130);
    }
    
    $c->stash->{tag_count}  = $tag_count;
    $c->stash->{tags}	    = [keys %{$tags}];
    $c->stash->{tag_data}   = $tags;
    $c->stash->{template}   = 'tag_list.tt';
}

sub get_nav_box : Local {
    my ($self, $c) = @_;
    if ($c->request->param('_home')){ 
	# whether or not the Home link should be a link
	# (on the main page, it's not a link because you're already home)
	$c->stash->{page} = 'home';
    }
    $c->stash->{categories} = [$c->model('Filesystem')->get_categories];
    $c->stash->{tags} = [$c->model('Filesystem')->get_tags];
    $c->stash->{template} = 'navbox.tt';
}

sub index : Private {
    my ($self, $c) = @_;
    $c->detach('tag_list');
}


=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
