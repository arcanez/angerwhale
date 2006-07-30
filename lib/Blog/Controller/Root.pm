package Blog::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';
use URI;
use HTTP::Date;
use Digest::MD5 qw(md5_hex);

# this was auto-generated and is apparently essential
__PACKAGE__->config->{namespace} = q{}; 

=head1 NAME

Blog::Controller::Root - Root Controller for this Catalyst based application

=head1 SYNOPSIS

See L<Blog>.

=head1 DESCRIPTION

Root Controller for this Catalyst based application.

=head1 METHODS

=cut

=head2 default

=cut

sub auto : Private {
    my ($self, $c) = @_;

    my $sid = $c->request->cookie("sid");
    if(defined $sid){
	eval {
	    $sid = $sid->value;
	    $c->log->debug("got session cookie $sid");
	    my $uid = $c->model('NonceStore')->unstore_session($sid);
	    $c->stash->{user} = $c->model("UserStore")->
	      get_user_by_nice_id($uid);
	    $c->log->debug("got user $uid, ". $c->stash->{user}->fullname);
	};
	if ($@){
	    $c->log->debug("Failed to restore session $sid: $@");
	    $c->response->cookies->{sid} = {value   => q{},
					    expires => -1};

	}
    }
    $c->stash->{root} = $c->model('Filesystem');

    
    # not implemented yet, sort of
#     # update type information
#     my $uri = $c->request->uri->path;
#     if($uri =~ /(\/?)(.*)[.]([a-zA-Z]+)$/){
# 	my $slash = $1;
# 	my $path  = $2;
# 	my $type  = $3;
	
# 	# save the type
# 	$c->stash->{requested_type} = $type;

# 	# fix the URI
# 	my $uri = $c->request->uri->as_string;
# 	$uri =~ s{[.]$type}{};
# 	$c->request->{uri}  = URI->new($uri);

# 	# fix the path
# 	$c->request->{path} = $path;

# 	# fix the arguments
# 	#$path =~ m{/(.+)[.]$type};
# 	#$c->{request}->{arguments}->[-1] = "foo";

#     }


    return 1;
}

sub blog : Path('') {
    my ( $self, $c ) = @_;
    
    $c->stash->{page}     = "home";
    $c->stash->{title}    = "Blog";
    $c->stash->{category} = "/";
    $c->forward("/categories/show_category");
}

sub default : Private {
    my ($self, $c) = @_;
    $c->response->redirect('/');
}

# global ending action

sub end : Private {
    my ($self, $c) = @_;
    
    #  not implemented yet
    # my $requested_type = $c->stash->{requested_type};
    
    #if($c->debug){
#	my $res = $c->response->body;
#	$c->forward('Blog::View::Dump');
#	print {*STDERR} $c->response->body;
#	$c->response->body($res);
#    }
    
    if(!($c->response->body || $c->response->redirect)){
	$c->response->content_type('application/xhtml+xml; charset=utf-8');
#	$c->response->content_type('text/html; charset=utf-8');
 	$c->stash->{generated_at} = time();
 	my $articles = $c->stash->{articles};
 	my $article  = $c->stash->{article};
 	my $key      = _global_uniq_id($c);
	
 	if(ref $articles eq 'ARRAY'){    
 	    # try the cache
 	    $key .= join '|', map {_article_uniq_id($_)} @{$articles};
 	    _cache($c, $key);
 	}
 	elsif (ref $article && $c->request->uri =~ m{/articles/}){
 	    $key .= _article_uniq_id($article);
 	    _cache($c, $key);
 	}
	else {
	    $c->forward('Blog::View::HTML');
	}
    }

    my $h = $c->response->headers;
    $h->header('Content-Location' => $c->request->base);

    return;
}

sub _global_uniq_id {
    my $c = shift;
    # main page changes for:
    # uri
    # change in tags
    # change in categories
    # change in user
    my $user;
    eval {
	$user = $c->stash->{user}->nice_id;
    };
    $user ||= 'anonymous';
    
    return 	
      $c->request->uri->path. '|'. $user. '|'.
	'(tags:'. (join ':', $c->model('Filesystem')->get_tags). ')|'.
	'(cats:'. (join ':', $c->model('Filesystem')->get_categories). 
	  ')|';
}

sub _article_uniq_id {
    my $article = shift;
    # articles depend on:
    # tags
    # categories
    # contents (and mtime by association)
    # # of comments (to avoid traversing the entire comment tree)
    no warnings;
    return $article->comment_count.
      '|'. $article->checksum.
      '|'. $article->tags.
      '|'. $article->categories.
      '|'. $article->comment_count;
}

sub _cache {
    my $c   = shift;
    my $key = shift;
    my $document;
    if( $document = $c->cache->get($key) ){
	$c->log->debug("serving from cache $key");
	$c->response->body($document->{body});
    }
    else {
	$c->log->debug("caching $key");
	$c->forward('Blog::View::HTML');
	$document = { mtime => time(),
		      body  => $c->response->body };
	$c->cache->set($key, $document);
    }
    
    my $h = $c->response->headers;
    $h->header('E-Tag' => md5_hex($key));
    $h->header('Last-Modified' => time2str($document->{mtime}));
}

=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
