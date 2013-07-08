#!/usr/bin/perl -wT

use strict;

require '../lib/DateTimeUtils.pm';

my $dt1 = DateTimeUtils::create_date_time_stamp_utc("(yearfull)-(0monthnum)-(0daynum) (24hr):(0min):(0sec)");
print "     new sub utc: $dt1 \n";

my $dt2 = DateTimeUtils::create_database_datetime_stamp();
print "specific sub utc: $dt2 \n";

my $dt3 = DateTimeUtils::create_date_time_stamp_local("(yearfull)-(0monthnum)-(0daynum) (24hr):(0min):(0sec)");
print "   new sub local: $dt3 \n";
