# $Id: Content.pm,v 1.2 2003/12/15 00:03:06 btrott Exp $

package XML::Atom::Content;
use strict;

use base qw( XML::Atom::ErrorHandler );
use XML::LibXML;
use MIME::Base64 qw( encode_base64 decode_base64 );

use constant NS => 'http://purl.org/atom/ns#';

sub new {
    my $class = shift;
    my $content = bless {}, $class;
    $content->init(@_) or return $class->error($content->errstr);
    $content;
}

sub init {
    my $content = shift;
    my %param = @_ == 1 ? (Body => $_[0]) : @_;
    my $elem;
    unless ($elem = $param{Elem}) {
        my $doc = XML::LibXML::Document->createDocument('1.0', 'utf-8');
        $elem = $doc->createElementNS(NS, 'content');
        $doc->setDocumentElement($elem);
    }
    $content->{elem} = $elem;
    if ($param{Body}) {
        $content->body($param{Body});
    }
    if ($param{Type}) {
        $content->type($param{Type});
    }
    $content;
}

sub elem { $_[0]->{elem} }

sub type {
    my $content = shift;
    if (@_) {
        $content->elem->setAttribute('type', shift);
    }
    $content->elem->getAttribute('type');
}

sub mode {
    my $content = shift;
    $content->elem->getAttribute('mode');
}

sub body {
    my $content = shift;
    my $elem = $content->elem;
    if (@_) {
        my $data = shift;
        $elem->removeChildNodes;
        if ($data =~ /[^\x09\x0a\x0d\x20-\x7f]/) {
            $elem->appendChild(XML::LibXML::Text->new(encode_base64($data, '')));
            $elem->setAttribute('mode', 'base64');
        } else {
            my $copy = '<div xmlns="http://www.w3.org/1999/xhtml">' .
                       $data .
                       '</div>';
            my $node;
            eval {
                my $parser = XML::LibXML->new;
                my $tree = $parser->parse_string($copy);
                $node = $tree->getDocumentElement;
            };
            if (!$@ && $node) {
                $elem->appendChild($node);
                $elem->setAttribute('mode', 'xml');
            } else {
                $elem->appendChild(XML::LibXML::Text->new($data));
                $elem->setAttribute('mode', 'escaped');
            }
        }
    } else {
        unless (exists $content->{__body}) {
            my $mode = $elem->getAttribute('mode') || 'xml';
            if ($mode eq 'xml') {
                my @children = grep ref($_) =~ /Element$/, $elem->childNodes;
                if (@children) {
                    @children = $children[0]->childNodes
                        if @children == 1 && $children[0]->localname eq 'div';
                    $content->{__body} = join '', map $_->toString, @children;
                } else {
                    $content->{__body} = $elem->textContent;
                }
            } elsif ($mode eq 'base64') {
                $content->{__body} = decode_base64($elem->textContent);
            } elsif ($mode eq 'escaped') {
                $content->{__body} = $elem->textContent;
            } else {
                $content->{__body} = undef;
            }
            if ($] >= 5.008) {
                require Encode;
                Encode::_utf8_off($content->{__body});
            }
        }
    }
    $content->{__body};
}

sub as_xml {
    my $content = shift;
    my $doc = XML::LibXML::Document->new('1.0', 'utf-8');
    $doc->setDocumentElement($_[0]->{doc});
    $doc->toString(1);
}

1;
