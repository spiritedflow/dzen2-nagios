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
use IO::Handle;
use Linux::Inotify2;
use Getopt::Long;
use Config::Auto;

my $base = $ENV{'HOME'}.'/.dzen2/nagios';
my $dump = 0;
my $dzen_fd;

# [ CODE ]

# Read cmdline arguments
GetOptions(
	   "base|b=s" => \$base,
	   "dump|d" => \$dump,
	    ) or die "unknown params";

# Read config and load localmodule
my $cfg = Config::Auto::parse ($base.'/config', format => 'ini');
require $base.'/module/common.pm';

# Init common variables
my $spool_dir = $base.'/spool';
my $display_file = $base.'/run/display';
my $dump_file = $base.'/run/status';

my $font = $cfg->{'daemon'}{'font'};
my @pos = split /\s+/, $cfg->{'daemon'}{'pos'};
my $fg_color = $cfg->{'daemon'}{'fg'};



# Initialize inotify and make it watching for $spool_dir
my $inotify = new Linux::Inotify2
	or die "Unable to create new inotify object: $!" ;

$inotify->watch ($spool_dir, IN_MODIFY | IN_CREATE | IN_DELETE)
    or die "watch creation failed" ;

unless ($dump) {
	# Open Dzen2 process
	open $dzen_fd, '|-', $cfg->{'tools'}{'dzen2'},
			'-p', '-u',
			'-ta', 'l',
			'-fn', $font,
			'-fg', $fg_color,
			@pos
			or die "can not fork dzen2";
	$dzen_fd->autoflush(1);
}


# Main loop: 
while () {
	my $status = &common::refresh_status ($spool_dir);
	my $str = &common::format_status ($status);
	
	unless ($dump) {
		print $dzen_fd $str;
	} else {
		open ST, '>', $dump_file or die "can not open dump_file: $!";
		print ST $str;
		close ST;
	}
	
	my @events = $inotify->read;
	unless (@events > 0) {
		print "read error: $!";
		last ;
	}
	#print "Updated\n";
}
