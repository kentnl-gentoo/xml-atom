# $Id: Entry.pm,v 1.2 2003/09/08 03:38:49 btrott Exp $

package XML::Atom::Entry;
use strict;

use base qw( XML::Atom::Thing );
use MIME::Base64 qw( encode_base64 decode_base64 );

sub element_name { 'entry' }

sub content {
    my $atom = shift;
    if (@_) {
        my $content = shift;
        if ($content =~ /[^\x09\x0a\x0d\x20-\x7f]/) {
            $atom->set('content', encode_base64($content), { mode => 'base64' });
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
                $atom->set('content', $node, { mode => 'xml' });
            } else {
                $atom->set('content', $content, { mode => 'escaped' });
            }
        }
    } else {
        unless (exists $atom->{__content}) {
            my $content = $atom->_first($atom->{doc}, 'content') or return;
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

=head1 AUTHOR & COPYRIGHT

Please see the I<XML::Atom> manpage for author, copyright, and license
information.

=cut
