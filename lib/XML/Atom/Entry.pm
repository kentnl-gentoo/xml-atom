# $Id: Entry.pm,v 1.10 2003/12/15 00:39:17 btrott Exp $

package XML::Atom::Entry;
use strict;

use base qw( XML::Atom::Thing );
use MIME::Base64 qw( encode_base64 decode_base64 );
use XML::Atom::Person;
use XML::Atom::Content;

use constant NS => 'http://purl.org/atom/ns#';

sub element_name { 'entry' }

sub _element {
    my $entry = shift;
    my($class, $name) = (shift, shift);
    my $root = $entry->{doc}->getDocumentElement;
    if (@_) {
        my $obj = shift;
        if (my $node = $entry->_first($entry->{doc}, NS, $name)) {
            $root->removeChild($node);
        }
        my $elem = $entry->{doc}->createElementNS(NS, $name);
        $root->appendChild($elem);
        for my $child ($obj->elem->childNodes) {
            $elem->appendChild($child->cloneNode(1));
        }
        for my $attr ($obj->elem->attributes) {
            next unless ref($attr) eq 'XML::LibXML::Attr';
            $elem->setAttribute($attr->getName, $attr->getValue);
        }
        $obj->{elem} = $elem;
        $entry->{'__' . $name} = $obj;
    } else {
        unless (exists $entry->{'__' . $name}) {
            my $elem = $entry->_first($entry->{doc}, NS, $name) or return;
            $entry->{'__' . $name} = $class->new(Elem => $elem);
        }
    }
    $entry->{'__' . $name};
}

sub author {
    my $entry = shift;
    $entry->_element('XML::Atom::Person', 'author', @_);
}

sub content {
    my $entry = shift;
    my @arg = @_;
    if (@arg && ref($arg[0]) ne 'XML::Atom::Content') {
        $arg[0] = XML::Atom::Content->new($arg[0]);
    }
    $entry->_element('XML::Atom::Content', 'content', @arg);
}

1;
__END__

=head1 NAME

XML::Atom::Entry - Atom entry

=head1 SYNOPSIS

    use XML::Atom::Entry;
    my $entry = XML::Atom::Entry->new;
    $entry->title('My Post');
    $entry->content('The content of my post.');
    my $xml = $entry->as_xml;
    my $dc = XML::Atom::Namespace->new(dc => 'http://purl.org/dc/elements/1.1/');
    $entry->set($dc->subject, 'Food & Drink');

=head1 USAGE

=head2 XML::Atom::Entry->new

Creates and returns a new entry object.

=head2 $entry->content([ $content ])

Returns the content of the entry. If I<$content> is given, sets the content
of the entry. Automatically handles all necessary escaping.

=head2 $entry->content_type([ $type ])

Returns the content type of the content in I<content>. If I<$type> is given,
sets the content type of the entry.

NOTE: this interface is almost certain to change.

=head2 $entry->author([ $author ])

Returns an I<XML::Atom::Author> object representing the author of the entry,
or C<undef> if there is no author information present.

If I<$author> is supplied, it should be an I<XML::Atom::Author> object
representing the author. For example:

    my $author = XML::Atom::Author->new;
    $author->name('Foo Bar');
    $author->email('foo@bar.com');
    $entry->author($author);

=head1 AUTHOR & COPYRIGHT

Please see the I<XML::Atom> manpage for author, copyright, and license
information.

=cut
