#!/usr/bin/perl
# Application.pm 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Test::Application;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT = qw(context model);
our @EXPORT_OK = @EXPORT;

=head1 NAME

Angerwhale::Test::Application - return fake catalyst/angerwhale
application/context (C<$c>) for tests

=head1 EXPORT

context, model

=head1 FUNCTIONS

=head2 context(\%args)

Return an angerwhale context.  Args can be:

=over 4

=item config

Hashref of C<$c->config>.  See L<Catalyst|Catalyst>::config.

=back

=cut

sub context {
    my $args = shift;
    my $config = $args->{config};
    
    my $c = Test::MockObject->new;
    $c->set_always( 'stash', {} );
    $c->set_always( 'config', { encoding => 'utf8' } );
    $c->set_always( 'model', $user_store );

    # fake logging (doesn't do anything)
    my $log = Test::MockObject->new
    $log->set_always( 'debug', undef );
    $c->set_always( 'log', $log);
    
    # fake cache (always generates a cache miss)
    my $cache = Test::MockObject->new;
    $cache->set_always( 'get', undef );
    $cache->set_always( 'set', undef );
    $c->set_always( 'cache', $cache );    

    # TODO: model / etc.

    return $c;
}

=head2 model($model_name, { context_args => \%args, args => { args } } )

Returns an instance of C<$model_name>, where C<$model_name> is an
Angerwhale::Model.  Uses the application object created by C<context>
(with optional C<context_args>).

=cut

sub model {
    my $name = shift;
    croak "need name" unless $name;
    my $args = shift;
    my $context = context($args->{context_args});
    
    $name =~ s/\W//g;
    $name = "Angerwhale::Model::$name";

    eval "require $name";
    croak "error loading $name: $@" if $@;

    my $model;
    eval {
        $model = $name->COMPONENT($c, $args->{args});
    };
    croak "didn't get a model: $@" if $@ || !$model;

    return $model;
}
