# $Id: Util.pm,v 1.3 2003/12/24 08:56:39 btrott Exp $

package XML::Atom::Util;
use strict;

use vars qw( @EXPORT_OK @ISA );
use Exporter;
@EXPORT_OK = qw( first textValue iso2dt encode_xml );
@ISA = qw( Exporter );

sub first {
    my @res = $_[1] ? $_[0]->getElementsByTagNameNS($_[1], $_[2]) :
                      $_[0]->getElementsByTagName($_[2]);
    return unless @res;
    $res[0];
}

sub textValue {
    my $node = first(@_) or return;
    $node->textContent;
}

sub iso2dt {
    my($iso) = @_;
    return unless $iso =~ /^(\d{4})(?:-?(\d{2})(?:-?(\d\d?)(?:T(\d{2}):(\d{2}):(\d{2})(?:\.\d+)?(?:Z|([+-]\d{2}:\d{2}))?)?)?)?/;
    my($y, $mo, $d, $h, $m, $s, $zone) =
        ($1, $2 || 1, $3 || 1, $4 || 0, $5 || 0, $6 || 0, $7);
    require DateTime;
    my $dt = DateTime->new(
               year => $y,
               month => $mo,
               day => $d,
               hour => $h,
               minute => $m,
               second => $s,
               time_zone => 'UTC',
    );
    if ($zone && $zone ne 'Z') {
        my $seconds = DateTime::TimeZone::offset_as_seconds($zone);
        $dt->subtract(seconds => $seconds);
    }
    $dt;
}

my %Map = ('&' => '&amp;', '"' => '&quot;', '<' => '&lt;', '>' => '&gt;',
           '\'' => '&apos;');
my $RE = join '|', keys %Map;

sub encode_xml {
    my($str) = @_;
    $str =~ s!($RE)!$Map{$1}!g;
    $str;
}

1;
__END__

=head1 NAME

XML::Atom::Util - Utility functions

=head1 SYNOPSIS

    use XML::Atom::Util qw( iso2dt );
    my $dt = iso2dt($entry->issued);

=head1 USAGE

=head2 iso2dt($iso)

Transforms the ISO-8601 date I<$iso> into a I<DateTime> object and returns
the I<DateTime> object.

=head2 encode_xml($str)

Encodes characters with special meaning in XML into entities and returns
the encoded string.

=head1 AUTHOR & COPYRIGHT

Please see the I<XML::Atom> manpage for author, copyright, and license
information.

=cut
