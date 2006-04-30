
##
## -*- Mode: CPerl -*-
##

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME         => "PerlMongers",
	      VERSION      => "1.0",
	      PREREQ_PM    => {
			       'Pipeline'          => '2.00',
			       'OpenFrame'         => '0.01',
			       'OpenFrame::AppKit' => '0.01',
			       'Template'          => '2.08',
			      },
	     );

