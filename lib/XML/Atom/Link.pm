# $Id: Link.pm,v 1.1 2003/12/30 06:58:18 btrott Exp $

package XML::Atom::Link;
use strict;

use base qw( XML::Atom::ErrorHandler );
use XML::LibXML;

use constant NS => 'http://purl.org/atom/ns#';

sub new {
    my $class = shift;
    my $link = bless {}, $class;
    $link->init(@_) or return $class->error($link->errstr);
    $link;
}

sub init {
    my $link = shift;
    my %param = @_ == 1 ? (Body => $_[0]) : @_;
    my $elem;
    unless ($elem = $param{Elem}) {
        my $doc = XML::LibXML::Document->createDocument('1.0', 'utf-8');
        $elem = $doc->createElementNS(NS, 'link');
        $doc->setDocumentElement($elem);
    }
    $link->{elem} = $elem;
    $link;
}

sub elem { $_[0]->{elem} }

sub get {
    my $link = shift;
    my($attr) = @_;
    $link->elem->getAttribute($attr);
}

sub set {
    my $link = shift;
    my($attr, $val) = @_;
    $link->elem->setAttribute($attr, $val);
}

sub as_xml {
    my $link = shift;
    my $doc = XML::LibXML::Document->new('1.0', 'utf-8');
    $doc->setDocumentElement($link->elem);
    $doc->toString(1);
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
