#!/usr/bin/env perl

use strict;
use feature 'say';
use autodie;
use DBI;
use Getopt::Long;
use File::Find::Rule;
use Pod::Usage;
use Readonly;
use Text::RecordParser::Tab;

Readonly my %DEFAULT => (
    db_dir => '/usr/local/imicrobe/simap/features/db'
);

Readonly my @BLAST_FLDS => qw(qseqid sseqid pident length mismatch gapopen 
    qstart qend sstart send evalue bitscore);

Readonly my @OUT_FLDS => qw(date dbname evalue feature_desc feature_id
    feature_name hit_start hit_stop interpro_desc interpro_name 
    protein_len seq_id true_pos_flag);

main();

# --------------------------------------------------
sub main {
    my %args = get_args();

    if ($args{'help'} || $args{'man_page'}) {
        pod2usage({
            -exitval => 0,
            -verbose => $args{'man_page'} ? 2 : 1
        });
    } 

    my $out_fh;
    if (my $out_file = $args{'out'}) {
        open $out_fh, '>', $out_file;
    }
    else {
        $out_fh = *STDOUT;
    }

    my $file   = $args{'blast'} or pod2usage('Missing BLAST file');
    my $db_dir = $args{'db_dir'} || $DEFAULT{'db_dir'};

    unless (-d $db_dir) {
        pod2usage("db_dir ($db_dir) is not a directory");
    }

    my @dbs = File::Find::Rule->file()->name('*.db')->in($db_dir);

    unless (@dbs) {
        pod2usage("Found no '.db' files in $db_dir");
    }

    printf STDERR "Found %s dbs in '%s'\n", scalar(@dbs), $db_dir;

    my @dbhs = map { 
        DBI->connect("dbi:SQLite:dbname=$_", "", "", { RaiseError => 1 })
    } @dbs;

    my $p = Text::RecordParser::Tab->new($file);
    $p->bind_fields(@BLAST_FLDS);
    my $sql = 'select * from feature where feature_id=?';

    say $out_fh join("\t", 'protein_id', @OUT_FLDS);

    my ($n_checked, $n_annot) = (0, 0);
    while (my $r = $p->fetchrow_hashref) {
        my $feature_id = $r->{'sseqid'} or next;

        $n_checked++;

        for my $dbh (@dbhs) {
            for my $simap (
              @{$dbh->selectall_arrayref($sql, { Columns => {} }, $feature_id)}
            ) {
                say $out_fh join("\t", 
                    $r->{'qseqid'},
                    (map { $simap->{$_} // '' } @OUT_FLDS)
                );
                $n_annot++;
            }
        }
    }

    say STDERR "Done. Checked = $n_checked, annotations = $n_annot.";
}

# --------------------------------------------------
sub get_args {
    my %args;
    GetOptions(
        \%args,
        'blast=s',
        'db_dir:s',
        'out:s',
        'help',
        'man',
    ) or pod2usage(2);

    return %args;
}

__END__

# --------------------------------------------------

=pod

=head1 NAME

annotate-blast.pl - a script

=head1 SYNOPSIS

  annotate-blast.pl -b blast.out -d /path/to/simap/features/db

Required arguments:

  --blast  BLAST output file in tab format (-outfmt 6)

Options (defaults in parentheses):

  --out    File name to write results (STDOUT)
  --db_dir Location of the SIMAP SQLite db 
           (/usr/local/imicrobe/simap/features/db)
  --help   Show brief help and exit
  --man    Show full documentation

=head1 DESCRIPTION

Parses "--blast" output for "sseqid" and looks that up as the "feature_id" 
in the SIMAP SQLite dbs in the "--db_dir."  Writes the db records to the
"--out" file or STDOUT.

=head1 SEE ALSO

SIMAP.

=head1 AUTHOR

Ken Youens-Clark E<lt>kyclark@email.arizona.eduE<gt>.

=head1 COPYRIGHT

Copyright (c) 2016 Hurwitz Lab

This module is free software; you can redistribute it and/or
modify it under the terms of the GPL (either version 1, or at
your option, any later version) or the Artistic License 2.0.
Refer to LICENSE for the full license text and to DISCLAIMER for
additional warranty disclaimers.

=cut
