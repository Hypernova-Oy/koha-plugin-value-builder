package Koha::Plugin::Fi::Hypernova::ValueBuilder::Controller;

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# This program comes with ABSOLUTELY NO WARRANTY;

use Modern::Perl;

use Mojo::Base 'Mojolicious::Controller';

use Koha::Plugin::Fi::Hypernova::ValueBuilder::Factory;

sub get_concis_itemcallnumber {
    my $c = shift->openapi->valid_input or return;

    my $biblionumber = $c->validation->param('biblionumber');

    my $plugin = Koha::Plugin::Fi::Hypernova::ValueBuilder->new;

    my $itemcallnumber;

    eval {
        $itemcallnumber = Koha::Plugin::Fi::Hypernova::ValueBuilder::Factory::concis_itemcallnumber($plugin, $biblionumber);
    };
    if ($@) {
        return $c->render( status => 500, openapi => { error => "$@" } );
    } else {
        return $c->render( status => 200, openapi => { itemcallnumber => $itemcallnumber } );
    }
}

1;
