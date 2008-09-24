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
use Config::Auto;

my $base = $ENV{'HOME'}.'/.dzen2/nagios';

my $message;
my $type = 'ok';
my ($font, $sleep, @pos);
my %colors;


# [ CODE ]

# Parse cmdline args
GetOptions(
	   "type|t=s" => \$type,
	   "message|m=s" => \$message,
	   "sleep|s=s" => \$sleep,
	   "font|f=s" => \$font,
	   "base|b=s" => \$base,
	    ) or die "unknown params";

# Read config and load localmodule
my $cfg = Config::Auto::parse ($base.'/config', format => 'ini');
#require $base.'/module/common.pm';

# Init common variables
my $display_file = $base.'/run/display';
	
@pos = split /\s+/, $cfg->{'notify'}{'pos'};
$sleep ||= $cfg->{'notify'}{'sleep'};
$font ||= $cfg->{'notify'}{'font'};;
$colors{$_} = { -bg => $cfg->{'notify'}{$_.'_bg'},
				-fg => $cfg->{'notify'}{$_.'_fg'}}
		foreach (qw(ok warning critical));

# Check passed params
defined $message or die "Undefined message, use --massage, Luke";
defined $colors{$type} or die "Unknown type. Allowed: ok, warning, critical";

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

# Open dzen2
open DZEN, '|-', $cfg->{'tools'}{'dzen2'},
			'-p', $sleep, @pos, 
			'-fg', $colors{$type}{-fg}, 
			'-bg', $colors{$type}{-bg},
			'-fn', $font;

print DZEN $message,"\n";
close DZEN;
