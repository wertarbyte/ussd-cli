#!/usr/bin/perl
# USSD command line interface
# for Huawei GSM modems
# by Stefan Tomanek <stefan@pico.ruhr.de>

use strict;
use Getopt::Long;
use Device::Gsm::Pdu;

my $dev;
my $verbose = 0;
my $interactive = 0;
my $help = 0;

my $USAGE = <<EOF;

Usage: $0 [--device <device>] [-v] [-i] [ussd_msg]...

Description:
  Send and receive 7-bit PDU-encoded USSD messages.
  Written and tested for Huawei E173 GSM/UMTS USB modem.

Options:
  --device  <dev>    Device to send AT commands to
  --verbose          Be verbose.
  --interactive      Interactive mode
EOF


my $res = GetOptions(
	"device=s"     => \$dev,
	"verbose+"     => \$verbose,
	"interactive"  => \$interactive,
	"help"         => \$help,
);

print $USAGE and exit if (!$interactive && !@ARGV) or $help;

open (MODEM, "+>", $dev) || die "Can't open '$dev': $!\n";

while (@ARGV || $interactive) {
	my $cmd = shift @ARGV;
	if (!defined $cmd && $interactive) {
		print "> ";
		$cmd = <STDIN>;
		chomp($cmd);
	}
	print "USSD MSG: $cmd\n" if $verbose;
	my $ussd_req = substr( Device::Gsm::Pdu::encode_text7($cmd), 2 );
	print "PDU ENCODED: $ussd_req\n" if $verbose;

	my $str = "AT+CUSD=1,$ussd_req,15";
	print "$str\n" if $verbose;
	print MODEM "$str\r\n";
	print "Waiting for USSD reply...\n" if $verbose;
	my $ussd_reply;
	while (<MODEM>) {
		chomp;
		print "received from modem: $_\n" if $verbose > 1;
		if (/^\+CUSD: /) {
			if (/^\+CUSD: [01],\"([A-F0-9]+)\"/) {
				my $msg = Device::Gsm::Pdu::pdu_to_latin1($1);
				print STDOUT "USSD REPLY: $msg\n\n";
			} else {
				print "Received strange message: $_\n";
			}
			last;
		}
	}
}
