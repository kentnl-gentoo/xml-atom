# $Id: Person.pm,v 1.2 2003/12/30 06:58:18 btrott Exp $

package XML::Atom::Person;
use strict;

use base qw( XML::Atom::ErrorHandler );
use XML::LibXML;
use XML::Atom::Util qw( first );

use constant NS => 'http://purl.org/atom/ns#';

sub new {
    my $class = shift;
    my $person = bless {}, $class;
    $person->init(@_) or return $class->error($person->errstr);
    $person;
}

sub init {
    my $person = shift;
    my %param = @_;
    my $elem;
    unless ($elem = $param{Elem}) {
        my $doc = XML::LibXML::Document->createDocument('1.0', 'utf-8');
        $elem = $doc->createElementNS(NS, 'author'); ## xxx
        $doc->setDocumentElement($elem);
    }
    $person->{elem} = $elem;
    $person;
}

sub elem { $_[0]->{elem} }

sub get {
    my $person = shift;
    my($name) = @_;
    my $node = first($person->elem, NS, $name) or return;
    my $val = $node->textContent;
    if ($] >= 5.008) {
        require Encode;
        Encode::_utf8_off($val);
    }
    $val;
}

sub set {
    my $person = shift;
    my($name, $val) = @_;
    my $elem;
    unless ($elem = first($person->elem, NS, $name)) {
        $elem = XML::LibXML::Element->new($name);
        $elem->setNamespace(NS);
        $person->elem->appendChild($elem);
    }
    $elem->removeChildNodes;
    $elem->appendChild(XML::LibXML::Text->new($val));
    $val;
}

sub as_xml {
    my $author = shift;
    my $doc = XML::LibXML::Document->new('1.0', 'utf-8');
    $doc->setDocumentElement($_[0]->{doc});
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
__END__

=head1 NAME

XML::Atom::Person - Author or contributor object

=head1 SYNOPSIS

    my $author = XML::Atom::Person->new;
    $author->email('foo@example.com');
    $author->name('Foo Bar');
    $entry->author($author);

=head1 DESCRIPTION

I<XML::Atom::Person> represents an author or contributor element in an
Atom feed or entry.

=cut
