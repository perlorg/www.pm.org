use 5.18.0;
use Email::Stuffer;
use XML::Twig;

my $xml = 'perl_mongers.xml';
my $name = 'Omaha.pm';

my ($url, $email) = update_xml($name);
send_email($name, $url, $email);

exit;

# END MAIN


sub update_xml {
   my ($name) = @_;
   my $twig = XML::Twig->new(
      pretty_print => 'indented',
      # output_text_filter => 'html',
      twig_handlers => {
         group => sub { 
            if ($_->first_child('name')->text eq "Omaha.pm") {
               $_->{att}->{status} = 'inactive';
            }
         },
      }
   );
   $twig->parsefile($xml);
   open my $new, '>:utf8', 'new.xml' or die;
   print $new $twig->sprint;
   close $new;
   rename('new.xml', $xml);
}


sub send_email {
   my ($group, $homepage, $leader_email) = @_;

   $leader_email = 'jay@jays.net';  # temporary

   my $body = <<EOT;
<p>
$group leader,
</p><p>
It appears that your Perl Mongers group configuration is broken, 
badly out of date, or has been overrun with spam: 
</p><p>
   $homepage
</p><p>
Your group has been deactivated. 
</p><p>
When you have resolved the problem(s), please reply to this email 
informing us of your resolutions so that we can re-activate you.
</p><p>
Thank you for your attention!
</p><p>
pm.org support staff<br/>
support\@pm.org
</p>
EOT
 
   # Create and send the email in one shot
   Email::Stuffer
      ->from     ('support@pm.org')
      ->to       ($leader_email)
      ->bcc      ('jay@jays.net')
      ->subject  ("$group deactivated")
      ->html_body($body)
      ->send;
}



