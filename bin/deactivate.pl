#! env perl

use 5.18.0;
use Email::Stuffer;
use XML::Twig;

my $xml = 'perl_mongers.xml';
my $name = $ARGV[0] || usage();

my ($elt) = update_xml($name);
send_email($elt);
say "Deactivated in XML. Email sent.";

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
            if ($_->first_child('name')->text eq $name) {
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


sub send_email {
   my ($elt) = @_;

   my $group_name = $elt->first_child('name')->text;
   my $tsar =       $elt->first_child('tsar')->first_child('name')->text;
   my $e =          $elt->first_child('tsar')->first_child('email');
   my $tsar_email = 
      $e->first_child('user')->text . '@' . 
      $e->first_child('domain')->text;
   my $web =        $elt->first_child('web')->text;

   my $body = <<EOT;
<p>
$tsar,
</p><p>
It appears that your Perl Mongers group configuration is broken, 
badly out of date, or has been overrun with spam: 
</p><p>
   $web
</p><p>
Your group has been deactivated. 
</p><p>
When you have resolved the problem(s), please reply to this email 
informing us of your resolutions so that we can re-activate you.
</p><p>
If we have made a mistake, we apologize. Please reply so we know something
has gone wrong on our side.
</p><p>
Thank you for your attention!
</p><p>
For support, please open an issue in github:
  https://github.com/perlorg/www.pm.org/issues<br/>
Or send us an email:<br/>
pm.org support staff &lt;support\@pm.org&gt;<br/>
Group hosting FAQ: http://www.pm.org/faq/hosting.html
</p>
EOT

   # Create and send the email in one shot
   say "Sending to $tsar_email";
   Email::Stuffer
      ->from     ('support@pm.org')
      ->to       ($tsar_email)
      ->cc       ('jay@jays.net')
      ->subject  ("$group_name deactivated")
      ->html_body($body)
      ->send || die $!;
}



