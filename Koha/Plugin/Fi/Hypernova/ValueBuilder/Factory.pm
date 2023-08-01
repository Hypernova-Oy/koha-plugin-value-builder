package Koha::Plugin::Fi::Hypernova::ValueBuilder::Factory;

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

sub concis_itemcallnumber {
    my ($plugin, $itemnumber) = @_;

    my $item = Koha::Items->find($itemnumber);
    my $record = Koha::Biblio::Metadata->find($item->biblionumber)->record;

    return callnumber($plugin, $record).' '.signum($plugin, $record);
}

sub _callnumber {
    my ($plugin, $record) = @_;

    my $pattern_itemcallnumber = $plugin->retrieve_data('pattern_itemcallnumber');

    my $callnumber_field = $record->fields('09.','084','080','082','065','050','060'); #In scalar-context picks the first found instance.
    $callnumber_field->subfield('a');
}

sub _signum {
    my ($plugin, $record) = @_;

    #Get the proper SIGNUM (important) Use one of the Main Entries or the Title Statement
    my $leader = $record->leader(); #If this is a video, we calculate the signum differently, 06 = 'g'
    my $signumSource; #One of fields 100, 110, 111, 130, or 245 if 1XX is missing
    my $nonFillingCharacters = 0;

    if (substr($leader,6,1) eq 'g' && ($signumSource = $record->subfield('245', 'a'))) {
        $nonFillingCharacters = $signumSource->parent()->indicator2();
    }
    elsif ($signumSource = $record->subfield('100', 'a')) {

    }
    elsif ($signumSource = $record->subfield('110', 'a')) {

    }
    elsif ($signumSource = $record->subfield('111', 'a')) {

    }
    elsif ($signumSource = $record->subfield('130', 'a')) {
        $nonFillingCharacters = $record->field('130')->indicator(1);
        $nonFillingCharacters = 0 if (not(defined($nonFillingCharacters)) || $nonFillingCharacters eq ' ');
    }
    elsif ($signumSource = $record->subfield('245', 'a')) {
        $nonFillingCharacters = $record->field('245')->indicator(2);
    }
    if ($signumSource) {
        $record->{signum} = uc(substr($signumSource, $nonFillingCharacters, 3));
    }
    return $signumSource;
}

1;