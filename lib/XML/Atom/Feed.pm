# $Id: Feed.pm,v 1.2 2003/09/08 03:38:49 btrott Exp $

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
        my $entry = XML::Atom::Entry->new(Doc => $res);
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

=head1 AUTHOR & COPYRIGHT

Please see the I<XML::Atom> manpage for author, copyright, and license
information.

=cut
