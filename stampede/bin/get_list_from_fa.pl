#!/usr/bin/env perl

=head1 NAME

   get_list_from_fa.pl

=head1 SYNOPSIS

   get_list_from_fa.pl input.fa list output 

Options:
 
   none.

=head1 DESCRIPTION

   gets a list of sequences from a fasta file 
 
=head1 SEE ALSO

perl.

=head1 AUTHOR

Bonnie Hurwitz E<lt>bhurwitz@email.arizona.eduE<gt>,

=head1 COPYRIGHT

Copyright (c) 2011 Bonnie Hurwitz 

This library is free software;  you can redistribute it and/or modify 
it under the same terms as Perl itself.

=cut

use strict;
use warnings;
use Bio::SeqIO;

if ( @ARGV != 3 ) {
    die "Usage: get_list_from_fasta.pl input.fa list output\n";
}

my $inputfilename  = shift @ARGV;
my $list           = shift @ARGV;
my $outputfilename = shift @ARGV;

my $in = Bio::SeqIO->new(
    '-file'   => "$inputfilename",
    '-format' => 'Fasta'
);
my $out = Bio::SeqIO->new(
    '-file'   => ">$outputfilename",
    '-format' => 'Fasta'
);

open( LIST, $list );
my %list;
while (<LIST>) {
    chomp $_;
    my ( $cl, $id ) = split( /\t/, $_ );
    $list{$id} = $cl;
}

# go through each of the sequence records in Genbank
while ( my $seq = $in->next_seq() ) {
    my $id = $seq->id();
    if ( exists $list{$id} ) {
        $out->write_seq($seq);
    }
}
