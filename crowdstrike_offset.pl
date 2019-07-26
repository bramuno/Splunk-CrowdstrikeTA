#!/usr/bin/perl --
use lib "/usr/local/nagios/libexec"; # required
use Getopt::Long; # required for check_options subroutine
$help	= undef;
$debug = "no";
$host="dev.splunk.com";
$username="user";
$password = "pass";
$searchHost = "myHostName";
$SPL="earliest=-24h index=_internal sourcetype=ta-crowdstrike_ucc_lib-2 host=$searchHost consuming | stats max(placeholder)";
$file="/opt/splunk/etc/deployment-apps/TA-crowdstrike/local/crowdstrike_falcon_host_inputs.conf";
$cmd="curl -s -u $username:'$password' https://$host:8089/services/search/jobs -d search=\"search $SPL\"";$result=`$cmd`;
##############
@tmp = split("\n",$result);
$tmp[2] =~ s/<sid>//g;
$tmp[2] =~ s/<\/sid>//g;
$tmp[2] =~ s/\s+//g;
$SID = $tmp[2];
sleep(5);
$cmd="curl -s -u $username:'$password' https://$host:8089/services/search/jobs/$SID/results";
$result=`$cmd`;
@tmp = split("\n",$result);
for($a=0;$a<@tmp;$a++){
	if($tmp[$a] =~ /offset/ ){ $pos = $a+2;}
}
$tmp[$pos] =~ s/^.*<text>//g;
$tmp[$pos] =~ s/<\/text.*//g;
$offset = $tmp[$pos];
if($offset =~ /^[0-9]+$/)
{
	# open file
	open(CONFIGFILE, "< $file");
	my @configfile_raw = <CONFIGFILE>;
	close (CONFIGFILE);
	if($debug eq "yes"){
		for($a=0;$a<@configfile_raw;$a++){
			print "configfile_raw[$a] = $configfile_raw[$a]";
		}
	}
	$dataOut = "";
	# re-create file
	for($a=0;$a<@configfile_raw;$a++){
		if($configfile_raw[$a] =~ /start_offset/ ){ $dataOut .= "start_offset = $offset\n"; }
		else{$dataOut .= "$configfile_raw[$a]";}
	}
	if($debug eq "yes"){
		print "dataOut = \"\n$dataOut\n\"\n";
	}
	# write file
	open(MYFILE, ">$file") or die $!;
	print MYFILE "$dataOut"; 
	close (MYFILE);
}
else{
	print "unable to update offset, value is not numerical.\n offset=$offset\n";
}
