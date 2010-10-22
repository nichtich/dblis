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

my @bibtexmonth = qw(jan feb mar apr may jun jul aug sep oct nov dec);

# the following variables define a bibliographic record
my ($key, $issue, $url, $title, @authors, $abstract, $year, $month, $day);
my $issn = "1940-5758";

my $with_abstracts = 1; # set false for quick generation

use LWP::Simple;

my $html = get($source); # because pQuery cracks Unicode

pQuery($html)->find('.issue')->each(sub {
    my $p = pQuery($_);
    my $issuetitle = $p->find('.issuetitle a')->text;

    $issuetitle =~ /issue +(.*), +(\d\d\d\d)-(\d\d)-(\d\d)/i
      or warn "Failed to parse issue '$issuetitle'\n";
    ($issue, $year, $month, $day) = ($1,$2,$3,$4);

    if ($with_abstracts) {
        $html = get ("http://journal.code4lib.org/issues/issue$issue");
        $p = pQuery($html);
        $p->find('.article')->each( \&article );
    } else {
        $p->find('li')->each( \&article );
    }
});

sub article {
    my $article = pQuery($_);
    my $a = $article->find('.articletitle a');

    $url = $a->get(0)->getAttribute('href');
    $url =~ /(\d+)$/; $key = "code4lib$1";
    $title = $a->text;

    my $author = $article->find('.author')->text;

    # J. Gordon Daines, III => J. Gordon Daines III
    $author =~ s/, *(I+)/ $1/;

    # split author names
    @authors = map { s/ *\([^)]*\) *$//; $_ }
                map { s/(^\s+|\s+$)//g; $_ }
                split /&|,? +and +|,? +with +|,/, $author;

    $abstract = $article->find('.abstract')->text;

    # Right now this only exports BibTeX. Feel free to export the
    # bibliographic data as something else, unless you modify 
    # the variables that define the record and thus break bibtex()
    bibtex(); 
};


# This will fail if anything contains '/', but BibteX is bad anyway
sub bibtex {
  my @fields = (
    " author = {" . join(' and ', @authors) . "}",
    " title = {$title}",
    " journal = {Code4Lib Journal}",
    " issue = {$issue}",
    " year = {$year}",
    " month = " . $bibtexmonth[$month-1],
    " day = {$day}",
    " url = {$url}",
    " issn = {$issn}"
  );
  push @fields, " abstract = {$abstract}" if $abstract;
  print join(",\n", "\@article{$key", @fields, "}", "");
}

=head1 LICENSE

This script is part of the dblis repository: http://github.com/nichtich/dblis
Feel free to fork and add scrapers for other interesting journals.

=cut
