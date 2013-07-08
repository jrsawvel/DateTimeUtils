package DateTimeUtils;

use strict;
use Time::Local;


# receives date string as: YYYY-MM-DD HH-MM-SS
# date format used in database date field
# code from: http://stackoverflow.com/users/4234/dreeves
# in post: http://stackoverflow.com/questions/95492/how-do-i-convert-a-date-time-to-epoch-time-aka-unix-time-seconds-since-1970
# I changed timelocal to timegm
sub convert_date_to_epoch {
  my($s) = @_;
  my($year, $month, $day, $hour, $minute, $second);

  if($s =~ m{^\s*(\d{1,4})\W*0*(\d{1,2})\W*0*(\d{1,2})\W*0*
                 (\d{0,2})\W*0*(\d{0,2})\W*0*(\d{0,2})}x) {
    $year = $1;  $month = $2;   $day = $3;
    $hour = $4;  $minute = $5;  $second = $6;
    $hour |= 0;  $minute |= 0;  $second |= 0;  # defaults.
    $year = ($year<100 ? ($year<70 ? 2000+$year : 1900+$year) : $year);
    return timegm($second,$minute,$hour,$day,$month-1,$year);  
  }
  return -1;

}

# receives formatted date and time to local time
# and converts to Z time for pubDate RSS tag as:
# Tue, 04 Oct 2005 12:52:43 Z
sub format_date_time_for_rss {
    my $date = shift;  # format as: Jun 22, 2013
    my $time = shift;  # format as: 01:34:55 PM
 
    my %hash = ();
 
    my @short_month_names = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    
    my %months = (Jan => 0, 
                  Feb => 1,
                  Mar => 2,
                  Apr => 3,
                  May => 4,
                  Jun => 5,
                  Jul => 6,
                  Aug => 7,
                  Sep => 8,
                  Oct => 9,
                  Nov => 10,
                  Dec => 11);

    my @dow = qw(Sun Mon Tue Wed Thu Fri Sat);
 
    $time =~ m/(\d+):(\d+):(\d+)/; 
    my $hr  = $1;
    my $min = $2;
    my $sec = $3;

    if ( $time =~ m/pm/i and $hr != 12 ) {
        $hr+=12;    
    }

    $date =~ m/(\w+) (\d+), (\d+)/g;
    my $mon = $months{$1};
    my $day = $2;
    my $year = $3 - 1900;

    my $time_1 = timelocal($sec, $min, $hr, $day, $mon, $year); 

    my ($seconds, $minutes, $hours, $day_of_month, $month_of_year, $current_year, $wday) = (gmtime($time_1))[0,1,2,3,4,5,6];


    $hash{date} = sprintf "%s, %02d %s %d", $dow[$wday], $day_of_month, $short_month_names[$month_of_year], 1900 + $current_year;

    $hash{time} = sprintf "%02d:%02d:%02d Z", $hours, $minutes, $seconds;

    return %hash;
}

# convert this 2013-06-23T11:52:00-04:00 into a better format
sub reformat_nws_date_time {
    my $nws_date_time_str = shift;
    
    my %hash = ();

    if ( !$nws_date_time_str ) {
        $hash{date} = "-";
        $hash{time} = "-";
        $hash{period} = "-";
        return %hash;
    }

    my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

    my @values = split('T', $nws_date_time_str);

    # work on time first
    my @hrminsec = split('-', $values[1]);
    my @time = split(':', $hrminsec[0]);
    my $hr = $time[0];
    my $min = $time[1];

    my $prd = "am";
    if ( $hr >= 12 ) {
        $prd = "pm";
    }
    if ( $hr > 12 ) {
        $hr = $hr - 12;
    }
    if ( $hr == 0 ) {
        $hr = 12;
    }

    my $time_str = sprintf("%d:%02d", $hr, $min); 

    # work on date
    my @yrmonday = split('-', $values[0]);
    my $date_str = sprintf("%s %d, %d", $months[$yrmonday[1]-1], $yrmonday[2], $yrmonday[0]);

    $hash{date} = $date_str;
    $hash{time} = $time_str;
    $hash{period} = $prd;

    return %hash;
}

# optional arg of either the number of epoch secionds or a string of the returned format type
sub create_date_time_stamp_utc {
    my $arg1 = shift;
    my $arg2 = shift;

    return _create_date_time_stamp($arg1, $arg2, 0);
}

# eastern time zone only for now
sub create_date_time_stamp_local {
    my $arg1 = shift;
    my $arg2 = shift;

    return _create_date_time_stamp($arg1, $arg2, -5);
}

sub _create_date_time_stamp {
    my $arg1 = shift;
    my $arg2 = shift;
    my $offset = shift;

    my %arg_hash = _process_args($arg1, $arg2);

    my $epochsecs   = $arg_hash{epochsecs};
    my $format      = $arg_hash{format};
    my $return_hash = $arg_hash{return_hash};

    if ( $arg_hash{error} ) {
        if ( $arg_hash{return_hash} ) {
            return %arg_hash;
        } else {
            return $arg_hash{error_string};
        }
    }

    my @monname     = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my @monfullname = qw(January February March April May June July August September October November December);
    my @dayname     = qw(Sun Mon Tue Wed Thu Fri Sat);
    my @dayfullname = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);

    my %datetime = _initialize_datetime_hash();

    # tag=todo: for now, hard code this to work for eastern time zone, but need to make it user defined.
    # set to Eastern U.S.
    my $abs_offset = abs($offset);
    $datetime{'offset'}    = $offset;     # EST offset from GMT
    $datetime{'0offset'}   = "-0" . $abs_offset . "00";
    $datetime{'0offset:'}  = "-0" . $abs_offset . ":00";
    $datetime{'tz'} = "est";
    $datetime{'TZ'} = "EST";

    # determine if it's daylight savings time for eastern time zone
    my $isdst = (localtime($epochsecs))[8];
    if ( $isdst and $offset != 0 ) {
        $offset++;
        $abs_offset = abs($offset);
        $datetime{'offset'}    =  $offset;
        $datetime{'0offset'}   = "-0" . $abs_offset . "00";
        $datetime{'0offset:'}  = "-0" . $abs_offset . ":00";
        $datetime{'tz'} = "edt";
        $datetime{'TZ'} = "EDT";
    } 

    $epochsecs = $epochsecs + ($datetime{'offset'} * 3600); 

    if ( $offset == 0 ) {
        $datetime{'tz'} = "utc";
        $datetime{'TZ'} = "UTC";
    }

    my ($s, $mi, $h)    = (gmtime($epochsecs))[0, 1, 2];
   
    $datetime{'ap'}   = "am";
    $datetime{'a.p.'} = "a.m.";
    $datetime{'AP'}   = "AM";
    $datetime{'A.P.'} = "A.M.";

    $datetime{'12hr'}  = $h;
    $datetime{'012hr'} = sprintf "%02d", $h;
    $datetime{'24hr'}  = sprintf "%02d", $h;
    if ( $h > 11 ) 
    {
        $datetime{'ap'}   = "pm";
        $datetime{'a.p.'} = "p.m.";
        $datetime{'AP'}   = "PM";
        $datetime{'A.P.'} = "P.M.";
        if ( $h > 12 ) {
            $datetime{'12hr'}  = $h - 12;
            $datetime{'012hr'} = sprintf "%02d", $h-12;
        }
    } elsif ( $h == 0 ) {
        $datetime{'12hr'}  = 12;
        $datetime{'012hr'} = 12;
    }

    my ($d, $m, $y, $wd) = (gmtime($epochsecs))[3,4,5,6];
    my $cen = 19;
    $datetime{'yearminus1900'} = $y;
    if ( $y >= 100 ) {
        $y = $y - 100;
        $cen = 20;
    }

    $datetime{'year'}      = $y;
    $datetime{'0year'}     = sprintf "%02d", $y;
    $datetime{'yearfull'}  = sprintf "%d%02d", $cen, $y;

    $datetime{'monthnum'}          = $m+1;
    $datetime{'0monthnum'}         = sprintf "%02d", $m+1;
    $datetime{'monthname'}      = $monname[$m];
    $datetime{'monthfullname'}  = $monfullname[$m];

    $datetime{'daynum'}          = $d;
    $datetime{'0daynum'}         = sprintf "%02d", $d;
    $datetime{'dayname'}      = $dayname[$wd];
    $datetime{'dayfullname'}  = $dayfullname[$wd];

    $datetime{'min'}   = $mi;
    $datetime{'0min'}  = sprintf "%02d", $mi;

    $datetime{'sec'}   = $s;
    $datetime{'0sec'}  = sprintf "%02d", $s;

    if ( $return_hash ) {
        return %datetime; 
    } 

    $format =~ s/yearfull/$datetime{'yearfull'}/g;
    $format =~ s/0year/$datetime{'0year'}/g;
    $format =~ s/year/$datetime{'year'}/g;

    $format =~ s/monthfullname/$datetime{'monthfullname'}/g;
    $format =~ s/monthname/$datetime{'monthname'}/g;
    $format =~ s/0monthnum/$datetime{'0monthnum'}/g;
    $format =~ s/monthnum/$datetime{'monthnum'}/g;

    $format =~ s/dayfullname/$datetime{'dayfullname'}/g;
    $format =~ s/dayname/$datetime{'dayname'}/g;
    $format =~ s/0daynum/$datetime{'0daynum'}/g;
    $format =~ s/daynum/$datetime{'daynum'}/g;

    $format =~ s/\(24hr\)/$datetime{'24hr'}/g;
    $format =~ s/\(012hr\)/$datetime{'012hr'}/g;
    $format =~ s/\(12hr\)/$datetime{'12hr'}/g;

    $format =~ s/0min/$datetime{'0min'}/g;
    $format =~ s/min/$datetime{'min'}/g;

    $format =~ s/0sec/$datetime{'0sec'}/g;
    $format =~ s/sec/$datetime{'sec'}/g;

    $format =~ s/ap/$datetime{'ap'}/g;
    $format =~ s/a\.p\./$datetime{'a.p.'}/g;
    $format =~ s/AP/$datetime{'AP'}/g;
    $format =~ s/A\.P\./$datetime{'A.P.'}/g;

    $format =~ s/0offset:/$datetime{'0offset:'}/g;
    $format =~ s/0offset/$datetime{'0offset'}/g;
    $format =~ s/offset/$datetime{'offset'}/g;

    $format =~ s/tz/$datetime{'tz'}/g;
    $format =~ s/TZ/$datetime{'TZ'}/g;

    return $format;     
    
}

sub _is_numeric {
    my $str = shift;
    my $rc = 0;
    if ( $str =~ m|^[0-9]+$| ) {
        $rc = 1;
    }
    return $rc;
}

sub _process_args {
    my $arg1 = shift;
    my $arg2 = shift;

    my %hash;
    $hash{epochsecs}     = 0;
    $hash{format}        = "";
    $hash{return_hash}   = 0;
    $hash{error}         = 0;
    $hash{error_string}  = "";
  
    if ( $arg1 ) {
        if ( _is_numeric($arg1) ) {
            $hash{epochsecs} = $arg1;
        } else {
            $hash{format} = $arg1;
        }    
    }

    if ( $arg2 ) {
        if ( _is_numeric($arg2) ) {
            $hash{epochsecs} = $arg2;
        } else {
            $hash{format} = $arg2;
        }    
    }

    if ( $hash{epochsecs} == 0 ) {
        $hash{epochsecs} = time();
    }        

    if ( !$hash{format} ) {
        $hash{return_hash} = 1;
    }

    if ( $arg1 and $arg2 ) {
        if ( _is_numeric($arg1) and _is_numeric($arg2) ) {
            $hash{error} = 1;
            $hash{error_string} = "Both arguments are numeric.";
        } elsif ( !_is_numeric($arg1) and !_is_numeric($arg2) ) {
            $hash{error} = 1;
            $hash{error_string} = "Both arguments are strings.";
        }
    }

    return %hash;
}

# 27 keys
sub _initialize_datetime_hash {
    return (
        'year'            => 0,
        '0year'           => 0,
        'yearfull'        => 0,
        'yearminus1900'   => 0,
        'monthnum'        => 0,
        '0monthnum'       => 0,
        'monthname'       => "",
        'monthfullname'   => "",
        'daynum'          => 0,
        '0daynum'         => 0,
        'dayname'         => "",
        'dayfullname'     => "",
        '12hr'            => 0,
        '012hr'           => 0,
        '24hr'            => 0,
        'min'             => 0,
        '0min'            => 0,
        'sec'             => 0,
        '0sec'            => 0,
        'ap'              => "",
        'a.p.'            => "",
        'AP'              => "",
        'A.P.'            => "",
        'offset'          => "",
        '0offset'         => "",
        '0offset:'        => "",
        'tz'              => "",
        'TZ'              => "",
    );
}

1;

__END__

=head1 NAME

Date::Formatter - A simple Date and Time formatting object 

=head1 SYNOPSIS

  use My::DateTimeUtils;
  # todo: add code sample

=head1 DESCRIPTION

Description info here.

 format string variables:
 example:  dayname, monname, day, year 12hr:0min a.p.
 yields: Fri, Jul 5, 2013 11:08 a.m.

 year  (int)   (only year number like 13 for 2013);
 yearfull  (int) (will include century, so 2013);
 yearminus1900 (int) (will return 113 for 2013);
 mon  (int)
 0mon   (int) (leading zero)
 monname (string)
 monfullname (string)
 day  (int)
 0day  (int) (apply leading zero for single digit days)
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

=cut

