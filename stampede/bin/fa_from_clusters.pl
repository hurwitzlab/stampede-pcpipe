#!/usr/bin/env perl

use strict;
use feature 'say';
use autodie;
use Bio::SeqIO;
use Getopt::Long;
use File::Basename 'basename';
use Pod::Usage;
use Readonly;

main();

# --------------------------------------------------
sub main {
    my $args = get_args();

    if ($args->{'help'} || $args->{'man_page'}) {
        pod2usage({
            -exitval => 0,
            -verbose => $args->{'man_page'} ? 2 : 1
        });
    }; 

    my $sequence_file = $args->{'sequence_file'}
                        or pod2usage('Missing sequence file');
    my $output_file   = $args->{'output_file'} || basename($0) . '.out';
    my $num           = $args->{'number'} || 1;
    my $clusters      = get_clusters($args->{'cluster_file'});
    my ($avg, $max)   = average_max(map { $_->{'count'} } values %$clusters);

    my %seqs = 
        map  { $_->{'rep'}, 1 }
        grep { $_->{'count'} >= $num && $_->{'rep'} ne '' }
        values %$clusters;

    my $n_seqs = scalar(keys %seqs);
    if ($n_seqs == 0) {
        printf "Cluster file (%s) contained nothing above %s\n", 
            $args->{'cluster_file'}, $num;

        die "No clusters passed muster.\n";
    }

    printf "Found %s representative sequences from %s clusters\n", 
        $n_seqs, scalar(keys %$clusters);

    my $in = Bio::SeqIO->new(
        -file   => $sequence_file,
        -format => 'Fasta'
    );

    my $out = Bio::SeqIO->new(
        -file   => ">$output_file",
        -format => 'Fasta'
    );

    my ($n_checked, $n_took) = (0, 0);
    my %seen;
    while (my $seq = $in->next_seq) {
        $n_checked++;
        my $id = $seq->id or next;
        next if $seen{$id}++;

        if ($seqs{$id} ) {
            $out->write_seq($seq);
            $n_took++;
        }
    }

    say "Checked $n_checked, $n_took were >= $num (avg = $avg, max = $max)";
    say "See '$output_file'";
}

# --------------------------------------------------
sub get_clusters {
    my $file = shift or die "Missing cluster file.\n";
    my $min  = shift || 1;

    open my $fh , '<', $file;

    my ($name, %clusters);
    while (my $line = <$fh>) {
        chomp($line);
        if ($line =~ /^>(.+)/) {
            ($name = $1) =~ s/\s+/_/g;
            $clusters{ $name } = { count => 0, rep => '' };
        }
        else {
            if ($name && $line =~ /^.+>([^.]+)[.]{3}\s+(.+)/) {
                $clusters{ $name }{'count'}++;

                my ($seq_id, $id) = ($1, $2);

                if ($id eq "*") {
                    $clusters{ $name }{'rep'} = $seq_id;
                }
            }
        }
    }

    return \%clusters;
}

# --------------------------------------------------
sub get_args {
    my %args;
    GetOptions(
        \%args,
        'cluster_file=s',
        'sequence_file=s',
        'output_file=s',
        'number=i',
        'help',
        'man',
    ) or pod2usage(2);

    return \%args;
}

# --------------------------------------------------
sub average_max {
    my @numbers = @_ or return 0;
    my ($total, $max) = (0, 0);
    map { $total += $_; $max = $_ if $_ > $max } @numbers;
    return (int($total / scalar(@numbers)), $max);
}

__END__

# --------------------------------------------------

=pod

=head1 NAME

fa_from_clusters.pl - a script

=head1 SYNOPSIS

  fa_from_clusters.pl -c cluster-file -s sequence-file -n 20 -o out-file

Options:

  --cluster_file   The output of cd-hit
  --sequence_file  FASTA file 
  --out_file       Output file (FASTA format)
  --number         Minimum number of cluster members for selection

  --help           Show brief help and exit
  --man            Show full documentation

=head1 DESCRIPTION

Takes the "cluster_file" from cd-hit and selects the sequences from 
"sequence_file" that have a minimum "number" of members.

=head1 AUTHOR

Ken Youens-Clark E<lt>kyclark@email.arizona.eduE<gt>.

=head1 COPYRIGHT

Copyright (c) 2016 kyclark

This module is free software; you can redistribute it and/or
modify it under the terms of the GPL (either version 1, or at
your option, any later version) or the Artistic License 2.0.
Refer to LICENSE for the full license text and to DISCLAIMER for
additional warranty disclaimers.

=cut
