#!/usr/bin/perl

use Fcntl qw(:flock);

$usage = "./makeNewWeb.pl groupname ...\n";

die $usage if (! scalar @ARGV);

foreach my $user (@ARGV)
	{
	print "Adding user: $user.  domain name[$user]> ";
	chomp( $domain = <STDIN> );
	$domain = $user unless $domain ne '';

	print "group leader Full Name: ";
	chomp( $fullname = <STDIN> );
	($fullname =~ /^[-a-zρφισϊγ'A-Z_. ]+$/) || die;

	print "group leader email address: ";
	chomp( $email = <STDIN> );
	($email =~ /^[-a-zA-Z0-9_+.]+@[-a-zA-Z0-9_.]+$/) || die;

	print "Temporary password crypt string: ";
	chomp( $crypt = <STDIN> );
	($crypt =~ /^.............$/) || die;

	$domain =~ /^(.{1,8})/;
	$user = $1;

print STDERR "user: <$user>\n";
print STDERR "domain: <$domain>\n";
	
	#next if defined scalar getpwnam($user);
	die "username exists" if defined scalar getpwnam($user);

	push @domains, $domain;
	
	print "/usr/sbin/useradd -d \"/home/groupleaders/$user\" -m -c '$fullname,$email' -p $crypt -s /bin/bash $user\n";
	system "/usr/sbin/useradd -d \"/home/groupleaders/$user\" -m -c '$fullname,$email' -p $crypt -s /bin/bash $user";

	mkdir "/opt/apache/gocho.pm.org/80/htdocs/pm.org/$domain", 02770;
	
	chown( (getpwnam($user))[2], 503, "/opt/apache/gocho.pm.org/80/htdocs/pm.org/$domain");
	`ln -s /opt/apache/gocho.pm.org/80/htdocs/pm.org/$domain /home/groupleaders/$user/web_docs`;

	append_to_file("/etc/mail/local-host-names", "$domain.pm.org");

	open FILE, ">> /etc/httpd/pm.org.vhosts3";
	flock FILE, LOCK_EX;
	seek FILE, 0, 2;
	print FILE "$domain:$user:www_logs/:combined:0:0:0::\n";
	close FILE;

	open FILE, ">> /etc/httpd/pm.org.vhosts4";
	flock FILE, LOCK_EX;
	seek FILE, 0, 2;
	print FILE "$domain:$user:\n";
	close FILE;

	open FILE, ">> /opt/apache/gocho.pm.org/80/conf/vhosts.pm.org";
	flock FILE, LOCK_EX;
	seek FILE, 0, 2;
	print FILE "$domain\n";
	close FILE;

	
	if( defined $email )
		{
		open FILE, ">> /etc/mail/virtusertable";
		flock FILE, LOCK_EX;
		seek FILE, 0, 2;
		print FILE "\@$domain.pm.org\t$email\n";
		close FILE;
		
		open FILE, ">> /etc/mail/sendmail.cw";
		flock FILE, LOCK_EX;
		seek FILE, 0, 2;
		print FILE "$domain.pm.org\n";
		close FILE;
		
		send_faq($email, $user, "$domain.pm.org");
		}
	}


system( "cd /etc/mail; make " );
system( "cd /opt/apache/gocho.pm.org/80; kill `cat logs/httpd.pid`; sleep 3; bin/httpd -d `pwd`" );
print "just before mail to ben\n";
open MAIL, "| /usr/lib/sendmail -odq -oi -t" or die "$!";
die "$?" if $?;

print MAIL <<"HERE";
To: dns\@pm.org,hfb_admin\@pm.org
From: hfb_admin\@pm.org
Subject: new subdomain request

Please add these domains with A 64.49.222.22

@{[join "\tIN\tA\t64.49.222.22\n", @domains, '']}
@{[join "\tIN\tMX\t10\tmail.pm.org.\n", @domains, '']}

this has been an automagically generated message.  if this 
were a real social interaction you would have been notified.
	
HERE

sub send_faq
	{
	my $email = shift;
	my $user  = shift;
	
	open MAIL, "| /usr/lib/sendmail -odq -oi -t";
	print MAIL <<"HERE";
To: $email
From: tech\@pm.org
Bcc: tech\@pm.org
Subject: Perl Monger user group site configured

Your Perl Monger user group site has been configured:

 * Use an ssh ("secure shell") program to log on to
   www.pm.org as "$user" with the password that you
   provided.  You must use ssh to login and edit or
   transfer files (telnet and ftp are not allowed).
   For more information on ssh visit www.openssh.org

 * Your website files are stored at:
     /opt/apache/gocho.pm.org/80/htdocs/pm.org/$domain

 * There is a softlink to this path in your home directory
   called web_docs (cd ~/web_docs).
	
 * Until the nameserver updates itself with your domain
   name $domain.pm.org, you can add this to your client
   machine's host file (/etc/hosts on *nix and 
   c:\windows\system32\etc\hosts on Windows) by adding
   the line: 
	64.49.222.22 $domain.pm.org

 * All mail to \@$domain.pm.org will be automagically
   forwarded to: $email

That's it for now.  Good luck :)

--
The pm.org Admin Team <tech\@pm.org>
HERE

	close MAIL;
	}
	
sub append_to_file
{
	my ($filename, $line) = @_;
	open (FILENAME, ">>$filename") || die;
	chomp $line;
	print FILENAME "$line\n";
	close FILENAME;
}
