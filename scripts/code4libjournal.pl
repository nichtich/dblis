#!/usr/bin/perl

use strict;
use warnings;

=head1 NAME

Code4LibJournal - extract Code4lib Journal Bibliography

=head1 DESCRIPTION

This script creates a bibliography of Code4Lib journal articles by screen
scraping. Right now it only exports BibTeX in UTF-8. Further extensions may
allow other export formats and add parsing of article citations etc.

The input URL is hard-coded. The output is sent to STDOUT.

=cut

use pQuery;
use File::Path qw(make_path);

binmode STDOUT, ':utf8';

my $source = 'http://journal.code4lib.org/issues';

my ($key, $issue, $url, $title, @authors, $abstract, $year, $month, $day);

use LWP::Simple;

my $html = get($source); # because pQuery cracks Unicode

pQuery($html)->find('.issue')->each(sub {
    my $p = pQuery($_);
    my $issuetitle = $p->find('.issuetitle a')->text;

    $issuetitle =~ /issue +(.*), +(\d\d\d\d)-(\d\d)-(\d\d)/i
      or warn "Failed to parse issue '$issuetitle'\n";
    ($issue, $year, $month, $day) = ($1,$2,$3,$4);

    $p->find('li')->each(sub {
        my $li = pQuery($_); 
        my $a = $li->find('.articletitle a');

        $url = $a->get(0)->getAttribute('href');
        $url =~ /(\d+)$/; $key = "code4lib$1";
        $title = $a->text;

        my $author = $li->find('.author')->text;

        # J. Gordon Daines, III => J. Gordon Daines III
        $author =~ s/, *(I+)/ $1/;

        # split author names
        @authors = map { s/ *\([^)]*\) *$//; $_ }
                   map { s/(^\s+|\s+$)//g; $_ }
                   split /&|,? +and +|,? +with +|,/, $author;

        # .. .we could further get the abstract ...

        bibtex(); # right now we only export BibTeX
    });
});


# This will fail if anything contains '/' but BibteX is bad anyway
sub bibtex {
  print 
    join(",\n", "\@article{$key",
    " author = {" . join(' and ', @authors) . "}",
    " title = {$title}",
    " journal = {Code4Lib Journal}",
    " volume = {$issue}",
    " year = {$year}",
    " month = {$month}",
    " day = {$day}",
    " url = {$url}",
    "}"
   ) . "\n";
}
