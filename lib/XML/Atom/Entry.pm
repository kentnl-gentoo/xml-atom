# $Id: Entry.pm,v 1.4 2003/09/29 04:19:25 btrott Exp $

package XML::Atom::Entry;
use strict;

use base qw( XML::Atom::Thing );
use MIME::Base64 qw( encode_base64 decode_base64 );
use XML::Atom::Author;

use constant NS => 'http://purl.org/atom/ns#';

sub element_name { 'entry' }

sub author {
    my $entry = shift;
    if (@_) {
        my $author = shift;
        $entry->{doc}->getDocumentElement->appendChild($author->{doc}->getDocumentElement->cloneNode(1));
        $entry->{__author} = $author;
    } else {
        unless (exists $entry->{__author}) {
            my $author = $entry->_first($entry->{doc}, NS, 'author') or return;
            $entry->{__author} = XML::Atom::Author->new(Doc => $author);
        }
    }
    $entry->{__author};
}

sub content {
    my $atom = shift;
    if (@_) {
        my $content = shift;
        if ($content =~ /[^\x09\x0a\x0d\x20-\x7f]/) {
            $atom->set(NS, 'content', encode_base64($content), { mode => 'base64' });
        } else {
            $content = '<div xmlns="http://www.w3.org/1999/xhtml">' .
                       $content .
                       '</div>';
            my $node;
            eval {
                my $parser = XML::LibXML->new;
                my $tree = $parser->parse_string($content);
                $node = $tree->getDocumentElement;
            };
            if (!$@ && $node) {
                $atom->set(NS, 'content', $node, { mode => 'xml' });
            } else {
                $atom->set(NS, 'content', $content, { mode => 'escaped' });
            }
        }
    } else {
        unless (exists $atom->{__content}) {
            my $content = $atom->_first($atom->{doc}, NS, 'content') or return;
            my $mode = $content->getAttribute('mode') || 'xml';
            if ($mode eq 'xml') {
                my @children = grep ref($_) =~ /Element$/, $content->childNodes;
                $atom->{__content} = @children ? $children[0]->toString :
                    $content->textContent;
            } elsif ($mode eq 'base64') {
                $atom->{__content} = decode_base64($content->textContent);
            } elsif ($mode eq 'escaped') {
                $atom->{__content} = $content->textContent;
            } else {
                $atom->{__content} = undef;
            }
            if ($] >= 5.008) {
                require Encode;
                Encode::_utf8_off($atom->{__content});
            }
        }
    }
    $atom->{__content};
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
