package Blog::Controller::Login;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Blog::Challenge;
use Blog::Signature;
use YAML;


=head1 NAME

Blog::Controller::Login - Handles logins

=head1 SYNOPSIS

See L<Blog>

=cut

sub nonce : Local {
    my ( $self, $c ) = @_;
    
    my $nonce = Blog::Challenge->new({uri => $c->request->base->as_string});    
    $c->model('NonceStore')->new_nonce($nonce);
    $c->stash->{nonce} = $nonce;
    
    if(!$c->stash->{template}){
	$c->response->content_type('text/plain');
	$c->response->body($nonce);
    }

    return;
}

sub process : Local {
    my ( $self, $c ) = @_;
    my $data = $c->request->param('login');
    
    my $sig;
    my $key_id;

    eval {
	$sig    = Blog::Signature->new($data);
	$key_id = $sig->get_key_id;
    };
    if(!$key_id || !$sig || $@){
	#$c->stash->{error} = 'You forgot to sign the message.';
	#$c->detach('login_page');
	
	$c->response->body('You forgot to sign the message.');
	return;
    }
    my $nice_key_id = "0x". substr(unpack("H*", $key_id), -8, 8);
    my $nonce_data = $sig->get_signed_data;

    $c->log->debug("keyid $nice_key_id is presumably logging in");
    
    eval {
	my $challenge = Load($nonce_data) or die "couldn't deserialize request";
	
	die unless $c->model("NonceStore")->verify_nonce($challenge) && 
	  $sig->verify;
    };
    
    if($@){
	$c->log->warn("Failed login for 0x$nice_key_id");
	$c->response->body("You cheating scum!  You are NOT $nice_key_id!");
	return;
    }
    else {
	my $user = $c->model('UserStore')->get_user_by_real_id($key_id);
	my $session_id = $c->model('NonceStore')->store_session($user);
	$c->model('UserStore')->refresh_user($user);
	
	$c->log->info("successful login for ". $user->nice_id);
	$c->log->debug("new session $session_id created");
	$c->response->body("Passed!  You are ". $user->fullname.
			   " (0x". $user->nice_id. ").");
	$c->response->cookies->{sid} = {value => "$session_id"};
	return 1;
    }
}

sub login_page : Private {
    my ( $self, $c ) = @_;
    $c->stash->{template} = 'login.tt';
    $c->forward('nonce');
}

sub default : Private {
    my ( $self, $c ) = @_;    
    $c->forward('login_page');
}


=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
