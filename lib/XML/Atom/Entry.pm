# $Id: Entry.pm,v 1.13 2004/05/09 10:44:55 btrott Exp $

package XML::Atom::Entry;
use strict;

use XML::Atom;
use base qw( XML::Atom::Thing );
use MIME::Base64 qw( encode_base64 decode_base64 );
use XML::Atom::Person;
use XML::Atom::Content;
use XML::Atom::Util qw( first );

use constant NS => 'http://purl.org/atom/ns#';

sub element_name { 'entry' }

sub _element {
    my $entry = shift;
    my($class, $name) = (shift, shift);
    my $root = LIBXML ? $entry->{doc}->getDocumentElement : $entry->{doc};
    if (@_) {
        my $obj = shift;
        if (my $node = first($entry->{doc}, NS, $name)) {
            $root->removeChild($node);
        }
        my $elem = LIBXML ?
            $entry->{doc}->createElementNS(NS, $name) :
            XML::XPath::Node::Element->new($name);
        $root->appendChild($elem);
        if (LIBXML) {
            for my $child ($obj->elem->childNodes) {
                $elem->appendChild($child->cloneNode(1));
            }
            for my $attr ($obj->elem->attributes) {
                next unless ref($attr) eq 'XML::LibXML::Attr';
                $elem->setAttribute($attr->getName, $attr->getValue);
            }
        } else {
            for my $child ($obj->elem->getChildNodes) {
                $elem->appendChild($child);
            }
            for my $attr ($obj->elem->getAttributes) {
                $elem->appendAttribute($attr);
            }
        }
        $obj->{elem} = $elem;
        $entry->{'__' . $name} = $obj;
    } else {
        unless (exists $entry->{'__' . $name}) {
            my $elem = first($entry->{doc}, NS, $name) or return;
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

=head2 XML::Atom::Entry->new([ $stream ])

Creates a new entry object, and if I<$stream> is supplied, fills it with the
data specified by I<$stream>.

Automatically handles autodiscovery if I<$stream> is a URI (see below).

Returns the new I<XML::Atom::Entry> object. On failure, returns C<undef>.

I<$stream> can be any one of the following:

=over 4

=item * Reference to a scalar

This is treated as the XML body of the entry.

=item * Scalar

This is treated as the name of a file containing the entry XML.

=item * Filehandle

This is treated as an open filehandle from which the entry XML can be read.

=back

=head2 $entry->content([ $content ])

Returns the content of the entry. If I<$content> is given, sets the content
of the entry. Automatically handles all necessary escaping.

=head2 $entry->author([ $author ])

Returns an I<XML::Atom::Person> object representing the author of the entry,
or C<undef> if there is no author information present.

If I<$author> is supplied, it should be an I<XML::Atom::Person> object
representing the author. For example:

    my $author = XML::Atom::Person->new;
    $author->name('Foo Bar');
    $author->email('foo@bar.com');
    $entry->author($author);

=head2 $entry->link

If called in scalar context, returns an I<XML::Atom::Link> object
corresponding to the first I<E<lt>linkE<gt>> tag found in the entry.

If called in list context, returns a list of I<XML::Atom::Link> objects
corresponding to all of the I<E<lt>linkE<gt>> tags found in the entry.

=head2 $entry->add_link($link)

Adds the link I<$link>, which must be an I<XML::Atom::Link> object, to
the entry as a new I<E<lt>linkE<gt>> tag. For example:

    my $link = XML::Atom::Link->new;
    $link->type('text/html');
    $link->rel('alternate');
    $link->href('http://www.example.com/2003/12/post.html');
    $entry->add_link($link);

=head1 AUTHOR & COPYRIGHT

Please see the I<XML::Atom> manpage for author, copyright, and license
information.

=cut
