#!/usr/bin/env perl

# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

BEGIN {
    #$ENV{LOG4PERL_VERBOSITY_CHANGE} = 6;
    #$ENV{MOJO_OPENAPI_DEBUG} = 1;
    #$ENV{MOJO_LOG_LEVEL} = 'debug';
    $ENV{VERBOSE} = 1;
    $ENV{KOHA_PLUGIN_DEV_MODE} = 1;
}

use Modern::Perl;
use utf8;

use Test::More tests => 1;
use Test::Deep;
use Test::Mojo;

use t::lib::TestBuilder;
use t::lib::Mocks;
use t::db_dependent::Util qw(build_patron);
use Mojo::Cookie::Request;

use Koha::Database;
use C4::Biblio;
use MARC::Record;

use Koha::Plugin::Fi::Hypernova::ValueBuilder;

my $schema = Koha::Database->schema;
my $builder = t::lib::TestBuilder->new;
$t::db_dependent::Util::builder = $builder;

#$schema->storage->txn_begin;
my $plugin = Koha::Plugin::Fi::Hypernova::ValueBuilder->new(); #Make sure the plugin is installed

my $t = Test::Mojo->new('Koha::REST::V1');
t::lib::Mocks::mock_preference( 'RESTBasicAuth', 1 );

subtest("Scenario: Concis itemcallnumber generation API call.", sub {
    my ($patron, $host, $patronPassword, $biblionumber, $item);

    plan tests => 12;

    subtest("Given a Patron with the Catalogue-permission", sub {
        plan tests => 1;

        ($patron, $host, $patronPassword) = build_patron({
            flags => 2,
        });
        ok($patron);
    });

    subtest("And a MARC Record with call numbers and a signum", sub {
        plan tests => 1;

        $biblionumber = C4::Biblio::AddBiblio(MARC::Record->new_from_usmarc(<<MARC
<record format="MARC21" type="Bibliographic">
  <datafield tag="084" ind1=" " ind2=" ">
    <subfield code="a">78.5129</subfield>
  </datafield>
  <datafield tag="100" ind1=" " ind2=" ">
    <subfield code="a">trad.</subfield>
  </datafield>
  <datafield tag="245" ind1="1" ind2="0">
    <subfield code="a">007 Talikkalan markkinoilla.</subfield>
  </datafield>
</record>
MARC
));
        ok($biblionumber);
    });

    subtest("And an Item", sub {
        plan tests => 1;

        $item = Koha::Item->new;
        $item->biblionumber($biblionumber);
        $item->store();
        ok($item->itemnumber);
    });

    subtest "GET /value-builder/concis-itemcallnumber" => sub {
        plan tests => 13;

        $t->get_ok($host.'/api/v1/contrib/value-builder/concis-itemcallnumber' => json => {itemnumber => $item->itemnumber})
        ->status_is('200')
        ->json_like('/itemcallnumber', qr/78\.5129 TRA/, 'itemcallnumber ok');

        $t->get_ok($host.'/api/v1/contrib/value-builder/concis-itemcallnumber' => json => {itemnumber => $item->itemnumber})
        ->status_is('400')
        ->json_like('/error', qr/itemnumber/, "No such itemnumber");
    };
});

#$schema->storage->txn_rollback;

sub prepareBasicAuthHeader {
    my ($username, $password) = @_;
    return 'Basic '.MIME::Base64::encode($username.':'.$password, '');
}

1;
