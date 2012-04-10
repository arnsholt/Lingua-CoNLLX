use utf8;
use v5.12;
use strict;
use warnings  qw(FATAL utf8);
use open      qw(:std :utf8);
use charnames qw(:full :short);

use Test::More tests => 2;

use Lingua::CoNLLX;

my $corpus = Lingua::CoNLLX->new(file => 't/test.conll');

# TODO: Proper test cases here.
my @traversed;
my $prefix = [qw/0 20 1 2 3 4 6 5 7 8 10 11 13 9 12 14 19 16 17 18 15 25 21 22
    23 24 40 27 26 34 28 31 29 33 30 32 35 39 36 37 38 44 41 42 43/];
my $postfix = [qw/3 5 6 4 8 7 9 12 14 13 11 10 2 1 17 16 15 18 19 22 23 21 26
    28 29 30 32 33 31 35 34 27 38 37 36 39 41 43 42 44 40 24 25 20 0/];

@traversed = ();
$corpus->sentence(0)->traverse(sub { push @traversed, $_->id }, order => 'prefix');
is_deeply(\@traversed, $prefix, 'prefix traversal');

@traversed = ();
$corpus->sentence(0)->traverse(sub { push @traversed, $_->id }, order => 'postfix');
is_deeply(\@traversed, $postfix, 'postfix traversal');
