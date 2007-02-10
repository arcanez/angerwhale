#!/usr/bin/perl
# markdown-format.t
# Copyright (c) 2007 Florian Ragwitz <rafl@debian.org>

use Test::More tests => 4;
use ok 'Angerwhale::Format::Markdown';
use Test::HTML::Tidy;
use Test::XML::Valid;

my $markdown = Angerwhale::Format::Markdown->new;
isa_ok( $markdown, 'Angerwhale::Format::Markdown', 'created parser' );

my $input = do { local $/; <DATA> };
my $output = $markdown->format($input);

# make output tidier for tidy:
$output = <<"END";
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
                      "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml"
      xml:lang="en">
<head><title>test</title></head><body>$output</body></html>
END

my $tidy = HTML::Tidy->new( { config_file => 'tidy_config' } );
html_tidy_ok( $tidy, $output, 'html is tidy' );
xml_string_ok( $output, 'html is valid xml' );

__DATA__
A First Level Header
====================

A Second Level Header
---------------------

Now is the time for all good men to come to
the aid of their country. This is just a
regular paragraph.

The quick brown fox jumped over the lazy
dog's back.

### Header 3
#
#> This is a blockquote.
#> 
#> This is the second paragraph in the blockquote.
#>
#> ## This is an H2 in a blockquote
