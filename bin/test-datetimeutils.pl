#!/usr/bin/perl -wT

use strict;
use Time::Local;
use Data::Dumper;

require '../lib/DateTimeUtils.pm';


print  <<EOTEXT;

 year  (int)   (only year number like 13 for 2013);
 yearfull  (int) (will include century, so 2013);
 yearminus1900 (int) (will return 113 for 2013);
 monthnum  (int)
 0monthnum   (int) (leading zero)
 monthname (string)
 monthfullname (string)
 daynum  (int)
 0daynum  (int) (apply leading zero for single digit days)
 dayname (string)
 dayfullname (string)
 12hr (int)
 012hr  (int) (leading zero)
 24hr  (int) (automatically applies leading zero for single digit hours)
 min (int)
 0min (int) (apply leading zero for single digit mins)
 sec (int)
 0sec (int)
 ap or a.p. or AP or A.P. (string)
 offset  (string)(returns  -4 or -5)
 0offset  (string)(returns -0400 )  
 0offset: (string) (returns -04:00 )
 tz or TZ  (string)(returns edt or est or EDT or EST)

EOTEXT


my $format = <<EOFORMAT;  
 (year)
 (yearfull)
 (yearminus1900)
 (monthnum)
 (0monthnum)
 (monthname)
 (monthfullname)
 (daynum)
 (0daynum)
 (dayname)
 (dayfullname)
 (12hr)
 (012hr)
 (24hr)
 (min)
 (0min)
 (sec)
 (0sec)
 (ap)
 (a.p.)
 (AP)
 (A.P.)
 (offset)
 (0offset)
 (0offset:)
 (tz)
 (TZ)

EOFORMAT

# timegm or timelocal
# (secs, mins, hrs, mday, mon, year)
# if already have date broken down into numerics
# returns the number of epoch seconds for the date given
my $time = timegm(8, 38, 4, 18, 0, 103); # jan 17, 2003 11:38:08 p.m. EST -5
print $time . "\n\n";

my %hash = DateTimeUtils::create_date_time_stamp_local($time);
print Dumper(\%hash);

my $e = DateTimeUtils::convert_date_to_epoch("2003-01-18 04:38:08");
print "\n $e \n";

print "\n what if date string is local to Toledo, but code runs on server in California, and I want the returned epoch secondes to reflect Toledo time and that epoch number gets passed to the create date-time stamp routine. what date info is returned?\n";

$e = DateTimeUtils::convert_date_to_epoch("2013-07-07 13:10:30");
print "\n current toledo date and time as i typed this:  $e \n";

# since the above epoch is already for toledo time, use utc sub. 
# the returned hour vars are correct, but of course, the tz says utc instead of edt.
%hash = DateTimeUtils::create_date_time_stamp_utc($e);
print Dumper(\%hash);

print "displaying output from my variables submitted in string to sub\n";
print DateTimeUtils::create_date_time_stamp_local($format);

