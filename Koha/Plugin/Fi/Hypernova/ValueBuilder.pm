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

our $VERSION = "23.05.2";

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

sub api_routes {
    my ( $self, $args ) = @_;

    my $spec_str = $self->mbf_read('openapi_paths.json');
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

sub intranet_js {
     my ( $self ) = @_;

     return <<'JAVASCRIPT'
<script>
if (document.getElementById("cat_additem")) {
let kpfhvb_plugin_indicator;
let kpfhvb_icn_value_input;

function kpfhvb_err_and_die(log_object, alert_msg="") {
    if (!alert_msg && typeof log_object === "string") {
        alert_msg = log_object;
    }
    if (alert_msg) { alert("Koha::Plugin::Fi::Hypernova::ValueBuilder:> "+alert_msg) }
    console.error(log_object);
    return;
}
function kpfhvb_getBiblionumber () {
    let biblionumber = document.querySelector("input[name='biblionumber'][type='hidden']");
    if (!biblionumber) { kpfhvb_err_and_die("Couldn't detect biblionumber!") }
    return biblionumber.value;
}
function kpfhvb_getItemcallnumberValueInputElement () {
    kpfhvb_icn_value_input = document.querySelector("#subfield952o input");
    if (!kpfhvb_icn_value_input) { kpfhvb_err_and_die("Couldn't detect items.itemcallnumber input field!") }
    return kpfhvb_icn_value_input;
}
function kpfhvb_bindItemcallnumberInputFieldActions (biblionumber) {
    kpfhvb_icn_value_input.addEventListener("focus", function (event) {
        if (this.value !== "") { return } // Do not overwrite existing values
        kpfhvb_requestConcisItemcallnumber(biblionumber);
    });
}
function kpfhvb_deployPluginIndicator () {
    icn_input_container = document.querySelector("#subfield952o");
    if (!icn_input_container) { kpfhvb_err_and_die("Couldn't detect items.itemcallnumber input container!") }
    kpfhvb_plugin_indicator = document.createElement("i");
    kpfhvb_plugin_indicator.id = "kpfhvb_plugin_indicator_itemcallnumber";
    kpfhvb_plugin_indicator.classList.add("fa","fa-lg","fa-puzzle-piece");
    kpfhvb_plugin_indicator.style.marginLeft = "0.4em";
    kpfhvb_plugin_indicator.style.fontSize = "2em";
    kpfhvb_plugin_indicator.title = "Affected by the ValueBuilder-plugin. On input-field focus fetches the itemcallnumber information, if the field is empty.";
    icn_input_container.append(kpfhvb_plugin_indicator);
}
function kpfhvb_requestConcisItemcallnumber (biblionumber) {
    kpfhvb_plugin_indicator.classList.add("pulsating-animation");
    $.ajax('/api/v1/contrib/value-builder/concis-itemcallnumber?biblionumber='+biblionumber)
    .then(function(data, textStatus, jqXHR) {
        kpfhvb_plugin_indicator.classList.remove("pulsating-animation");
        kpfhvb_icn_value_input.value = data.itemcallnumber;
    })
    .fail(function(jqXHR, textStatus, errorThrown) {
        kpfhvb_plugin_indicator.classList.remove("pulsating-animation");
        kpfhvb_icn_value_input.value = "REST API ERROR";
        kpfhvb_err_and_die(jqXHR, textStatus);
    })
}
$(document).ready(function(){
    let biblionumber = kpfhvb_getBiblionumber();
    kpfhvb_icn_value_input = kpfhvb_getItemcallnumberValueInputElement();

    kpfhvb_bindItemcallnumberInputFieldActions(biblionumber);

    kpfhvb_deployPluginIndicator();
});
}
</script>
JAVASCRIPT
}

sub intranet_head {
     my ( $self ) = @_;

     return <<'CSS';
<style>
.pulsating-animation {
    animation: pulse-animation 2s infinite;
}

@keyframes pulse-animation {
    0% {
        box-shadow: 0 0 00px 0px rgba(0, 0, 0, 0.2);
    }
    100% {
        box-shadow: 0 0 10px 10px rgba(0, 0, 0, 0);
    }
}
</style>
CSS
}

1;
