# $Id: API.pm,v 1.4 2003/09/08 04:04:40 btrott Exp $

package XML::Atom::API;
use strict;

use base qw( XML::Atom::ErrorHandler );
use LWP::UserAgent;
use XML::Atom::Entry;
use XML::LibXML;
use Digest::SHA1 qw( sha1_hex );
use MIME::Base64 qw( encode_base64 );

use constant NS => 'http://purl.org/atom/ns#';

sub new {
    my $class = shift;
    my $client = bless { }, $class;
    $client->init(@_) or return $class->error($client->errstr);
    $client;
}

sub init {
    my $client = shift;
    my %param = @_;
    $client->{ua} = LWP::UserAgent->new;
    $client->{ua}->agent('XML::Atom/' . XML::Atom->VERSION);
    if (my $uri = $param{IntrospectionURI}) {
        $client->introspect($uri) or return;
    }
    $client;
}

sub username {
    my $client = shift;
    $client->{username} = shift if @_;
    $client->{username};
}

sub password {
    my $client = shift;
    $client->{password} = shift if @_;
    $client->{password};
}

sub auth_digest {
    my $client = shift;
    $client->{auth_digest} = shift if @_;
    $client->{auth_digest};
}

sub introspect {
    my $client = shift;
    my($uri) = @_;
    my $req = HTTP::Request->new(GET => $uri);
    my $res = $client->{ua}->request($req);
    return $client->error("$uri returned " . $res->status_line)
        unless $res->is_success;
    my $parser = XML::LibXML->new;
    my $doc = $parser->parse_string($res->content);
    my @el = $doc->getElementsByTagNameNS(NS, 'introspection')
        or return $client->error("Invalid introspection file");
    for my $child ($el[0]->childNodes) {
        next unless ref($child) eq 'XML::LibXML::Element';
        $client->{uri}{$child->nodeName} = $child->textContent;
    }
    1;
}

sub getEntry {
    my $client = shift;
    my($url) = @_;
    my $req = HTTP::Request->new(GET => $url);
    my $res = $client->make_request($req);
    return $client->error("Error on GET $url: " . $res->status_line)
        unless $res->code == 200;
    XML::Atom::Entry->new(Stream => \$res->content);
}

sub createEntry {
    my $client = shift;
    my($entry) = @_;
    my $url = $client->{uri}{'create-entry'}
        or return $client->error("Must set create-entry before posting");
    my $req = HTTP::Request->new(POST => $url);
    $req->content_type('application/x.atom+xml');
    my $xml = $entry->as_xml;
    $req->content_length(length $xml);
    $req->content($xml);
    my $res = $client->make_request($req);
    return $client->error("Error on POST $url: " . $res->status_line)
        unless $res->code == 201;
    $res->header('Location');
}

sub updateEntry {
    my $client = shift;
    my($url, $entry) = @_;
    my $req = HTTP::Request->new(PUT => $url);
    $req->content_type('application/x.atom+xml');
    my $xml = $entry->as_xml;
    $req->content_length(length $xml);
    $req->content($xml);
    my $res = $client->make_request($req);
    return $client->error("Error on PUT $url: " . $res->status_line)
        unless $res->code == 200;
    1;
}

sub deleteEntry {
    my $client = shift;
    my($url) = @_;
    my $req = HTTP::Request->new(DELETE => $url);
    my $res = $client->make_request($req);
    return $client->error("Error on DELETE $url: " . $res->status_line)
        unless $res->code == 200;
    1;
}

sub searchEntries {
    my $client = shift;
    my $url = $client->{uri}{'search-entries'}
        or return $client->error("Must set search-entries before searching");
    $url .= '?atom-start-range=0&atom-end-range=20';
    my $req = HTTP::Request->new(GET => $url);
    my $res = $client->make_request($req);
    return $client->error("Error on GET $url: " . $res->status_line)
        unless $res->code == 200;
    my $parser = XML::LibXML->new;
    my $doc = $parser->parse_string($res->content);
    my @el = $doc->getElementsByTagNameNS(NS, 'search-results')
        or return $client->error("Invalid introspection file");
    my @res;
    for my $child ($el[0]->childNodes) {
        next unless ref($child) eq 'XML::LibXML::Element';
        my $res;
        for my $col (qw( id title )) {
            my @val = $child->getElementsByTagNameNS(NS, $col);
            $res->{$col} = $val[0]->textContent;
        }
        push @res, $res;
    }
    \@res;
}

sub make_request {
    my $client = shift;
    my($req) = @_;
    my $ua = $client->{ua};
    my $res;
    my $tries = 0;
    if ($client->{auth}{nextnonce}) {
        $client->add_auth_header($req, $client->{auth}{nextnonce});
    }
    {
        $res = $ua->request($req);
        if ($res->code == 401 && $tries++ < 5) {
            $client->{auth} =
                $client->parse_auth_header($res->header('WWW-Authenticate'));
            $client->add_auth_header($req, $client->{auth}{nonce});
            redo;
        } else {
            ## Either success or error... look for nextnonce.
            if (my $info = $res->header('X-Atom-Authentication-Info')) {
                my $param = $client->parse_auth_header($info);
                $client->{auth}{nextnonce} = $param->{nextnonce};
            }
            return $res;
        }
    }
}

sub parse_auth_header {
    my $client = shift;
    my($auth_header) = @_;
    $auth_header =~ s/Atom //;
    my %param;
    for my $i (split /,\s*/, $auth_header) {
        my($k, $v) = split /=/, $i, 2;
        $v =~ s/^"//;
        $v =~ s/"$//;
        $param{$k} = $v;
    }
    \%param;
}

sub add_auth_header {
    my $client = shift;
    my($req, $nonce) = @_;
    my $auth = $client->{auth};
    my $digest = $client->auth_digest ||
      sha1_hex(join ':', $client->username, $auth->{realm}, $client->password);
    my $a2 = join ':', $req->method, $req->uri;
    my $cnonce = sha1_hex(sha1_hex(time() . {} . rand() . $$));
    my $res = sha1_hex(join ':', $digest, $nonce, '00000001',
                       $cnonce, $auth->{qop}, sha1_hex($a2));
    $req->header('X-Atom-Authorization', sprintf
        qq(Atom username="%s", realm="%s", nonce="%s", uri="%s", qop="atom-auth", nc="00000001", cnonce="%s", response="%s"),
        $client->username, $auth->{realm}, $nonce, $req->uri,
        $cnonce, $res);
    $req->header('Authorization', 'Atom key="value"');
}

1;
__END__

=head1 NAME

XML::Atom::API - A client for the Atom API

=head1 SYNOPSIS

    use XML::Atom::API;
    use XML::Atom::Entry;
    my $api = XML::Atom::API->new;
    $api->introspect('http://www.my-weblog.com/atom');
    $api->username('Melody');
    $api->password('Nelson');

    my $entry = XML::Atom::Entry->new;
    $entry->title('New Post');
    $entry->content('Content of my post.');
    my $url = $api->createEntry($entry);

=head1 DESCRIPTION

I<XML::Atom::API> implements a client for the Atom API described at
I<http://bitworking.org/rfc/draft-gregorio-07.html>, with the
authentication scheme described at
I<http://bitworking.org/news/New_AtomAPI_Implementation_Release2>.

=head1 USAGE

=head2 XML::Atom::API->new(%param)

=head2 $api->username([ $username ])

=head2 $api->password([ $password ])

=head2 $api->introspect($url)

=head2 $api->createEntry($entry)

Creates a new entry.

I<$entry> must be an I<XML::Atom::Entry> object.

=head2 $api->getEntry($url)

Retrieves the entry with the given URL I<$url>.

Returns an I<XML::Atom::Entry> object.

=head2 $api->updateEntry($url, $entry)

Updates the entry at URL I<$url> with the entry I<$entry>, which must be
an I<XML::Atom::Entry> object.

Returns true on success, false otherwise.

=head2 $api->deleteEntry($url)

Deletes the entry at URL I<$url>.

=head2 $api->searchEntries

Retrieves a list of entries.

Returns a reference to an array of hash references, each with two keys:
I<id>, the URL for editing/retrieving the entry; and I<title>, the
title of the entry.

=head2 ERROR HANDLING

Methods return C<undef> on error, and the error message can be retrieved
using the I<errstr> method.

=head1 AUTHOR & COPYRIGHT

Please see the I<XML::Atom> manpage for author, copyright, and license
information.

=cut
