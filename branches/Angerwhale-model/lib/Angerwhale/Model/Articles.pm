# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Model::Articles;
use strict;
use warnings;
use Class::C3; 
use Carp;
use base qw(Catalyst::Component::ACCEPT_CONTEXT Catalyst::Model);
use Scalar::Util qw(blessed);
use Scalar::Defer;

# filters
use Angerwhale::Content::Filter::Encoding;
use Angerwhale::Content::Filter::Checksum;
use Angerwhale::Content::Filter::Title;
use Angerwhale::Content::Filter::Author;
use Angerwhale::Content::Filter::Format;
use Angerwhale::Content::Filter::Summary;
use Angerwhale::Content::Filter::URI;
use Angerwhale::Content::Filter::Finalize;


our @ISA;

__PACKAGE__->mk_accessors(qw/storage_class storage_args source filters/);

sub new {
    my $class = shift;
    my $self  = $class->next::method(@_);
    
    my $sclass = "Angerwhale::Content::ContentProvider::".$self->storage_class;
    eval "require $sclass";
    croak "can't load $sclass" if $@;
    
    my $s = $sclass->new($self->storage_args);
    
    $self->filters([
                    Angerwhale::Content::Filter::Encoding::filter($self->context->config->{encoding}),
                    Angerwhale::Content::Filter::Checksum::filter(),
                    Angerwhale::Content::Filter::Title::filter(),
                    Angerwhale::Content::Filter::Author::filter(),
                    Angerwhale::Content::Filter::Format::filter(),
                    Angerwhale::Content::Filter::Summary::filter(),
                    Angerwhale::Content::Filter::URI::filter(),
                    Angerwhale::Content::Filter::Finalize::filter(),
                   ]);
    
    $self->source($s);
    return $self;
}

sub COMPONENT {
    my ($class, $app, $args) = @_;
    
    # use the Filesystem by default, for backcompat
    if ($app->config->{base}) {
        $args->{storage_class} = 'Filesystem';
        $args->{storage_args}{root} = $app->config->{base};
    }
    
    return $class->next::method($app, $args);
}

sub preview {
    my $self = shift;
    my $args = shift;

    if (!ref $args) {
        $args = {$args, @_};
    }
    
    my $data = $args->{body};
    my $metadata = $args;
    delete $metadata->{body};
    
    croak "need title" unless $metadata->{title};
    croak "need type"  unless $metadata->{type};
    croak "need name"  unless $metadata->{name};
    
    $metadata->{creation_time} = time();
    $metadata->{modification_time} = $metadata->{creation_time};
    
    my $article = Angerwhale::Content::Item->
      new({ metadata => $metadata,
            data     => $data });
    
    return ($self->_apply_filters($article))[0];
}


sub get_article {
    my $self = shift;
    my $article = shift;
    return ($self->_apply_filters($self->source->get_article($article)))[0];
}

sub get_articles {
    my $self  = shift;
    return $self->_apply_filters($self->source->get_articles);
}

sub get_by_category {
    my $self = shift;
    return $self->_apply_filters($self->source->get_by_category(@_));
}

sub get_by_tag {
    my $self = shift;
    return;
}

sub get_tags { $_[0]->source->get_tags };
sub get_categories { $_[0]->source->get_categories };
sub revision { $_[0]->source->revision };


sub _apply_filters {
    my $self    = shift;
    my @articles= @_;
    
    # curry the filters
    my @filters = map { my $filter = $_;
                        sub { my $item = shift; 
                              my $r = $filter->($filter, $self->context, $item);
                              if (blessed $r) {
                                  return $r;
                              }
                              else {
                                  return $item;
                              }
                          }
                    } @{$self->filters||[]};
    
    my @result;
    foreach my $a (@articles) {
        my $article = $a;
        
        # filter kids (lazy)
        $article->children(
                           lazy {
                               # XXX: a bit messy due to Finalization
                               my @kids = @{$article->children||[]};
                               $article->{item}{children} 
                                 = [$self->_apply_filters(@kids)]
                             });
        
        # filter article
        foreach my $f (@filters) {
            $article = $f->($article);
        }

        push @result, $article;
    }
    
    return @result;
}

1;

__END__

=head1 NAME

Angerwhale::Model::Articles - get blog articles

=head1 METHODS

=head2 preview

Return a preview comment.

=head1 PROXIED METHODS

Methods below proxy the ContentProvider. See
L<Angerwhale::Content::ContentProvider>.

=head2 get_articles

=head2 get_article

=head2 get_categories

=head2 get_tags

=head2 get_by_tag

=head2 get_by_category

=head2 get_by_date

=head2 revision

=head1 CATALYST METHODS

=head2 new

Create an instance

=head2 ACCEPT_CONTEXT

Accept context

1;
