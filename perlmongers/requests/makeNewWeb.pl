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
	($fullname =~ /^[-a-zA-Z_. ]+$/) || die;

	print "group leader email address: ";
	chomp( $email = <STDIN> );
	($email =~ /^[-a-zA-Z0-9_.]+@[-a-zA-Z0-9_.]+$/) || die;

	$domain =~ /^(.{1,8})/;
	$user = $1;

print STDERR "user: <$user>\n";
print STDERR "domain: <$domain>\n";
	
	#next if defined scalar getpwnam($user);
	die "username exists" if defined scalar getpwnam($user);

	push @domains, $domain;
	
	print "/usr/sbin/useradd -m -c '$fullname,$email' -s /bin/bash $user";
	system "/usr/sbin/useradd -m -c '$fullname,$email' -s /bin/bash $user";

	mkdir "/export/home/$user/www_docs", 0755;
	mkdir "/export/home/$user/www_logs", 0755;
	
	chown( (getpwnam($user))[2,3], glob("/export/home/$user/www_*"));

	open FILE, ">> /etc/httpd/pm.org.vhosts";
	flock FILE, LOCK_EX;
	seek FILE, 0, 2;
	print FILE "$domain:$user:www_logs/:combined:0:0:0::\n";
	close FILE;

	open FILE, ">> /etc/httpd/pm.org.vhosts2";
	flock FILE, LOCK_EX;
	seek FILE, 0, 2;
	print FILE "$domain:$user:\n";
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


system( "cd /etc/mail; /usr/ccs/bin/make > /dev/null" );
print "just before mail to ben\n";
open MAIL, "| /usr/lib/sendmail -odq -oi -t" or die "$!";
die "$?" if $?;

print MAIL <<"HERE";
To: dns\@pm.org,hfb_admin\@pm.org
From: hfb_admin\@pm.org
Subject: new subdomain request

Please add these domains with A 166.84.5.165

@{[join "\tIN\tA\t166.84.5.165\n", @domains, '']}
	

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
Bcc: wwalker\@bybent.com
Subject: Perl Mongers services configured!

Your Perl Monger net services have been configured.

* log on to happyfunball.pm.org as "$user" with the password that
you provided.  You must use ssh v.1 (or v.2 now :).  telnet is not allowed.

* in your home directory, there are two directories for your web
things:

	www_docs - put your public web stuff in here
	www_logs - here are your log files
	
* until the nameserver updates itself with your domain name
$domain.pm.org, you can access your web stuff as a normal user:

	http://hfb.pm.org/~$user/
	
* all mail to \@$domain.pm.org will be automagically forwarded to
$email.

that's it for now.  good luck :)

--
Wayne Walker - <wwalker\@bybent.com>
HERE

	close MAIL;
	}
	
