package Koha::Plugin::Fi::Hypernova::ValueBuilder;

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

use base qw(Koha::Plugins::Base);

use Mojo::JSON qw(decode_json);

use Koha::Plugin::Fi::Hypernova::ValueBuilder::Configure;
use Koha::Plugin::Fi::Hypernova::ValueBuilder::Factory;

our $VERSION = "23.05.0";

our $metadata = {
    name            => 'Value Builder',
    author          => 'Olli-Antti Kivilahti',
    date_authored   => '2023-07-31',
    date_updated    => "2023-07-31",
    minimum_version => '18.11.00.000',
    maximum_version => undef,
    version         => $VERSION,
    description     => 'This plugin adds routes to return string-values based on configurations. Used to for example populate the itemcallnumber when adding Items.',
};

sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    ## Here, we call the 'new' method for our base class
    ## This runs some additional magic and checking
    ## and returns our actual $self
    my $self = $class->SUPER::new($args);

    return $self;
}

sub intranet_js {
     my ( $self ) = @_;

     return q%
         <script>
            $(document).ready(function(){
                $('#cataloguing_additem_newitem input[type="submit"]').click(function() {
                    var submit = this;
                    var barcode = $("div#subfield952p input[name=items\\\\.barcode]");
                    var library_id = $("div#subfield952a select[name=items\\\\.homebranch]");

                    // Koha 21.05 and below support BEGIN
                    $('*[name="field_value"]').each(function() {
                        if(/tag_952_subfield_p/.test(this.id)) {
                            barcode = this;
                        }
                        if(/tag_952_subfield_a/.test(this.id)) {
                            library_id = this;
                        }
                    });
                    // Koha 21.05 and below support END

                    if(!barcode.length || $(barcode).val()) return true;
                    $.ajax('/api/v1/contrib/barcode-generator/barcode?library_id='+$(library_id).val())
                    .then(function(res) {
                        $(barcode).val(res.barcode);
                        submit.click();
                    })
                    .fail(function(err) {
                        console.log(err);
                    })

                    return false;
                })
            })
         </script>
     %;
}

sub api_routes {
    my ( $self, $args ) = @_;

    my $spec_str = $self->mbf_read('openapi.json');
    my $spec     = decode_json($spec_str);

    return $spec;
}

sub api_routes2 {
    my ( $plugin, $args ) = @_;

    my $spec_dir = $plugin->mbf_dir();

    my $schema = JSON::Validator::Schema::OpenAPIv2->new;
    my $spec = $schema->resolve($spec_dir . '/openapi.yaml');

    # The installer automatically changes the references to absolute (bug33503), but not during development.
    # To have this work more easily during development, we still check for dynamic $refs
    # Remove this comment when the Bug 33505 compatibility is no longer needed.
    return Koha::Plugin::Fi::Hypernova::ValueBuilder::URLLib::convert_refs_to_absolute($spec->data->{'paths'}, 'file://' . $spec_dir . '/');
}

sub api_namespace {
    my ( $self ) = @_;
    
    return 'value-builder';
}

sub configure {
    Koha::Plugin::Fi::Hypernova::ValueBuilder::Configure::configure(@_);
}

sub install {
    return 1;
}

sub uninstall {
    return 1;
}

1;
