# $Id: Feed.pm,v 1.4 2003/12/15 18:11:59 btrott Exp $

package XML::Atom::Feed;
use strict;

use base qw( XML::Atom::Thing );
use XML::Atom::Entry;

use constant NS => 'http://purl.org/atom/ns#';

sub element_name { 'feed' }

sub entries {
    my $feed = shift;
    my @res = $feed->{doc}->getElementsByTagNameNS(NS, 'entry') or return;
    my @entries;
    for my $res (@res) {
        my $entry = XML::Atom::Entry->new(Elem => $res->cloneNode(1));
        push @entries, $entry;
    }
    @entries;
}

sub add_entry {
    my $feed = shift;
    my($entry) = @_;
    $feed->{doc}->getDocumentElement->appendChild($entry->{doc}->getDocumentElement);
}

1;
__END__

=head1 NAME

XML::Atom::Feed - Atom feed

=head1 SYNOPSIS

    use XML::Atom::Feed;
    use XML::Atom::Entry;
    my $feed = XML::Atom::Feed->new;
    $feed->title('My Weblog');
    my $entry = XML::Atom::Entry->new;
    $entry->title('First Post');
    $entry->content('Post Body');
    $feed->add_entry($entry);
    my @entries = $feed->entries;
    my $xml = $feed->as_xml;

    ## Get a list of the <link rel="..." /> tags in the feed.
    my $links = $feed->get_links;

=head1 AUTHOR & COPYRIGHT

Please see the I<XML::Atom> manpage for author, copyright, and license
information.

=cut
