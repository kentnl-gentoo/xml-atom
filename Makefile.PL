# $Id: Makefile.PL,v 1.7 2003/12/30 06:59:05 btrott Exp $

use inc::Module::Install;

name('XML-Atom');
abstract('Atom API and Feed Support');
author('Benjamin Trott <cpan@stupidfool.org>');
version_from('lib/XML/Atom.pm');
license('perl');
no_index(directory => 't');
sign(1);

include('ExtUtils::AutoInstall');

requires('XML::LibXML' => 1.54);
requires('MIME::Base64');
requires('URI');

features(
    'Client/Server for Atom API' => [
        -default => 1,
        recommends('LWP'),
        recommends('Digest::SHA1'),
        recommends('DateTime'),
    ],

    'Feed and API Auto-discovery' => [
        -default => 1,
        recommends('HTML::Parser'),
    ],

    'Namespace Normalization' => [
        -default => 0,
        recommends('XML::LibXSLT'),
    ],
);

auto_include();
auto_install();

&WriteAll;
