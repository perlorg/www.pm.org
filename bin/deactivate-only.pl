#!/usr/bin/env perl

use 5.18.0;
use XML::Twig;

my $xml = 'perl_mongers.xml';
my $name = $ARGV[0] || usage();

$name = $name . ".pm" unless $name =~ /\.pm$/i;

my ($elt) = update_xml($name);
say "Deactivated ${name} in XML.";

exit;

# ------------
# END MAIN
# ------------

sub usage {
   print <<EOT;

$0 Omaha.pm

EOT
   exit;
}


sub update_xml {
   my ($name) = @_;
   my $found_it = 0;
   my $elt;
   my $twig = XML::Twig->new(
      pretty_print => 'indented',
      # output_text_filter => 'html',
      twig_handlers => {
         group => sub { 
            if (lc $_->first_child('name')->text eq lc $name) {
               $_->{att}->{status} = 'inactive';
               $found_it++;
               $elt = $_;
            }
         },
      },
   );
   $twig->parsefile($xml);
   unless ($found_it) {
      die "Didn't find group '$name'";
   }
   open my $new, '>:utf8', 'new.xml' or die;
   print $new $twig->sprint;
   close $new;
   rename('new.xml', $xml);
   return $elt;
}
