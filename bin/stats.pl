#!/usr/bin/env perl

use utf8;
use v5.12;
use strict;
use warnings  qw(FATAL utf8);
use open      qw(:std :utf8);
use charnames qw(:full :short);

use Lingua::CoNLLX;
use List::Util qw/max/;

usage(die => 1) if not @ARGV;

my %stats = ();
for my $file (@ARGV) {
    my $corpus = Lingua::CoNLLX->new(file => $file);

    my $sents = $corpus->size;
    my @sentence_length = map {$_->length} @{$corpus->sentences};
    $stats{$file} = compute_stats(@sentence_length);
}

my $maxlen = max map {length $_} @ARGV;
my $maxn   = max map {length "$_"} map {$stats{$_}{n}} keys %stats;
printf "%${maxlen}s | %${maxn}s | mean  | sigma\n", '', 'n';
say '-'x$maxlen, '-+------+-------+-------';
for my $file (@ARGV) {
    printf "%-${maxlen}s | %${maxn}d | %#5.4g | %#5.4g\n", $file, @{$stats{$file}}{qw/n mean stddev/};
}

sub compute_stats {
    my ($sum, $squares, $n) = (0, 0, 0);
    for my $x (@_) {
        $n++;
        $sum     += $x;
        $squares += $x*$x;
    }

    my $mean = $sum/$n;
    return {n      => $n,
            mean   => $mean,
            stddev => sqrt(1/($n-1)*($squares - 2*$mean*$sum + $n*$mean*$mean))};
}

sub usage {
    my %args = @_;

    say STDERR "Usage: $0 FILE [FILE ...]";

    exit($args{die}) if exists $args{die};
}
