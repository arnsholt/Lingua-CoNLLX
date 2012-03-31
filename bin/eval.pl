#!/usr/bin/env perl

use utf8;
use v5.12;
use strict;
use warnings  qw(FATAL utf8);
use open      qw(:std :utf8);
use charnames qw(:full :short);

use Lingua::CoNLLX;
use List::Util qw/max/;
use Getopt::Long;

my ($gold_file, @system);
my $result = GetOptions('s|system=s{,}' => \@system,
                        'g|gold=s'   => \$gold_file,);
usage(die => 1) if not $result or not $gold_file;

my $gold = Lingua::CoNLLX->new(file => $gold_file);
my %stats = ();
for my $system_file (@system) {
    my $system = Lingua::CoNLLX->new(file => $system_file);
    # TODO: Wrap in eval BLOCK to handle failures in evaluate().
    my $stats = evaluate($gold, $system);
    $stats{$system_file} = $stats;
}

# Print stats:
my $maxlen = max map {length $_} @system, $gold_file;

# Print header:
#                   | 100.00% | 100.00% | 100.00%
printf "%-${maxlen}s |   UAS  |   LAS  | Labels\n", $gold_file;
say '-'x$maxlen,   '-+--------+--------+--------';
for my $file (@system) {
    my $w      = $stats{$file}{words};
    my $uas    = 100.0*$stats{$file}{uas}/$w;
    my $las    = 100.0*$stats{$file}{las}/$w;
    my $labels = 100.0*$stats{$file}{labels}/$w;
    printf "%-${maxlen}s | %#5.4g%% | %#5.4g%% | %#5.4g%%\n", $file, $uas, $las, $labels;
}

sub evaluate {
    my ($gold, $system) = @_;

    my $golds = $gold->sentences;
    my $systems = $system->sentences;
    my $length = scalar @$golds;

    # Don't really want to handle evaluating corpora w/different number of
    # sentences...
    #die "$gold->file and $system->file are of unequal length!\n" if ;
    if($gold->size != $system->size) {
        my $gold_file = $gold->file;
        my $system_file = $system->file;
        die "$gold_file and $system_file are of unequal length!\n";
    }

    my %stats = (words  => 0,
                 uas    => 0,
                 las    => 0,
                 labels => 0,);

    for my $i (0..$length-1) {
        my $g = $golds->[$i];
        my $s = $systems->[$i];

        # Don't really want to handle evaluating sentences of different
        # lengths either...
        if($g->length != $s->length) {
            my $n = $i+1;
            die "Sentence #$n $gold->file and $system->file have different lengths!\n"
        }

        $stats{words} += $g->length;
        for my $j (1..$g->length) {
            if($g->token($j)->form ne $s->token($j)->form) {
                my $gold_file = $gold->file;
                my $system_file = $system->file;
                my $gold_word = $g->token($j)->form;
                my $system_word = $g->token($j)->form;

                die "$gold_file and $system_file: Sentence $i, word $j don't match (`$gold_word' vs. `$system_word').\n";
            }

            my $deprel = $g->token($j)->deprel   eq $s->token($j)->deprel;
            my $head   = $g->token($j)->head->id == $s->token($j)->head->id;

            $stats{labels}++ if $deprel;
            $stats{uas}++    if $head;
            $stats{las}++    if $head and $deprel;
        }
    }

    return \%stats;
}

sub usage {
    my %args = @_;
    say STDERR "Usage: $0 -g GOLD -s SYSTEM [-s SYSTEM ...]";

    exit($args{die}) if exists $args{die};
}
