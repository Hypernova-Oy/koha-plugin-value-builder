package Koha::Plugin::Fi::Hypernova::ValueBuilder::Configure;

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

sub configure {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    unless ( $cgi->param('save') ) {
        my $template = $self->get_template( { file => 'configure.tt' } );

        ## Grab the values we already have for our settings, if any exist
        $template->param(
            pattern_itemcallnumber => $self->retrieve_data('pattern_itemcallnumber'),
        );

        $self->output_html( $template->output() );
    }
    else {
        $self->store_data(
            {
                pattern_itemcallnumber => $cgi->param('pattern_itemcallnumber'),
            }
        );
        $self->go_home();
    }
}

1;
