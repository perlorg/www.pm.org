#!/usr/bin/perl
use strict;
use warnings;

# collect statistics from the publicly available archives
# of the mailing lists
# TODO:
# 1) Has public archive?
# 2) Has any messages been saved?
# 3) How many messages in the last 12 months?
# 4) How many authors and what is the distribution of messages?

use Data::Dumper qw(Dumper);
use List::Util   qw(max);
use WWW::Mechanize;

# last 6 months (should be parameterized)
my $months = 6;

my $root_url = 'http://mail.pm.org/mailman/listinfo/';

my $command = shift;

die "Usage: $0 list | report valladolid-pm | all | all 5\n"
    if not $command or $command !~ /^(list|report|all)$/;

use DateTime;
my $now = DateTime->now;

my $w = WWW::Mechanize->new;

if ($command eq 'list' or $command eq 'all') {
    my $limit = shift;
    $w->get( $root_url );
    foreach my $link ( $w->links ) {
        if ( $link->url_abs =~ m{/listinfo/([^/]+-pm)$}i ) {
           #print $link->url_abs, "\n";
           if ($command eq 'all') {
               report($1);
               if (defined $limit) {
                   $limit--;
                   last if $limit <= 0;
               }
               sleep 3; # slowly cowboy!
           } else {
               print "$1\n";
           }
        }
    }
}


if ($command eq 'report') {
    my $group = shift or die "No group given\n";
    report($group);
}

exit;


sub report {
    my $group = shift;
    warn "Working on $group\n";
    print "Report for $group\n";
    my $url = "http://mail.pm.org/pipermail/$group/";
    eval { $w->get( $url ) };
    my $err = $@;
    if ($w->status eq '404') {
        print "$group is 404\n";
        return;
    }
    if ($err) {
        die $err;
    }

    my %count;
    foreach my $m (1..$months) {
        my $month = $now->clone->subtract( DateTime::Duration->new( months => $m ));
        my $file = $month->year . '-' . $month->month_name . '.txt';
        #print "Search $file\n";
        my $link = $w->find_link(url_regex => qr/^$file(.gz)?$/);
        next if not $link;

        if ($link->url =~ /.gz$/) {
            warn "for now  skip gz files " . $link->url . "\n";
            next;
        }
        #print "Fetching " . $link->url_abs . "\n";
        my $wm = WWW::Mechanize->new;
        $wm->get( $link->url_abs );
        # TODO processing mbox file!
        # w is used in warszawa-pm
        my @result = $wm->content =~ m{^From: (\S+ (?:at|w) \S+)}mg;
        #print Dumper \@result;
        foreach my $email (@result) {
            $count{$email}++;

        }
    }
    my $total = 0;
    my $ppl = 0;
    my $top = 0;;
    for my $mail (reverse sort { $count{$a} <=> $count{$b} } keys %count) {
        $total += $count{$mail};
        $ppl++;
#        printf("%-40s %s\n", $mail, $count{$mail});
        $top = max($top, $count{$mail});
    }
    print "Total:  $total\n";
    print "People: $ppl\n";
    print "Top:    $top\n";
    #print $w->content;
    # links that have YYYY-Month.txt or  YYYY-Month-txt.gz
}

