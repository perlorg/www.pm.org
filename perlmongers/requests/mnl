#!/usr/bin/perl
use strict;

use vars qw($owner $group);
use subs qw(create_file);

use Fcntl qw(:flock);

$ENV{'PATH'} = "$ENV{'PATH'}:/usr/local/bin";

die <<"HERE" unless ( defined $ARGV[0] and defined $ARGV[1] );
USE:

	make_list.pl list_name owner_email
	
HERE

my ($owner, $group) = (getpwnam 'mjordomo')[2,3];

my $list    = $ARGV[0];
my $email   = $ARGV[1];
my $dir     = '/usr/local/majordomo';
my $listdir = "$dir/lists";
my $wrapper = "$dir/wrapper";
my $aliases = '/etc/mail/majordomo.aliases';
my $archive = "$dir/archives";
my $digest  = "$dir/digests";

# 1) Create list file
die "Could not create list file ($?)" 
	unless create_file("$listdir/$list") >= 0;

die "Could not create list digest file ($?)" 
	unless create_file("$listdir/$list-digest") >= 0;

mkdir "$listdir/$list-digest.archive", 0775;
chown $owner, $group, "$listdir/$list-digest.archive";

# 2) Create list info file
warn "Could not create list info file" 
	unless create_file("$listdir/$list.info") >= 0;

# 3) Create mail aliases
open  FILE, ">> $aliases" 
	or die "Could not open alias file [$aliases] for append\n$!\n";
flock FILE, LOCK_EX;
seek  FILE, 0, 2;

print FILE <<"HERE";
########################
# $list @{[scalar localtime]}
########################
$list: "| $wrapper resend -l $list $list-outgoing"
$list-digest: $list
$list-outgoing: :include:$listdir/$list,"| $wrapper digest -r -C -l $list-digest $list-digest-outgoing","| $wrapper archive2.pl -a -m -f $archive/$list/$list.archive"
$list-digest-outgoing: :include: $listdir/$list-digest
owner-$list: $email
owner-$list-outgoing: owner-$list
owner-$list-digest: owner-$list
owner-$list-digest-outgoing: owner-$list-digest

$list-request: "| $wrapper request-answer $list"
$list-digest-request: "| $wrapper request-answer $list-digest"

$list-approval: $email
$list-digest-approval: $list-approval


HERE

close FILE;

system("cd /etc/mail; make > /dev/null");

# 4) Create archive directory

mkdir "$archive/$list", 0775;
chown $owner, $group, "$archive/$list";

# 5) Create digest directory

mkdir "$digest/$list-digest", 0775;
chown $owner, $group, "$digest/$list-digest";

# 6) Check ownership

# 7) Issue config
open MAIL, "| /usr/lib/sendmail -odq -oi -t";
print MAIL <<"HERE";
To: majordomo\@hfb.pm.org
From: majordomo-owner\@hfb.pm.org
Subject: config $list

config $list $list.admin
HERE

# send email to list owner
close MAIL;

open MAIL, "| /usr/lib/sendmail -odq -oi -t";

print MAIL <<"MAIL";
To: $email
From: majordomo-owner\@pm.org
Subject: Perl Monger mailing list configured
Cc: majordomo-owner\@pm.org

Your list is configured:

	it's name is:     $list
	your password is: $list.admin  (change right away!)
	
	the posting address is: $list\@hfb.pm.org
	
	list requests should be sent to: majordomo\@hfb.pm.org
	
You can configure you list through the normal majordomo email
interface or you can use Majorcool at:

	<URL:http://hfb.pm.org/cgi-bin/majordomo?module=modify>

If you are new to this whole Majordomo thing, here's some good info:

        <URL:http://eleccomm.ieee.org/demo1/ownerdoc.html>
        <URL:http://www.greatcircle.com/majordomo/>
	
If you have any problems, please send email to majordomo-owner\@hfb.pm.org.

Thanks!
MAIL

close MAIL;


sub create_file
	{
	my $file = shift;
	
	return -1 if -e $file;
	
	open FILE, "> $file" or return -2;
	close FILE;
	
	chmod 0664, $file;
	chown $owner, $group, $file;
	}
	
