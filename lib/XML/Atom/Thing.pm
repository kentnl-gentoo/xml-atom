# $Id: Thing.pm,v 1.10 2004/04/24 10:09:12 btrott Exp $

package XML::Atom::Thing;
use strict;

use base qw( XML::Atom::ErrorHandler );
use XML::LibXML;
use LWP::UserAgent;
use XML::Atom::Util qw( first );
use XML::Atom::Link;

use constant NS => 'http://purl.org/atom/ns#';

sub new {
    my $class = shift;
    my $atom = bless {}, $class;
    $atom->init(@_) or return $class->error($atom->errstr);
    $atom;
}

sub init {
    my $atom = shift;
    my %param = @_ == 1 ? (Stream => $_[0]) : @_;
    if (%param) {
        if (my $stream = $param{Stream}) {
            my $parser = XML::LibXML->new;
            if (ref($stream) eq 'SCALAR') {
                $atom->{doc} = $parser->parse_string($$stream);
            } elsif (ref($stream)) {
                $atom->{doc} = $parser->parse_fh($stream);
            } else {
                $atom->{doc} = $parser->parse_file($stream);
            }
        } elsif (my $doc = $param{Doc}) {
            $atom->{doc} = $doc;
        } elsif (my $elem = $param{Elem}) {
            $atom->{doc} = XML::LibXML::Document->createDocument('1.0', 'utf-8');
            $atom->{doc}->setDocumentElement($elem);
        }
    } else {
        my $doc = $atom->{doc} = XML::LibXML::Document->createDocument('1.0', 'utf-8');
        my $root = $doc->createElementNS(NS, $atom->element_name);
        $doc->setDocumentElement($root);
    }
    $atom;
}

sub get {
    my $atom = shift;
    my($ns, $name) = @_;
    my $ns_uri = ref($ns) eq 'XML::Atom::Namespace' ? $ns->{uri} : $ns;
    my $node = first($atom->{doc}, $ns_uri, $name);
    return unless $node;
    my $val = $node->textContent;
    if ($] >= 5.008) {
        require Encode;
        Encode::_utf8_off($val);
    }
    $val;
}

sub set {
    my $atom = shift;
    my($ns, $name, $val, $attr) = @_;
    my $elem;
    my $ns_uri = ref($ns) eq 'XML::Atom::Namespace' ? $ns->{uri} : $ns;
    unless ($elem = first($atom->{doc}, $ns_uri, $name)) {
        $elem = $atom->{doc}->createElementNS($ns_uri, $name);
        $atom->{doc}->getDocumentElement->appendChild($elem);
    }
    if ($ns ne NS) {
        $atom->{doc}->getDocumentElement->setNamespace($ns->{uri}, $ns->{prefix}, 0);
    }
    if (ref($val) =~ /Element$/) {
        $elem->appendChild($val);
    } elsif (defined $val) {
        $elem->removeChildNodes;
        my $text = XML::LibXML::Text->new($val);
        $elem->appendChild($text);
    }
    if ($attr) {
        while (my($k, $v) = each %$attr) {
            $elem->setAttribute($k, $v);
        }
    }
    $val;
}

sub add_link {
    my $thing = shift;
    my($link) = @_;
    my $elem = $thing->{doc}->createElementNS(NS, 'link');
    $thing->{doc}->getDocumentElement->appendChild($elem);
    if (ref($link) eq 'XML::Atom::Link') {
        for my $k (qw( type rel href title )) {
            $elem->setAttribute($k, $link->$k());
        }
    } elsif (ref($link) eq 'HASH') {
        for my $k (qw( type rel href title )) {
            $elem->setAttribute($k, $link->{$k});
        }
    }
}

sub link {
    my $thing = shift;
    if (wantarray) {
        my @res = $thing->{doc}->getDocumentElement->getChildrenByTagNameNS(NS, 'link');
        my @links;
        for my $elem (@res) {
            push @links, XML::Atom::Link->new(Elem => $elem);
        }
        return @links;
    } else {
        my $elem = first($thing->{doc}, NS, 'link') or return;
        return XML::Atom::Link->new(Elem => $elem);
    }
}

sub as_xml {
    my $doc = $_[0]->{doc};
    if (eval { require XML::LibXSLT }) {
        my $parser = XML::LibXML->new;
        my $xslt = XML::LibXSLT->new;
        my $style_doc = $parser->parse_string(<<'EOX');
<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet> 
EOX
        my $sheet = $xslt->parse_stylesheet($style_doc);
        my $results = $sheet->transform($doc);
        return $sheet->output_string($results);
    } else {
        return $doc->toString(1);
    }
}

sub DESTROY { }

use vars qw( $AUTOLOAD );
sub AUTOLOAD {
    (my $var = $AUTOLOAD) =~ s!.+::!!;
    no strict 'refs';
    *$AUTOLOAD = sub {
        @_ > 1 ? $_[0]->set(NS, $var, @_[1..$#_]) : $_[0]->get(NS, $var)
    };
    goto &$AUTOLOAD;
}

1;
