#!/usr/bin/perl

use XML::Parser;
use XML::Parser::Grove;
use XML::Grove;

my $xml_file = 'perl_mongers.xml';

$parser = XML::Parser->new(Style => 'grove');
$grove = $parser->parsefile($xml_file);

$root = $grove->root;

%groups = map { $_->attributes->{'id'}, $_->contents }  
          grep ref $_, @{$root->contents};


foreach my $g ( keys %groups )
	{
	my %elements = map { $_->name, $_->contents }
		grep ref $_, @{$groups{$g}};
	
# 	print "$groups{$g}[4]\n";
# 	my $name = $groups{$g}->[4]->contents->[0];
	
	my $name = $elements{name}[0];
	my $web  = $elements{web}[0];
	
	if( defined $web )
		{
		$link = qq|<b><a href="$web">$name</a></b>|;
		}
	else
		{
		$link = qq|<b>$name</b>|;
		}
	
	print "$link\n";
	
# 	print "-----$elements{name}[0]------\n";
# 	local $" = "]\n\t[";
# 	print "\t[@{[map { ref $_ ? ($_->name) : ();} @{$groups{$g}}]}]\n";	
	}




# foreach my $element ( @$contents )
# 	{
# 	next unless ref $element;
# 	my $name = $element->name;
# 	my $id   = ${$element->attributes}{'id'};
# 	
# 	print "Found $name, id => $id\n";
# 	$group{$id} = $element->contents;
# 	}


# $" = "\n";
# 
# foreach ( keys %$root )
# 	{
# 	print "$_: $$root{$_}\n";	
# 	
# 	if ( ref $$root{$_} eq 'ARRAY')
# 		{
# 		local $" = "]\n\t[";
# 		print "\t[@{[map { s/\n|\r/RET/g; s/\t/TAB/g; $_} @{$$root{$_}}]}]\n";
# 		}
# 	elsif ( ref $$root{$_} eq 'HASH')
# 		{
# 		local $" = "\t\n";
# 		print "\t@{[keys %{$$root{$_}}]}\n";
# 		}
# 		
# 	}
	
#print "@{[ keys %$root]}\n";
