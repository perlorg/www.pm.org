#!/usr/bin/perl

use URI::Escape qw(uri_escape);
use XML::DOM;
use IO::Tee;

$NO_STATE = 0;

my $PM_DOCS   = "/opt/apache/gocho.pm.org/80/htdocs/pm.org/www";
my $xml_base  = "$PM_DOCS/XML";
my $html_base = "$PM_DOCS/groups";

my $parser = new XML::DOM::Parser;

my $file = $parser->parsefile("$xml_base/perl_mongers.xml");

my $groups = $file->getElementsByTagName("group");

foreach my $g ( @$groups )
	{
	my $location  = eval { $g->getElementsByTagName("location")->item(0)};

	#state can be empty, in which case this will be fatal
	my $state     = eval { $location->getElementsByTagName("state")->[0]->getFirstChild->getData };
	my $country   = eval { $location->getElementsByTagName("country")->[0]->getFirstChild->getData};
	my $continent = eval { $location->getElementsByTagName("continent")->[0]->getFirstChild->getData};
	
	#only the US, Canada, Australia have states/provinces, so we'll have a placeholder
	#state for other countries
	$state = $NO_STATE unless $state;

	$hash{$continent}{$country}{$state} = [] unless defined $hash{$continent}{$country}{$state};
	push @{$hash{$continent}{$country}{$state}}, $g;
	}

open ENTIRE, "> $html_base/groups.data.html" or warn "Could not open $html_base/groups.data.html\n$!";

print ENTIRE qq|<table width=600 cellpadding=5>\n|;

foreach my $continent ( sort keys %hash )
	{
	my $file = lc $continent;
	$file =~ s/\s+/_/g;
	
	open FILE, "> $html_base/$file.data.html" or warn "Could not open $html_base/$file.data.html\n$!";
	print FILE qq|<table width=600 cellpadding=5>\n|;

	my $tee = IO::Tee->new(\*ENTIRE, \*FILE); 
	
	my $esc = uri_escape($continent);
	print $tee qq|<tr><td bgcolor="#0088AA"><b><font size="+2"><a name="$esc">$continent</a></font></b></td></tr>\n|;
	
	foreach my $country ( sort keys %{$hash{$continent}} )
		{
		my $esc = uri_escape($country);
		print $tee qq|\t<tr><td bgcolor="#aaaaaa"><b><font size="+1"><a name="$esc">$country</a></font></b></td></tr>\n|;
		
		foreach my $state ( sort keys %{$hash{$continent}{$country}} )
			{
			my $esc = uri_escape($state);
			print $tee qq|\t\t<tr><td bgcolor="#cccccc"><b><a name="$esc">$state</a></b></td></tr>\n| unless $state eq $NO_STATE;
			print $tee qq|\t\t\t<tr><td><dl>\n|;
			
			foreach my $g ( @{$hash{$continent}{$country}{$state}} )
				{
				my $id       = eval { $g->getAttributes->getNamedItem("id")->getValue}; 
				
				my $name     = eval { $g->getElementsByTagName("name")->[0]->getFirstChild->getData};
				
				my $location = eval { $g->getElementsByTagName("location")->item(0)};
				my $city     = eval { $location->getElementsByTagName("city")->[0]->getFirstChild->getData};
				my $region   = eval { $location->getElementsByTagName("region")->[0]->getFirstChild->getData};
				my $web      = eval { $g->getElementsByTagName("web")->[0]->getFirstChild->getData };
				
				
				if( $web )
					{
					print $tee qq|\t\t\t<dt><b><a href="$web">$name</a></b>|;
					}
				else
					{
					print $tee qq|\t\t\t<dt><b>$name</b>|;
					}
					
				if( $city and $region )
					{
					$city = "$city, $region";
					}
				else
					{
					$city = "$city$region";
					}
					
				print $tee qq| <i>($city)</i>| if $city;
				
				print $tee "\n";
				
				my $tsar      = eval { $g->getElementsByTagName("tsar")->item(0)};
				my $tsar_name = eval { $tsar->getElementsByTagName("name")->[0]->getFirstChild->getData};
				my $tsar_addr = eval { $tsar->getElementsByTagName("email")->[0]->getFirstChild->getData};
				
				print $tee qq|\t\t\t<dd>$tsar_name <a href="mailto:$tsar_addr">$tsar_addr</a><br><br>\n|;
				
				}

			
			print $tee qq|\t\t\t</dl></td></tr>\n\n|;
			
			}	
		
		}
		
	undef $tee;
	print FILE qq|</table>\n|;
	close FILE;
	}

print ENTIRE qq|</table>\n|;
