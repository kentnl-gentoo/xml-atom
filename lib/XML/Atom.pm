# $Id: Atom.pm,v 1.2 2003/09/08 03:38:48 btrott Exp $

package XML::Atom;
use strict;

use base qw( XML::Atom::ErrorHandler );

use vars qw( $VERSION );
$VERSION = '0.01';

## Methods to:
##     - set defaults (encoding, language?)
##     - set up modules/namespaces (add_module)
##     - syntactic sugar (new_feed, new_entry, etc)

1;
__END__

=head1 NAME

XML::Atom - Atom feed and API implementation

=head1 SYNOPSIS

    use XML::Atom;

=head1 DESCRIPTION

Atom is a syndication, API, and archiving format for weblogs and other
data. I<XML::Atom> implements the feed format as well as a client for the
API.

=head1 LICENSE

I<XML::Atom> is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR & COPYRIGHT

Except where otherwise noted, I<XML::Atom> is Copyright 2003 Benjamin
Trott, cpan@stupidfool.org. All rights reserved.

=cut
