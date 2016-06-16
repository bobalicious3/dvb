#!/usr/bin/perl

# usage: $0 [XXX] where XXX is channel name
# e.g. $0 ITV
# needs quotes for channels with odd chars/space ... 
# e.g. $0 "ITV2 +1"
#
# can use dvblast or c'vlc': cvlc advertises SAP, dvblast will give dvb subtitles etc

# dvbv5-scan -C GB dtv-scan-tables/dvb-t/uk-CrystalPalace (to get the dvb_channel.conf)
# # w_scan -c GB (better at getting HD - takes more time)
my $dvb_chans = "dvb_channel.conf";
my $dvb_cfg = "/tmp/dvb.cfg";


my $wanted = undef;
if($#ARGV eq 0) {
  $wanted = @ARGV[0];
}

my $chans = {};
open FILE, $dvb_chans or die "Cant open $dvb_chans:$!";
my $chan;
while(<FILE>) {
	chomp;
	if(/\[(.*)\]/){
		$chan = $1;
		$chans->{$chan} = {};
	} else {
		if(/(\w+) = (.*$)/) {
			my $prop = $1;
			my $val = $2;
			if($prop eq "MODULATION") {
				my ($junk,$rate) = split('/',$val);
				$val = "qam_$rate";
			}
			$chans->{$chan}->{$prop} = $val;
		}
	}
}
close FILE;

if($wanted and exists $chans->{$wanted}) {
	my $channel_id = $chans->{$wanted}->{SERVICE_ID};
	my $freq = $chans->{$wanted}->{FREQUENCY};
	my $qam = $chans->{$wanted}->{MODULATION};
	my $delivery = $chans->{$wanted}->{DELIVERY_SYSTEM};
	open FILE, ">$dvb_cfg" or die "Cant open $dvb_cfg:$!";
	print FILE "239.255.0.54:5004 1 $channel_id","\n";
	close FILE;

	my $dvb_exec = qq{dvblast -e -f $freq -m $qam -b 8 -c $dvb_cfg -5 $delivery};
	my $vlc_exec = qq[cvlc dvb-t2:// :no-sout-all :program=$channel_id :dvb-frequency=$freq :dvb-bandwidth=8 --sout '#rtp{mux=ts,dst=239.255.0.54,sdp=sap,name="$wanted"}'];
	print $dvb_exec,"\n";
	print $vlc_exec,"\n";
	system($vlc_exec);
} else {
	foreach my $chan (sort keys %$chans) {
		if($wanted) {
			if($chan =~ /$wanted/) {
				print "$chan\n";
			}
		} else {
			print "$chan\n";
		}
	}
}
