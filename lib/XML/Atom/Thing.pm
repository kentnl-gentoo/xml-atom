# $Id: Thing.pm,v 1.6 2003/12/05 10:23:01 btrott Exp $

package XML::Atom::Thing;
use strict;

use base qw( XML::Atom::ErrorHandler );
use XML::LibXML;
use LWP::UserAgent;

## Need easy access to namespaced data (eg TypePad-specific)

use constant NS => 'http://purl.org/atom/ns#';

sub new {
    my $class = shift;
    my $atom = bless {}, $class;
    $atom->init(@_) or return $class->error($atom->errstr);
    $atom;
}

sub init {
    my $atom = shift;
    my %param = @_;
    if (%param) {
        if (my $stream = $param{Stream}) {
            my $parser = XML::LibXML->new;
            if (ref($stream) eq 'SCALAR') {
                $atom->{doc} = $parser->parse_string($$stream);
            } elsif (UNIVERSAL::isa($stream, 'URI')) {
                ($stream, my($data)) = $atom->find_atom($stream);
                return $atom->error("Can't find Atom file") unless $stream;
                $atom->{doc} = $parser->parse_string($data);
            } elsif (ref($stream)) {
                $atom->{doc} = $parser->parse_fh($stream);
            } else {
                $atom->{doc} = $parser->parse_file($stream);
            }
        } elsif (my $doc = $param{Doc}) {
            $atom->{doc} = $doc;
        }
    } else {
        my $doc = $atom->{doc} = XML::LibXML::Document->createDocument('1.0', 'utf-8');
        my $root = $doc->createElementNS(NS, $atom->element_name);
        $doc->setDocumentElement($root);
    }
    $atom;
}

sub find_atom {
    my $atom = shift;
    my($uri) = @_;
    my $ua = LWP::UserAgent->new;
    my $req = HTTP::Request->new(GET => $uri);
    my $res = $ua->request($req);
    return unless $res->is_success;
    if ($res->content_type eq 'text/html') {
        my $atom_url;
        my $find_links = sub {
            my($tag, $attr) = @_;
            $atom_url = $attr->{href}
                if $tag eq 'link' &&
                   $attr->{rel} eq 'meta' &&
                   $attr->{type} eq 'application/x.atom+xml' &&
                   $attr->{title} eq 'Atom';
        };
        require HTML::Parser;
        my $p = HTML::Parser->new(api_version => 3,
                                  start_h => [ $find_links, "tagname, attr" ]);
        $p->parse($res->content);
        if ($atom_url) {
            $atom_url = URI->new_abs($atom_url, $uri);
            $req = HTTP::Request->new(GET => $atom_url);
            $res = $ua->request($req);
            return($atom_url, $res->content)
                if $res->is_success;
        }
    } else {
        return($uri, $res->content);
    }
}

sub _first {
    my @res = $_[1]->getElementsByTagNameNS($_[2], $_[3]) or return;
    $res[0];
}

sub get {
    my $atom = shift;
    my($ns, $name) = @_;
    my $ns_uri = ref($ns) eq 'XML::Atom::Namespace' ? $ns->{uri} : $ns;
    my $node = $atom->_first($atom->{doc}, $ns_uri, $name);
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
    unless ($elem = $atom->_first($atom->{doc}, $ns_uri, $name)) {
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
    my($attr) = @_;
    my $elem = $thing->{doc}->createElementNS(NS, 'link');
    $thing->{doc}->getDocumentElement->appendChild($elem);
    while (my($k, $v) = each %$attr) {
        $elem->setAttribute($k, $v);
    }
}

sub get_links {
    my $thing = shift;
    my @res = $thing->{doc}->getElementsByTagNameNS(NS, 'link');
    my @links;
    for my $node (@res) {
        next unless $node->getAttribute('rel');
        push @links, {
            rel => $node->getAttribute('rel'),
            type => $node->getAttribute('type'),
            title => $node->getAttribute('title'),
            href => $node->getAttribute('href'),
        };
    }
    \@links;
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
