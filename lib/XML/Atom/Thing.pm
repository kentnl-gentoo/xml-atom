# $Id: Thing.pm,v 1.3 2003/09/08 03:11:17 btrott Exp $

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
    my @res = $_[1]->getElementsByTagNameNS(NS, $_[2]) or return;
    $res[0];
}

sub get {
    my $atom = shift;
    my $node = $atom->_first($atom->{doc}, $_[0]);
    my $val = $node ? $node->textContent : '';
    if ($] >= 5.008) {
        require Encode;
        Encode::_utf8_off($val);
    }
    $val;
}

sub set {
    my $atom = shift;
    my($var, $val, $attr) = @_;
    my $elem;
    unless ($elem = $atom->_first($atom->{doc}, $var)) {
        $elem = $atom->{doc}->createElementNS(NS, $var);
        $atom->{doc}->getDocumentElement->appendChild($elem);
    }
    if (ref($val) =~ /Element$/) {
        $elem->appendChild($val);
    } else {
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

sub as_xml {
    $_[0]->{doc}->toString(1)
}

sub as_xml_clean {
    my $xml = $_[0]->{doc}->toString(1);
    my $parser = XML::LibXML->new;
    my $xslt = XML::LibXSLT->new;
    my $doc = $parser->parse_string(<<'EOX');
<xsl:template match="@*|node()">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()"/>
  </xsl:copy>
</xsl:template>
EOX
    my $sheet = $xslt->parse_stylesheet($doc);
    my $results = $sheet->transform($xml);
    $sheet->output_string($results);
}

sub DESTROY { }

use vars qw( $AUTOLOAD );
sub AUTOLOAD {
    (my $var = $AUTOLOAD) =~ s!.+::!!;
    no strict 'refs';
    *$AUTOLOAD = sub {
        @_ > 1 ? $_[0]->set($var, @_[1..$#_]) : $_[0]->get($var)
    };
    goto &$AUTOLOAD;
}

1;
