#!/usr/bin/perl -w 
# Copyright (C) 2008  Artem S. <spiritedflow()gmail.com>
#
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

use strict;
use Getopt::Long;

my $dzen2='/usr/bin/dzen2';
my $display_file=$ENV{'HOME'}.'/.dzen2/nagios/run/display';

my ($type, $message);

my %colors = ( 
	'ok' => {-bg => 'green', -fg => 'black'},
	'warning' => {-bg => 'yellow', -fg => 'black'},
	'critical' => {-bg => 'red', -fg => 'white'},
	);
	
my @pos = ('-x', 724, '-w', 300, '-h', 19, '-y', 1);
my $sleep = 10;
my $font='-xos4-terminus-medium-*-normal-*-14-*-*-*-*-*-*-*';

# [ CODE ]

# Found wich display to use
# If there is no DISPLAY var in environment,
# then use that wich uses daemon.pl (it stores it
# to display_file)
unless ($ENV{'DISPLAY'}) {
	if ( -r $display_file ) {
		open F, '<', $display_file or die "can not open display file";
		chomp ($ENV{'DISPLAY'} = <F>);
		close F;
	} else {
		die "can not notify without DISPLAY setted";
	}
}

# Parse cmdline args
GetOptions(
	   "type|t=s" => \$type,
	   "message|m=s" => \$message,
	   "sleep|s=s" => \$sleep,
	   "font|f=s" => \$font,
	    ) or die "unknown params";

# Check passed params
defined $message or die "Undefined message, use --massage, Luke";
defined $type and defined $colors{$type} or $type = 'ok';


# Open dzen2
open DZEN, '|-', $dzen2, 
			'-p', $sleep, @pos, 
			'-fg', $colors{$type}{-fg}, 
			'-bg', $colors{$type}{-bg},
			'-fn', $font;

print DZEN $message,"\n";
close DZEN;
