# $Id: Makefile.PL,v 1.4 2003/09/08 07:33:37 btrott Exp $

use ExtUtils::MakeMaker;
use strict;

use ExtUtils::AutoInstall (
    -core => [
        'XML::LibXML' => 1.54,
        'MIME::Base64' => 0,
    ],

    'Client API' => [
        -default => 1,
        'LWP' => 0,
        'Digest::SHA1' => 0,
    ],

    'Auto-discovery' => [
        -default => 1,
        'HTML::Parser' => 0,
    ],

    'Namespace Normalization' => [
        -default => 0,
        'XML::LibXSLT' => 0,
    ],
);

WriteMakefile(
    NAME => 'XML::Atom',
    DISTNAME => 'XML-Atom',
    VERSION_FROM => 'lib/XML/Atom.pm',
    AUTHOR => 'Benjamin Trott <cpan@stupidfool.org>',
    ABSTRACT => 'Atom API and Feed support',
);
