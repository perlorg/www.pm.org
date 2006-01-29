#!/usr/bin/perl

# Read perl_mongers.xml and generate map.xml, which is much smaller and simpler.
# Where should this script live?
# -jhannah Jan 29, 2006

use XML::Twig;

open (OUT, ">map.xml");
my $twig=XML::Twig->new( 
           twig_handlers =>
             { group   => \&group }
);

print OUT <<EOT;
<?xml version="1.0" encoding="ISO-8859-1"?><markers>
EOT

$twig->parsefile( '../../perl_mongers.xml'); 

print OUT <<EOT;
</markers>
EOT

close OUT;


sub group {
  my ($twig, $group) = @_;

  my $id =       $group->{'att'}->{'id'};
  my $status =   $group->{'att'}->{'status'};
  my $name =     $group->first_child('name');
  my $web =      $group->first_child('web');
  my $location = $group->first_child('location') || return undef;
  my $lat      = $location->first_child('latitude');
  my $long     = $location->first_child('longitude');
  $name = $name->text if $name;
  $lat = $lat->text if $lat;
  $long = $long->text if $long;
  $web = $web->text if $web;

  next unless ($status eq "active" and $lat and $long);
  #print "$id $name $web $lat $long\n";
  print OUT <<EOT
<marker lat="$lat"
        lng="$long"
        name="$name"
        web="$web"
/>
EOT

}

