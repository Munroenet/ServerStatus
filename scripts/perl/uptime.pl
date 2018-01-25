#!/usr/bin/perl
###
### uptime.pl: Generate the JSON info required for ServerStatus
###   https://github.com/Munzy/ServerStatus
###
### Copyright 2014 by Davy Chan <imchandave@gmail.com>
###
### Last updated: 2014-09-22
###

###
### Configfile is in the format:
###   pidfile="/pathname/filename" #comments begin with a '#'
###   # This is a comment
###   outfile=/path/to/file/can/be/enclosed/in/double/quotes
###   sleep=integer_value_of_seconds
###   daemon=true # close STDIN/STDOUT/STDERR and fork to background
###
### External dependencies:
###   /bin/df
###

use strict;
use warnings;

use vars qw( @ARGV );
use vars qw( @ENV );
use vars qw( %SIG );
use vars qw($sleep_secs $outfile $pidfile);
use vars qw($daemonize);
use vars qw($DF_CMD);
use vars qw(%array);
%main::array = ();
$main::sleep_secs = 0;
$main::outfile = $main::pidfile = "";
$main::daemonize = "false";
$main::DF_CMD = '/bin/df';

sub usage
{
  print STDERR <<EOM;
usage: $0 [...]
  --sleep secs: re-run $0 after secs of time
  --outfile file:      write JSON to file
  --pidfile file:      write PID to file
  --config file:       read configs from file
  --daemon true|false: close STDIN, STDOUT, & STDERR and chdir("/")
                       Note: --daemon must be the last option specified

EOM
}

sub cleanup
{
  if ( $main::pidfile && -f $main::pidfile ) {
    unlink($main::pidfile);
  }
  exit 0;
}

$SIG{'INT'} = 'cleanup';
$SIG{'TERM'} = 'cleanup';
$SIG{'QUIT'} = 'cleanup';

sub disk_info {
  ### Assuming /bin/df output is in the following format:
  ###   Filesystem 1K-Blocks Used Available Use% Mounted on
  ###
  my($fs) = @_;
  my($hddtotal,$hddfree) = (0,0);

  if (open(F,'-|',"$main::DF_CMD $fs")) {
    while (defined($_=<F>)) {
      next if ( ! /\/([^\s]+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+%)\s+$fs$/o );
      ($hddtotal,$hddfree) = ($2,$4); last;
    }
    close(F);
  }
  return ($hddtotal,$hddfree);
}

sub sec2human {
  my($time) = @_;

  my($seconds) = $time%60;
  my($mins) = int($time/60)%60;
  my($hours) = int($time/60/60)%24;
  my($days) = int($time/60/60/24);
  my($ret) = "";

  $ret = ($days > 0 ? $days . ' day' . ($days > 1 ? 's' : '') : $hours . ':' . $mins . ':' . $seconds);
  $ret;
}

sub GetUptime
{ ### Get Uptime
  my($uptime) = 0;
  if (open(F,"< /proc/uptime")) {
    $_ = <F>; chomp($_);
    close(F);
    if ( /(\d+)\.\d+\s+.*/o ) {
      $uptime = $1;
    }
  }
  $main::array{'uptime'} = &sec2human($uptime);
}

sub GetMemInfo
{ ### Get Memory stats
  ### Assuming /proc/meminfo output is in the following format:
  ###   Label: Kilobytes kB
  ###
  my($memtotal, $memfree, $memcache, $memmath) = (1, 0, 0, 0);
  my($memlevel) = "";
  my($memory);
  if (open(F,"< /proc/meminfo")) {
    while ($_ = <F>) {
      if ( /^MemTotal:\s+(\d+)\skB$/o ) {
        $memtotal = $1;
      } elsif ( /^MemFree:\s+(\d+)\skB$/o ) {
        $memfree = $1;
      } elsif ( /^Cached:\s+(\d+)\skB$/o ) {
        $memcache = $1;
      }
    }
    close(F);
  }
  $memmath = $memcache + $memfree;
  $memory = int($memmath / $memtotal * 100);
  if ( $memory >= 51 ) {
    $memlevel = "success";
  } elsif ( $memory <= 50 ) {
    $memlevel = "warning";
  } elsif ( $memory <= 35 ) {
    $memlevel = "danger";
  }
  $memory = "${memory}%";
  $main::array{'memory'} = '<div class="progress progress-striped active">
<div class="bar bar-' . $memlevel . '" style="width: ' . $memory . ';">' . $memory . '</div>
</div>';
}

sub AddHDDTotal {
  my($hddtotal) = @_;
  my($ret) = "";
  my($units) = 'MB';
  my($divisor) = 1024;

  $divisor = 1000 if ( ! -f '/proc/vz/veinfo' );
  if ( -f '/root/00README.stats' ) {
    $ret = int($hddtotal/$divisor);
    if ( $ret > 999 ) {
      $units = 'GB';
      $ret = int($ret/$divisor);
      if ( $ret > 999 ) {
        $units = 'TB';
        $ret = int($ret/$divisor)
      }
    }
    $ret = "(${ret}${units})";
  }
  $ret;
}

sub GetStorage
{ ### Get storage stats
  my($hddtotal, $hddfree) = (0,0);
  my($hddlevel) = "";
  my($hdd);
  my($hdd_present) = "";
  ($hddtotal, $hddfree) = &disk_info("/");
  $hddtotal = 1 if ( $hddtotal < 1 );
  $hdd = int($hddfree / $hddtotal * 100);
  if ( $hdd >= 51 ) {
    $hddlevel = "success";
  } elsif ( $hdd <= 50 ) {
    $hddlevel = "warning";
  } elsif ( $hdd <= 35 ) {
    $hddlevel = "danger";
  }
  $hdd="${hdd}%";
#  $hdd_present = &AddHDDTotal($hddtotal);
  $main::array{'hdd'} = '<div class="progress progress-striped active">
<div class="bar bar-' . $hddlevel . '" style="width: ' . $hdd . ';">' . $hdd . $hdd_present . '</div>
</div>';
}

sub GetLoadAvg
{ ### Get load average
  ### Assuming /proc/loadavg output is in the following format:
  ###   now.load five.load fifteen.load cpus/sch recent_pid
  ###
  my($load) = "0.0";
  if (open(F,"</proc/loadavg")) {
    $_=<F>;
    close(F);
    if ( /(\d+)\.(\d+)\s+.*/o ) {
      $load = "$1.$2";
    }
  }
  $main::array{'load'} = "${load}";
}

sub GetOnlineStatus
{ ### Assign online status
  $main::array{'online'} = '<div class="progress">
<div class="bar bar-success" style="width: 100%"><small>Up</small></div>
</div>';
}

sub GetTimestamp
{ ### Set timestamp
  $main::array{'timestamp'} = time;
}

sub mk_json {
  ### Print JSON version of array
  my($key) = "";
  my($json_str) = "{";
  foreach $key (keys %array) {
    $_ = $array{$key};
    s/"/\\"/g;
    s/\n/\\n/g;
    s/\//\\\//g;
    $json_str .= "\"${key}\":\"$_\",";
  }
  chop($json_str);
  $json_str .= "}";
  $json_str;
}

sub Daemonize
{
  if ( ! ($main::outfile && $main::pidfile) ) {
    print STDERR "ERR: --daemon must be preceeded by --pidfile and --outfile.\n";
    exit 1;
  }
  if ( $main::outfile !~ /^\// ) {
    print STDERR "ERR: outfile must be a full pathname.\n";
    exit 1;
  }
  chdir("/");
  close(STDIN); close(STDOUT); close(STDERR);
}

sub ProcessCmdOptions {
  my($arg, $arg1) = @_;
  if ( $arg =~ /^--sleep/o ) {
    $main::sleep_secs = int($arg1) if ( ! $main::sleep_secs );
  } elsif ( $arg =~ /^--outfile/o ) {
    $main::outfile = $arg1 if ( $main::outfile eq "" );
  } elsif ( $arg =~ /^--pidfile/o ) {
    $main::pidfile = $arg1 if ( $main::pidfile eq "" );
    $main::sleep_secs = 120 if ( ! $main::sleep_secs );
  } elsif ( $arg =~ /^--config/o ) {
    my($config_file) = $arg1;
    my($key,$value) = ("","");
    if ( ! -r $config_file ) {
      print STDERR "ERR: configfile ${config_file} does not exist!\n";
      exit 1;
    }
    if ( ! open(F,"< ${config_file}") ) {
      print STDERR "ERR: cannot open ${config_file}.\n";
      exit 1;
    }
    while ($_ = <F>) {
      next if ( /^#/o );
      if ( /([^=]+)\s*=\s*(.*)/o ) {
        ($key,$value) = split(/=/,$_);
        $key =~ s/^\s+//; $key =~ s/\s+$//;
        $key =~ s/^"//; $key =~ s/"$//;
        $value =~ s/#.*$//; $value =~ s/^\s+//; $value =~ s/\s+$//;
        $value =~ s/^"//; $value =~ s/"$//;
        next if ( $key eq "config" );
        &ProcessCmdOptions("--${key}", "${value}");
      }
    }
    close(F);
  } elsif ( $arg =~ /^--daemon/o ) {
    $main::daemonize = "true" if ( $arg1 =~ /true/i );
  } else {
    &usage; exit 1;
  }
}

###
### MAIN
###

while ( defined($ARGV[0]) && $ARGV[0] =~ /^--/o ) {
  my($arg) = shift;
  &ProcessCmdOptions($arg,$ARGV[0]);
  shift;
}

$main::sleep_secs = int($ENV{'SLEEP'}) if ( defined($ENV{'SLEEP'}) );
$main::outfile = $ENV{'OUTFILE'} if ( defined($ENV{'OUTFILE'}) );
$main::pidfile = $ENV{'PIDFILE'} if ( defined($ENV{'PIDFILE'}) );
if ( defined($ENV{'DAEMON'}) ) {
  $main::daemonize = 'true'  if ( $ENV{'DAEMON'} =~ /true/io );
  $main::daemonize = 'false' if ( $ENV{'DAEMON'} =~ /false/io );
}

if ( $main::daemonize eq 'true' ) {
  my($pid) = 0;
  $pid=fork();
  if ( $pid == 0 ) {
    &Daemonize;
  } elsif ( $pid > 0 ) {
    exit 0;
  } else {
    print STDERR "ERR: Cannot fork to go into the background...exiting..\n";
    exit 1;
  }
} else {
  my $oldsel = select(STDOUT); $| = 1; select($oldsel);
}
umask(022);

if ( $main::pidfile ne "" ) {
  if ( open(F,"> $main::pidfile") ) {
    print F "$$\n";
    close(F);
  }
}

while ( 1 ) {
  undef(%main::array);
  %main::array = ();
  &GetUptime;
  &GetMemInfo;
  &GetStorage;
  &GetLoadAvg;
  &GetOnlineStatus;
  &GetTimestamp;
  if ( $main::outfile ne "" ) {
    open(OUT, "> $main::outfile");
  } else {
    open(OUT, ">&STDOUT");
  }
  print OUT &mk_json;
  close(OUT);

  last if ( ! $main::sleep_secs );
  sleep($main::sleep_secs);
}

&cleanup;