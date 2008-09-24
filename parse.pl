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

# Make this script parse your mails from nagios daemon
# using procmail or similar tool

use strict;

my $spool_dir = $ENV{'HOME'}.'/.dzen2/nagios/spool';
my $notify_script = $ENV{'HOME'}.'/.dzen2/nagios/notify.pl';

my ($host, $service, $state);

sub set_service_state;
sub set_host_state;

# [ CODE ]
while (my $line = <STDIN>) {
	chomp $line;

	if ($line =~ /^Service: (.*)/) {
		$service = $1;
	} elsif ($line =~ /^Host: (.*)/) {
		$host = $1;
	} elsif ($line =~ /^State: (.*)/) {
		$state = $1; 
	}
}

# If host or state undefined, than there is no work for us
defined $host or exit 0;
defined $state or exit 0;

# Now set host state or service state
if (defined $service) {
	set_service_state ($host, $service, $state);
} else {
	set_host_state ($host, $state);
}

exit 0;

# [ FUNCTIONS ] 
# rm_spool_file
# Removes file from spool_dir with name ARG1
sub rm_spool_file {
	my $file = shift;
	
	defined $spool_dir and -d $spool_dir or return 1;

	unlink "$spool_dir/$file";
	return 0;
}

# add_spool_file
# Adds new file with name $ARG1 in spool_dir 
# and write to it his state ($ARG2)
sub add_spool_file {
	my ($file, $state) = @_;

	defined $spool_dir and -d $spool_dir or return 1;

	open F, '>', "$spool_dir/$file" or die "can not open file $file for writing";
	print F $state;
	close F or die "can not close file $file";
	return 0;
}

# notify
# calls notify_script with --type $ARG1 --message $ARG2
sub notify {
	my ($type, $message) = @_;
	
	defined $notify_script and -x $notify_script or return 1;
	
	unless (fork) {
		exec $notify_script, '--type', $type, '--message', $message;
	}
	return 0;
}


# set_host_state
# contols spool file HOST-* adding/removing. 
# notify using notify func
sub set_host_state {
	my ($host, $state) = @_;
	my $fname = "HOST-$host";
	
	if ($state eq 'UP') {
		rm_spool_file ($fname);
		notify ('ok', "Host $host is UP");

	} else {
		add_spool_file ($fname, $state);
		my $type = ($state eq 'DOWN')? 'critical':'warning';
		notify ($type, "Host $host is $state");
	}
}



# set_service_state
# contols spool file SERVICE-* adding/removing. 
# notify using notify func
sub set_service_state {
	my ($host, $service, $state) = @_;
	my $fname = "SERVICE-$host-$service";
	
	if ($state eq 'OK') {
		rm_spool_file ($fname);
		notify ('ok', "Service $host:$service is OK");

	} else {
		add_spool_file ($fname, $state);
		my $type = ($state eq 'CRITICAL')? 'critical':'warning';
		notify ($type, "Service $host:$service is $state");
	}
}
