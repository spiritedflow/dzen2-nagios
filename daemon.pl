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
use File::Basename;
use Linux::Inotify2;

my $spool_dir = $ENV{'HOME'}.'/.dzen2/nagios/spool';
my $dzen2='/usr/bin/dzen2';
my $display_file=$ENV{'HOME'}.'/.dzen2/nagios/run/display';

my $font='-xos4-terminus-medium-*-normal-*-14-*-*-*-*-*-*-*';
my @pos = ('-x', 500, '-w', 150, '-y', 749);

our %status = ();

sub format_status; 
sub refresh_status;

# [ CODE ]

# Open Dzen2 process
our $dzen_fd;
open $dzen_fd, '|-', $dzen2, '-p', '-u',
			'-ta', 'l',
			'-fn', $font,
#			'-bg', 'black', '-fg', 'white',
			@pos
			or die "can not fork dzen2";
$dzen_fd->autoflush(1);

# Initialize inotify and make it watching for $spool_dir
my $inotify = new Linux::Inotify2
		or die "Unable to create new inotify object: $!" ;

$inotify->watch ($spool_dir, IN_MODIFY | IN_CREATE | IN_DELETE)
    or die "watch creation failed" ;


# Main loop: 
while () {
	refresh_status();
	print $dzen_fd format_status;
	
	my @events = $inotify->read;
	unless (@events > 0) {
		print "read error: $!";
		last ;
	}
	#print "Updated\n";
}


# [ FUNCTIONS ] 

# colorize
# colorize digit if it defined and greater than zero
# else returns '0'
sub colorize {
	my ($n, $color) = @_;
	
	defined $n and $n > 0 or return '0';
	
	return "^fg($color)$n^fg(gray)";
}

# format_status
# returns string "Nagios is OK" if there is no events
# else returns colorized status: 
#  H: <DOWN>/<UNREACHABLE> S: <CRITICAL>/<WARNING>/<UNKNOWN>
sub format_status {
	
	$status{'TOTAL'} or return "Nagios is OK\n";

	return sprintf ("H:%s/%s S:%s/%s/%s %s\n",
					colorize ($status{'HOST'}{'DOWN'}, 'red'),
					colorize ($status{'HOST'}{'UNREACHABLE'}, 'lightblue'),
					colorize ($status{'SERVICE'}{'CRITICAL'}, 'red'),
					colorize ($status{'SERVICE'}{'WARNING'}, 'yellow'),
					colorize ($status{'SERVICE'}{'UNKNOWN'}, 'lightblue'),
					$status{'UNDEF'} || ''
					);
	
}

# refresh_status
# rereads $spool_dir, reads all files
# and refill hash %status
sub refresh_status {
	%status = ( 'HOST' => { 'DOWN' => 0,
			                'UNREACHABLE' => 0
				          },
			    'SERVICE' => { 'CRITICAL' => 0,
			                   'WARNING' => 0,
							   'UNKNOWN' => 0
							 },
				'UNDEF' => 0,
				'TOTAL' => 0
			   );
	
	foreach my $file (glob $spool_dir.'/'.'*') {
		$status{'TOTAL'}++;

		# get filename
		my $fname = (fileparse($file))[0];
		# get type. if it is not defined, 
		# then inc UNDEF and go to next file
		unless ($fname =~ m!^(SERVICE|HOST)!) {
			$status{'UNDEF'} ++;
			next
		}
		my $type = $1;
		
		# read state
		open F, '<', $file or next;
		my $state = <F>;
		chomp $state;
		close F;

		# write to %status
		if (exists $status{$type}{$state}) {
			$status{$type}{$state}++;
		} else {
			$status{'UNDEF'} ++;
		}
	}
}
