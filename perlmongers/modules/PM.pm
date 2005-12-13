use strict;
use warnings;

package PM;

use Class::DBI::Loader;

my @missing;
foreach (qw(PM_USER PM_PASS)) {
  push @missing, $_ unless defined $ENV{$_};
}

if (@missing) {
  die 'You must set the ' . join(' and ', @missing) .
    " enviroment variables.\n";
}

my $db  = $ENV{PM_DB} || 'pm_census';
my $dsn = "dbi:mysql:database=$db";
$dsn .= ";host=$ENV{PM_HOST}" if $ENV{PM_HOST};

my $loader = Class::DBI::Loader->new( dsn       => $dsn,
                                      user      => $ENV{PM_USER},
                                      password  => $ENV{PM_PASS},
                                      namespace => 'PM' );

package PM::PmGroup;

my @freq = ('Unknown',
            'More than once a month',
            'Once a month',
            'Every two months',
            'Less often',
            'Scheduled randomly');

sub status {
  my $self = shift;

  if ($self->dead eq 'Y') {
    return 'inactive';
  } elsif ($self->checked_in eq 'Y') {
    return 'active';
  } else {
    return 'missing';
  }
}

sub freq_txt {
  my $self = shift;
  my $what = shift;

  $what = "${what}_freq";

  my $index = $self->$what;
  $index =~ s/\D//g;
  $index = 0 unless length $index;

  return $freq[$index];
}
