# $Id: API.pm,v 1.8 2003/09/28 06:10:18 btrott Exp $

package XML::Atom::API;
use strict;

use base qw( XML::Atom::ErrorHandler );
use LWP::UserAgent;
use XML::Atom;
use XML::Atom::Entry;
use XML::Atom::Util qw( first textValue );
use XML::LibXML;
use Digest::SHA1 qw( sha1_hex );
use MIME::Base64 qw( encode_base64 );
use DateTime;

use constant NS_ATOM => 'http://purl.org/atom/ns#';
use constant NS_SOAP => 'http://schemas.xmlsoap.org/soap/envelope/';

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

sub use_soap {
    my $client = shift;
    $client->{use_soap} = shift if @_;
    $client->{use_soap};
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
    my @el = $doc->getElementsByTagNameNS(NS_ATOM, 'introspection')
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
    my @el = $doc->getElementsByTagNameNS(NS_ATOM, 'search-results')
        or return $client->error("Invalid introspection file");
    my @res;
    for my $child ($el[0]->childNodes) {
        next unless ref($child) eq 'XML::LibXML::Element';
        my $res;
        for my $col (qw( id title )) {
            my @val = $child->getElementsByTagNameNS(NS_ATOM, $col);
            $res->{$col} = $val[0]->textContent;
        }
        push @res, $res;
    }
    \@res;
}

sub make_request {
    my $client = shift;
    my($req) = @_;
    $client->munge_request($req);
    my $res = $client->{ua}->request($req);
    $client->munge_response($res);
    $res;
}

sub munge_request {
    my $client = shift;
    my($req) = @_;
    my $nonce = $client->make_nonce;
    my $now = DateTime->now->iso8601 . 'Z';
    my $digest = encode_base64(sha1_hex($nonce . $now . $client->password), '');
    if ($client->use_soap) {
        my $xml = $req->content || '';
        $xml =~ s!^(<\?xml.*?\?>)!!;
        my $method = $req->method;
        $xml = $1 . <<SOAP;
<soap:Envelope
  xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
  xmlns:wsu="http://schemas.xmlsoap.org/ws/2002/07/utility"
  xmlns:wsse="http://schemas.xmlsoap.org/ws/2002/07/secext">
  <soap:Header>
    <wsse:Security>
      <wsse:UsernameToken>
        <wsse:Username>@{[ $client->username ]}</wsse:Username>
        <wsse:Password Type="wsse:PasswordDigest">$digest</wsse:Password>
        <wsse:Nonce>$nonce</wsse:Nonce>
        <wsu:Created>$now</wsu:Created>
      </wsse:UsernameToken>
    </wsse:Security>
  </soap:Header>
  <soap:Body>
    <$method xmlns="http://schemas.xmlsoap.org/wsdl/http/">
$xml
    </$method>
  </soap:Body>
</soap:Envelope>
SOAP
        $req->content($xml);
        $req->content_length(length $xml);
        $req->header('SOAPAction', 'http://schemas.xmlsoap.org/wsdl/http/' . $method);
        $req->method('POST');
        $req->content_type('text/xml');
    } else {
        $req->header('X-WSSE', sprintf
          qq(WSSE Username="%s", PasswordDigest="%s", Nonce="%s", Created="%s"),
          $client->username, $digest, $nonce, $now);
    }
}

sub munge_response {
    my $client = shift;
    my($res) = @_;
    if ($client->use_soap && (my $xml = $res->content)) {
        my $parser = XML::LibXML->new;
        my $doc = $parser->parse_string($xml);
        my $body = first($doc, NS_SOAP, 'Body');
        if (my $fault = first($body, NS_SOAP, 'Fault')) {
            $res->code(textValue($fault, undef, 'faultcode'));
            $res->message(textValue($fault, undef, 'faultstring'));
            $res->content('');
            $res->content_length(0);
        } else {
            $xml = join '', map $_->toString(1), $body->childNodes;
            $res->content($xml);
            $res->content_length(1);
        }
    }
}

sub make_nonce {
    my $app = shift;
    sha1_hex(sha1_hex(time() . {} . rand() . $$));
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
I<http://www.intertwingly.net/wiki/pie/DifferentlyAbledClients>.

B<NOTE:> the API, and particularly the authentication scheme, are still
in flux.

=head1 USAGE

=head2 XML::Atom::API->new(%param)

=head2 $api->use_soap([ 0 | 1 ])

I<XML::Atom::API> supports both the REST and SOAP-wrapper versions of the
Atom API. By default, the REST version of the API will be used, but you can
turn on the SOAP wrapper--for example, if you need to connect to a server
that supports only the SOAP wrapper--by calling I<use_soap> with a value of
C<1>:

    $api->use_soap(1);

If called without arguments, returns the current value of the flag.

=head2 $api->username([ $username ])

If called with an argument, sets the username for login to I<$username>.

Returns the current username that will be used when logging in to the
Atom server.

=head2 $api->password([ $password ])

If called with an argument, sets the password for login to I<$password>.

Returns the current password that will be used when logging in to the
Atom server.

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
