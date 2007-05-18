# ColorizeDbk.pm
# Copyright (c) 2007 Daniel Brosseau <dab@free.fr>

package Angerwhale::Filter::ColorizeDbk;

#--------------------------------------------------------------------#
# Transform XML Docbook in XHTML (colorized programlisting|screen )
# 'lang' is lost in 'transformation xslt' step then: 
# mark lang -> transformation xslt -> colorize && unmark lang
#--------------------------------------------------------------------#

use strict;
use Syntax::Highlight::Engine::Kate;
use Syntax::Highlight::Engine::Kate::All;


my $hl_node="programlisting|screen";
my $hl_attrib="lang";
my $marklang=0;
my $colorize=0;
my $tomark;
my $tocolorize;
my $lang;
my $doc;
my $step;
my $debug;


sub new {
    my $type = shift;
    $debug = shift;

    my $self = ( $#_ == 0 ) ? shift : { @_ };


    return bless $self, $type;
}


sub step{
    my $self = shift;
    $step = shift;
}


sub start_document{
    print STDERR "start_document\n" if $debug;
}


sub end_document{
    my $result=$doc;
    $doc="";

    print STDERR "end_document\n" if $debug;
    return $result;
}


sub start_element{
    my $self = shift;
    my $el = shift;

    my @Attributes = keys %{$el->{Attributes}};
    my $name = $el->{Name};

    print STDERR "[$step]start_element: $name\n" if $debug;

    $doc .= "<$name";
    foreach my $att (@Attributes) {
        my $val = $el->{Attributes}->{$att}->{Value};

        $att =~ s/^\{\}//;

        # Uppercase fisrt letter of lang
        $val =~ s/\b(\w)/\U$1/g if (( $att eq "lang" )&&($el->{Name} =~ /$hl_node/));

        # Bug  XML::SAX::ParserFactory (???)
        # It add {http://www.w3.org/XML/1998/namespace} before lang="fr"
        #  if attrib class=article|section
        if ( $att eq "{http://www.w3.org/XML/1998/namespace}lang") {
            next;
        }

        # to be conform to xhtml 1.1
        if (( $name eq "div" ) && ( $att eq "lang" )) {
            $att = "xml:lang";
        }

        $doc .= " $att=\"$val\"";

        print STDERR "  $att=\"$val\"\n" if $debug;

        if (( $step eq 'marklang') && ( $att =~ /$hl_attrib/i )&&($el->{Name} =~ /$hl_node/ )) {
            $lang = $val;
            $marklang=1;
        } elsif (( $step eq 'colorize' ) && ($el->{Name} eq 'pre' )&&($val =~ /$hl_node/i)) {
            $colorize=1;
        }
    }

    $doc .= ">";
}


sub end_element{
    my $self = shift;
    my $el = shift;

    my $name = $el->{Name};

    print STDERR "[$step]end_element: $name\n" if $debug;

    # Mark language
    if (( $el->{Name} =~ /$hl_node/ ) && ($marklang eq 1 )) {

        $tomark =~ s/</&lt;/g;
        $tomark =~ s/>/&gt;/g;

        $doc .= "[lang=$lang\]\n${tomark}\n\[\/lang\]";

        print STDERR " => MARK LANG\n" if $debug;

        $marklang=0;
        $lang="";
        $tomark="";
    }
    # Colorize
    elsif (( $el->{Name} =~ /pre/ ) && ($colorize eq 1 )) {

        print STDERR " => COLORIZE\n" if $debug;
        $doc .= ColorizeCode($tocolorize);
        $colorize=0;
        $tocolorize="";
    }

    $doc .= "</$name>";
}


sub characters{
    my $self = shift;
    my $el = shift;

    print STDERR "[$step]characters: " . $el->{Data} . "\n" if $debug;

    if ( $marklang ) {
        $tomark .= $el->{Data};
    } elsif (  $colorize ) {
        $tocolorize .= $el->{Data};
    } else {
        $doc .= $el->{Data} if ( defined $el->{Data} );
    }
}


sub ColorizeCode{
    my $code = shift;

    $code =~ m/\[lang=(.*)\]/;
    my $lang=$1;

    $code =~ s/^\n//;
    $code =~ s/\[lang=\w*\]\n//g;
    $code =~ s/\[\/lang\]\n\s*//;

    if ( $debug ) {
        print STDERR "lang=$lang\ncode=$code\n" . "-"x60 . "\n";
    }

    return $code if ( ! $lang );

    my $hl = Syntax::Highlight::Engine::Kate->new(
                                                  substitutions => {
                                                                    "<"  => "&lt;",
                                                                    ">"  => "&gt;",
                                                                    "&"  => "&amp;",
                                                                    q{'} => "&apos;",
                                                                    q{"} => "&quot;",
                                                                   },
                                                  format_table => {
                                                                   Alert    => [ '<span class="Alert">',    '</span>' ],
                                                                   BaseN    => [ '<span class="BaseN">',    '</span>' ],
                                                                   BString  => [ '<span class="BString">',  '</span>' ],
                                                                   Char     => [ '<span class="Char">',     '</span>' ],
                                                                   Comment  => [ '<span class="Comment">',  '</span>' ],
                                                                   DataType => [ '<span class="DataType">', '</span>' ],
                                                                   DecVal   => [ '<span class="DecVal">',   '</span>' ],
                                                                   Error    => [ '<span class="Error">',    '</span>' ],
                                                                   Float    => [ '<span class="Float">',    '</span>' ],
                                                                   Function => [ '<span class="Function">', '</span>' ],
                                                                   IString  => [ '<span class="IString">',  '</span>' ],
                                                                   Keyword  => [ '<span class="Keyword">',  '</span>' ],
                                                                   Normal   => [ '<span class="Normal">',   '</span>' ],
                                                                   Operator => [ '<span class="Operator">', '</span>' ],
                                                                   Others   => [ '<span class="Others">',   '</span>' ],
                                                                   RegionMarker =>
                                                                   [ '<span class="RegionMarker">', '</span>' ],
                                                                   Reserved => [ '<span class="Reserved">', '</span>' ],
                                                                   String   => [ '<span class="String">',   '</span>' ],
                                                                   Variable => [ '<span class="Variable">', '</span>' ],
                                                                   Warning  => [ '<span class="Warning">',  '</span>' ],

                                                                  },
                                                 );


    my @LANGS=$hl->languageList;

    # check lang
    if ( !  grep(/$lang/i, @LANGS) ) {
        die "Language '$lang' unknown !!! in :\n". "-"x80 . "\n${code}\n" ."-"x80 . "\n" . "Authaurized language : @LANGS\n";
    }

    $hl->language($lang);
    my $result = $hl->highlightText($code);
    return $result;
}


1;
\
