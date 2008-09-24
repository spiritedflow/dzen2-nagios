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

# [ CODE ]

# Read cmdline arguments
GetOptions(
	   "base|b=s" => \$base,
	    ) or die "unknown params";

# Read config and load localmodule
my $cfg = Config::Auto::parse ($base.'/config', format => 'ini');
require $base.'/module/common.pm';

# Init common variables
my $spool_dir = $base.'/spool';

my $status = &common::refresh_status($spool_dir);
print &common::format_status($status);
