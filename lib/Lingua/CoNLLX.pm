package Lingua::CoNLLX;

use utf8;
use v5.12;
use strict;
use warnings  qw(FATAL utf8);
use open      qw(:std :utf8);
use charnames qw(:full :short);

use Moo;

use Lingua::CoNLLX::Token;
use Lingua::CoNLLX::Sentence;

has file => (is => 'ro');
#has 'lazy'; # TODO: Implement this.
has sentences => (is => 'ro', writer => '_sentences');

sub BUILD {
    my $self = shift;

    $self->_read_corpus;
}

sub _read_corpus {
    my $self = shift;

    my $filename = $self->file;
    open my $file, '<', $filename or die "Couldn't read $filename: $!\n";

    my @lines = ();
    my @sentences = ();
    my @comments = ();
    while(my $line = <$file>) {
        $line =~ s/\A\s+ | \s+\z//msxg; # Trim leading and trailing whitespace
        #my $blank = (not $line or $line =~ m/\A\#/msx);
        my $comment = $line =~ m/\A\#\s* (.*) \z/msxo;
        push @comments, $1 if $comment and length $1 > 0;
        my $blank = (not $line or $comment);
        next if $blank and not @lines; # More than one blank line between sentences
        if($blank) {
            my @tokens = map {Lingua::CoNLLX::Token::from_array(@$_)} @lines;
            push @sentences, Lingua::CoNLLX::Sentence->new(tokens => \@tokens,
                                                           comments => \@comments,);
            @lines = ();
            @comments = ();
            next;
        }

        push @lines, [split m/\s+/, $line];
    }

    if(@lines) {
        my @tokens = map {Lingua::CoNLLX::Token::from_array(@$_)} @lines;
        push @sentences, Lingua::CoNLLX::Sentence->new(tokens => \@tokens,
                                                       comments => \@comments,);
    }

    $self->_sentences(\@sentences);
}

sub sentence {
    my $self = shift;

    return $self->sentences->[$_[0]];
}

sub size {
    my $self = shift;

    return scalar @{$self->sentences};
}

1;
