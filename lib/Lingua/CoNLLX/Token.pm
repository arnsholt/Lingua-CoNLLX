package Lingua::CoNLLX::Token;

use utf8;
use v5.12;
use strict;
use warnings  qw(FATAL utf8);
use open      qw(:std :utf8);
use charnames qw(:full :short);

use overload q{""} => 'to_string';
use List::MoreUtils qw/zip/;
use Moo;

my @fields = qw/id form lemma cpostag postag feats head deprel phead pdeprel/;

has id       => (is => 'ro', writer => '_id');
has form     => (is => 'ro');
has lemma    => (is => 'ro');
has cpostag  => (is => 'ro');
has postag   => (is => 'ro');
has feats    => (is => 'ro', writer => '_feats');
has head     => (is => 'ro', writer => '_head');
has deprel   => (is => 'ro');
has phead    => (is => 'ro');
has pdeprel  => (is => 'ro');
has children => (is => 'ro', writer => '_children', default => sub { [] });

sub BUILD {
    my $self = shift;

    for my $field (@fields) {
        $self->{$field} = undef if defined $self->{$field} and $self->{$field} eq '_';
    }

    if($self->feats) {
        $self->_feats([split m/\|/msx, $self->feats])
    }
}

sub from_array {
    __PACKAGE__->new(zip @fields, @_);
}

sub to_string {
    my $self = shift;

    my @data = ();
    for my $field (@fields) {
        my $val = $self->$field;
        $val = $val->id if defined $val and $field eq 'head';
        $val = '_' if not defined $val;
        push @data, $val;
    }

    return join "\t", @data;
}

sub _add_child {
    my $self = shift;
    my ($child, %args) = @_;

    push @{$self->children}, $child;
    $self->_children([sort {$a->id <=> $b->id} @{$self->children}]) if $args{resort};
}

sub _prefix {
    my $self = shift;
    my ($sub, %args) = @_;

    local $_ = $self;
    $sub->($self, $args{data});
    for my $child (@{$self->children}) {
        $child->_prefix(@_);
    }
}

# XXX: Infix order isn't obviously defined for a general n-ary tree.
#sub _infix {
#    my $self = shift;
#    my ($sub, %args) = @_;
#
#    $sub->($self, $args{data});
#    for my $child (@{$self->children}) {
#        $child->_infix(@_);
#    }
#}

sub _postfix {
    my $self = shift;
    my ($sub, %args) = @_;

    for my $child (@{$self->children}) {
        $child->_postfix(@_);
    }
    local $_ = $self;
    $sub->($self, $args{data});
}

1;
