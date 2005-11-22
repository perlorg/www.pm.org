use strict;
use warnings;

package PM;

use Class::DBI::Loader;

my $loader = Class::DBI::Loader->new( dsn       => 'dbi:mysql:pm_census',
                                      user      => 'pm_census',
                                      password  => 'pm_c3n5u5',
                                      namespace => 'PM' );

