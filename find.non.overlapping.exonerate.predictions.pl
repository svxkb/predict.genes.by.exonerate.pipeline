#!/usr/bin/perl 
use warnings;
use strict;

use Getopt::Long;


# Richard Emes University of Nottingham 2010
my $usage = "
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
(C) R D Emes University of Nottingham 2010

parse exonerate

USAGE:
-f	parsed exonerate file (from exonerate.parse.pl)
-o	output file
-c	chromosome name to add to prediction name
-p	prefix of gene predictions
-m	minimum length of overlap amino acids
-i	max number of introns
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
" ;


my ($file, $output, $chr, $prefix, $min_length,$max_introns);

GetOptions(
        'f|fasta:s'     => \$file,
        'o|output:s'     => \$output,	
	'c|chr:s'     => \$chr,
        'p|prefix:s'     => \$prefix,	
	'm|min:s'     => \$min_length,
        'i|introns:s'     => \$max_introns,		
	
         );


if( ! defined $file) {
print "$usage\nWARNING: Cannot proceed without parsed file to process\n\n"; exit;
}
if( ! defined $output) {
print "$usage\nWARNING: Cannot proceed without output file\n\n"; exit;
}
if( ! defined $chr) {
print "$usage\nWARNING: Cannot proceed without chr name\n\n"; exit;
}
if( ! defined $prefix) {
print "$usage\nWARNING: Cannot proceed without prefix name\n\n"; exit;
}
if( ! defined $min_length) {
print "$usage\nWARNING: Cannot proceed without minimum overlap\n\n"; exit;
}
if( ! defined $max_introns) {
print "$usage\nWARNING: Cannot proceed without maximum nuber of introns\n\n"; exit;
}




####################################################
open FILEIN, "<$file";
my $header  = <FILEIN>;
chomp $header;
open OUT, ">$output";
print OUT "Name\tChr\t$header\n";
open OUTTMP, ">hold1.tmp";
while (<FILEIN>)
{
chomp $_;
print OUTTMP "$_\n";
}
close OUTTMP;
close FILEIN;

system "sort -n -k6 hold1.tmp > ./hold.tmp"; ## sort numerically on the start position of prediction

open TEST, "<hold.tmp";
my @lines = <TEST>; ###
my $number_of_lines = scalar @lines; #'##
close TEST;

open FILE, "<hold.tmp";
my $flag = 0;
my $gene_start = 0;
my $gene_end = 0;
my @holding_gene_details = ();
my $number = 1;


my $current_line = 1;

while (<FILE>) 
{
	chomp $_;
	my $line = $_;
	my @data = split '\t', $line;
	my $start = $data[5];
	my $end = $data[6];
	
	if ($flag ==0)
		{
		$gene_start = $start;
		$gene_end = $end;
		$flag++;
		}
		
	if ($start >= $gene_start && $start < $gene_end)
			{
			push @holding_gene_details, $line; ### these are the overlapping
			if ($end > $gene_end) {$gene_end = $end;} # keeps tabs on extreme right side #################
			}
		
		
	if ($start >= $gene_end || $current_line == ($number_of_lines ))  ### looks for exception where only single prediction
			{
			my $current_best = 0;
			my $best_hit_line = "";
			
			foreach (@holding_gene_details)
					{
					chomp $_;
					my $best_line = $_;
					my @best_data = split  '\t', $best_line;
					my $best_score = $best_data[1];
					my $best_intron_count = $best_data[9];
					my $best_q_length = $best_data[4];
					if ($best_score >= $current_best && $best_intron_count <= $max_introns && $best_q_length >= $min_length) 
					
					
						{
						$best_hit_line = $best_line;
						}
					}
			#~ find best in @holding_gene_details
			
			if ($best_hit_line =~ /^[A-Za-z0-9\_\-]/)
				{
				print OUT "$prefix\.$number\t$chr\t$best_hit_line\n";
				$number++;
				}
			@holding_gene_details = ();
			push @holding_gene_details, $line;
			$gene_start = $start;
			$gene_end = $end;
			}
		
$current_line++;
}

close OUT;
close FILE;
system "rm -rf ./hold.tmp";
system "rm -rf ./hold1.tmp";

