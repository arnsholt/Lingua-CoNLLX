package Lingua::CoNLLX::Sentence;

use utf8;
use v5.12;
use strict;
use warnings  qw(FATAL utf8);
use open      qw(:std :utf8);
use charnames qw(:full :short);

use overload q{""} => 'to_string';
use Carp;
use Moo;

has tokens => (is => 'ro', writer => '_tokens');
has comments => (is => 'ro',);
has start => (is => 'ro',);
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
        $token->head($tokens->[$head]);
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

    $token->head($self->token($token->head));
    $token->head->_add_child($token, resort => 1);
}

sub delete_token {
    my $self = shift;
    my ($t, %args) = @_;

    $t = $self->token($t) if not ref $t;
    my $id = $t->id;
    if(scalar @{$t->children} and $args{recursive}) {
        croak "Recursive delete_token not yet implemented"
    }
    elsif(scalar @{$t->children}) {
        croak "Token $id has children";
    }

    my $head = $t->head;
    splice @{$self->tokens}, $id, 1; # In-place modification of token array.
    $head->_delete_child($t);
    $self->_renumber;
}

sub to_string {
    my $self = shift;

    my @lines = (map({"# $_"} @{$self->comments}),
                 map({"$_"} @{$self->tokens}[1..$self->length]));

    return join "\n", @lines;
}

sub _renumber {
    my $self = shift;

    my $tokens = $self->tokens;
    for my $i (0..$#$tokens) {
        $tokens->[$i]->_id($i);
    }
}

sub traverse {
    my $self = shift;
    my ($sub, %args) = @_;
    $args{order} = 'prefix' if not exists $args{order}; # XXX: What's a good default order?

    my $root = $self->token(0);
    given($args{order}) {
        when('prefix')  { return $root->_prefix(@_); }
        when('postfix') { return $root->_postfix(@_); }
        default { croak "Unknown traversal order $args{order}"; }
    }
}

1;
