package common;

use File::Basename;

# colorize
# colorize digit if it defined and greater than zero
# else returns '0'
sub colorize {
	my ($n, $color) = @_;
	
	defined $n and $n > 0 or return '0';
	
	return "^fg($color)$n^fg()";
}

# format_status
# returns string "Nagios is OK" if there is no events
# else returns colorized status: 
#  H: <DOWN>/<UNREACHABLE> S: <CRITICAL>/<WARNING>/<UNKNOWN>
sub format_status {
	my $status = shift;
	$status->{'TOTAL'} or return "Nagios is OK\n";

	return sprintf ("H:%s/%s S:%s/%s/%s %s\n",
					colorize ($status->{'HOST'}{'DOWN'}, 'red'),
					colorize ($status->{'HOST'}{'UNREACHABLE'}, 'lightblue'),
					colorize ($status->{'SERVICE'}{'CRITICAL'}, 'red'),
					colorize ($status->{'SERVICE'}{'WARNING'}, 'yellow'),
					colorize ($status->{'SERVICE'}{'UNKNOWN'}, 'lightblue'),
					$status->{'UNDEF'} || ''
					);
	
}

# refresh_status
# rereads $spool_dir, reads all files
# and refill hash %status
sub refresh_status {
	my $spool_dir = shift;
	my $status={'HOST' => { 'DOWN' => 0,
			                'UNREACHABLE' => 0
				          },
			    'SERVICE' => { 'CRITICAL' => 0,
			                   'WARNING' => 0,
							   'UNKNOWN' => 0
							 },
				'UNDEF' => 0,
				'TOTAL' => 0
			   };
	
	foreach my $file (glob $spool_dir.'/'.'*') {
		$status->{'TOTAL'}++;

		# get filename
		my $fname = (fileparse($file))[0];
		# get type. if it is not defined, 
		# then inc UNDEF and go to next file
		unless ($fname =~ m!^(SERVICE|HOST)!) {
			$status->{'UNDEF'} ++;
			next
		}
		my $type = $1;
		
		# read state
		open F, '<', $file or next;
		my $state = <F>;
		defined $state or next;
		chomp $state;
		close F;

		# write to %status
		if (exists $status->{$type}{$state}) {
			$status->{$type}{$state}++;
		} else {
			$status->{'UNDEF'} ++;
		}
	}

	return $status;
}

1;