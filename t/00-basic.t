use utf8;
use v5.12;
use strict;
use warnings  qw(FATAL utf8);
use open      qw(:std :utf8);
use charnames qw(:full :short);

use Data::Dumper;
use Test::More tests => 106;

use Lingua::CoNLLX;

# TODO
my $corpus = Lingua::CoNLLX->new(file => 't/test.conll');
ok(1, 'reading corpus');

my $tokens = $corpus->sentence(0)->tokens;
is(scalar @$tokens, 45, 'number of tokens');

my @heads = qw/20 1 2 2 6 4 2 7 13 2 10 13 11 13 18 19 16 19 20 0 25 21 21 25
    20 27 40 34 31 33 34 33 31 27 34 39 36 37 40 24 44 44 42 40/;
# No, the child list is not manually entered. I generated it with this
# command:
# head -n 44 t/test.conll | sort -nk 7 | awk '{print $7, $1}'
# The output has to be fiddled a bit with, since token ids don't always come
# in the correct order.
my @children = ([20],
                [2],
                [3, 4, 7, 10],
                [],
                [6],
                [],
                [5],
                [8],
                [],
                [],
                [11],
                [13],
                [],
                [9, 12, 14],
                [],
                [],
                [17],
                [],
                [15],
                [16, 18],
                [1, 19, 25],
                [22, 23],
                [],
                [],
                [40],
                [21, 24],
                [],
                [26, 34],
                [],
                [],
                [],
                [29, 33],
                [],
                [30, 32],
                [28, 31, 35],
                [],
                [37],
                [38],
                [],
                [36],
                [27, 39, 44],
                [],
                [43],
                [],
                [41, 42]);
for my $i (1..44) {
    my $t = $tokens->[$i];
    my $head = $t->head->id;
    is($head, $heads[$i-1], "head #$i");
    is_deeply([map {$_->id} @{$t->children}], $children[$i], "child list #$i");
}
is_deeply([map {$_->id} @{$tokens->[0]->children}], $children[0], 'root child list');

$tokens = $corpus->sentence(1)->tokens;
is(scalar @$tokens, 5, 'number of tokens');
@heads = qw/2 0 4 2/;
@children = ([2],
             [],
             [1, 4],
             [],
             [3]);
for my $i (1..4) {
    my $t = $tokens->[$i];
    my $head = $t->head->id;
    is($head, $heads[$i-1], "head #$i");
    is_deeply([map {$_->id} @{$t->children}], $children[$i], "child list #$i");
}
is_deeply([map {$_->id} @{$tokens->[0]->children}], $children[0], 'root child list');

my $comments = $corpus->sentence(1)->comments;
is(scalar @$comments, 1, 'no. of comments');
is($comments->[0], 'Test', 'comment contents');

# Adding tokens:
my $new_token = Lingua::CoNLLX::Token::from_array(qw/1 form lemma cpos pos _ 2 REL 0 _/);
my $sentence = $corpus->sentence(1);
$sentence->add_token($new_token, 3);
$tokens = $sentence->tokens;
is(scalar @$tokens, 6, 'number of tokens after add');
is($tokens->[3]->head->id, 2, 'head of new token');
#is(scalar @{$tokens->[2]->children}, 3, 'no. of children of token #2 after add');
is_deeply([map {$_->id} @{$tokens->[2]->children}], [1, 3, 5], 'child list #2 after add');
