package Lingua::CoNLLX::Sentence;

use utf8;
use v5.12;
use strict;
use warnings  qw(FATAL utf8);
use open      qw(:std :utf8);
use charnames qw(:full :short);

use Moo;

has tokens => (is => 'ro', writer => '_tokens');
has comments => (is => 'ro',);
#has root_children => (is => 'ro', default => sub { [] });

sub BUILD {
    my $self = shift;

    my $broken = undef;
    my $tokens = $self->tokens;
    unshift @$tokens, Lingua::CoNLLX::Token->new(id => 0);

    for my $i (0..$#$tokens) {
        if($tokens->[$i]->id != $i) {
            $broken = 1;
            last;
        }
    }

    if($broken) {
        # Traverse the token list from back to front, moving them to the index
        # they "want", so that the next bit of code will work.
        for my $i (reverse 0..$#$tokens) {
            my $t = $tokens->[$i];
            if($t->id != $i) {
                $tokens->[$t->id] = $t;
                $tokens->[$i] = undef;
            }
        }
    }

    # Replace the numeric head attribute with the actual node they point to.
    for my $token (@{$tokens}[1..$#$tokens]) {
        next if not defined $token;
        my $head = $token->head;
        $token->_head($tokens->[$head]);
    }

    if($broken) {
        # Remove lacunae in the token list and renumber the tokens.
        $tokens = [grep {defined $_} @$tokens];
        $self->_tokens($tokens);
        $self->_renumber;
    }

    # FIXME: This will leak memory! Since this results in a circular data
    # structure, perl's reference counting GC will never be able to free the
    # memory associated with a sentence. The best way to solve this is
    # probably to use Scalar::Util::weaken on the _child_ links (since there
    # are fewer of those), but I should do some more research before doing
    # something here. Also, I should see how severe the effects of the leak
    # are.
    # Build the child lists for each token.
    for my $t (@{$tokens}[1..$#$tokens]) {
        $t->head->_add_child($t);
    }
}

sub length {
    my $self = shift;

    return @{$self->tokens} - 1;
}

sub token {
    my $self = shift;
    my ($i) = @_;

    return $self->tokens->[$i];
}

sub add_token {
    my $self = shift;
    my ($token, $position) = @_;

    my @tail = splice @{$self->tokens}, $position;
    push @{$self->tokens}, $token, @tail;
    $self->_renumber;

    $token->_head($self->token($token->head));
    $token->head->_add_child($token, resort => 1);
}

sub _renumber {
    my $self = shift;

    my $tokens = $self->tokens;
    for my $i (0..$#$tokens) {
        $tokens->[$i]->_id($i);
    }
}

1;
