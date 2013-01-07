#!/usr/bin/env perl

use utf8;
use v5.12;
use strict;
use warnings  qw(FATAL utf8);
use open      qw(:std :utf8);
use charnames qw(:full :short);

use Getopt::Long;

use Lingua::CoNLLX;
use List::Util qw/max sum/;
use Statistics::Distributions qw/fdistr/;

my $anova;
my $result = GetOptions(anova => \$anova);

usage(die => 1) if not @ARGV;

my %stats = ();
for my $file (@ARGV) {
    my $corpus = Lingua::CoNLLX->new(file => $file);

    my $sents = $corpus->size;
    my @sentence_length = map {$_->length} @{$corpus->sentences};
    $stats{$file} = stats(@sentence_length);
}

my $maxlen = max map {length $_} @ARGV;
my $maxn   = max map {length "$_"} map {$stats{$_}{n}} keys %stats;
printf "%${maxlen}s | %${maxn}s | mean  | sigma\n", '', 'n';
say '-'x$maxlen, '-+-', '-'x$maxn, '-+-------+-------';
for my $file (@ARGV) {
    printf "%-${maxlen}s | %${maxn}d | %#5.4g | %#5.4g\n", $file, @{$stats{$file}}{qw/n mean stddev/};
}

if($anova) {
    my $between    = stats(map {$_->{mean}} values %stats);
    my $within_df  = sum map {$_->{df}} values %stats;
    my $within_ss  = sum map {$_->{ss}} values %stats;
    my $within_var = $within_ss/$within_df;

    my $f = $between->{var}/$within_var;

    my $dflen = max map {length "$_"} $within_df, $between->{df};

    say    '';
    printf " Source   | %${dflen}s |   ss  |  MSS  |   F\n", 'df';
    say    '----------+-', '-'x$dflen , '-+-------+-------+-------';
    printf "Corpus    | %${dflen}d | %#5.4g | %#5.4g | %#5.4g\n", @{$between}{qw/df ss var/}, $f;
    printf "Residuals | %${dflen}d | %#5.4g | %#5.4g |\n", $within_df, $within_ss, $within_var;

    my $crit5pc = fdistr($between->{df}, $within_df, 0.05);
    my $crit1pc = fdistr($between->{df}, $within_df, 0.01);
    say '';
    say "Critical F-values: $crit5pc (p < 5%), $crit1pc (p < 1%)";
}

sub stats {
    my $n       = scalar @_;
    my $sum     = sum @_;
    my $squares = squares(@_);

    my $mean = $sum/$n;
    my $ss = $squares - $sum*$sum/$n;
    my $var = $ss/($n-1);
    return {n      => $n,
            df     => $n - 1,
            mean   => $mean,
            stddev => sqrt($var),
            var    => $var,
            ss     => $ss};
}

sub squares {
    return sum map {$_*$_} @_;
}

sub usage {
    my %args = @_;

    say STDERR "Usage: $0 [--anova] FILE [FILE ...]";

    exit($args{die}) if exists $args{die};
}
