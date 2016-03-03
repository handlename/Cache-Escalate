package Cache::Escalate;
use 5.008001;
use strict;
use warnings;

use Class::Accessor::Lite (
    ro => [qw{caches sync_level sync_expiration}],
);

our $VERSION = "0.01";

our $SYNC_LEVEL_NONE   = 1;
our $SYNC_LEVEL_MISSED = 2;
our $SYNC_LEVEL_FULL   = 3;

sub new {
    my $class = shift;
    my %args = @_;

    if (! $args{caches} || ref $args{caches} ne "ARRAY" || ! scalar @{$args{caches}}) {
        die "One more caches required.";
    }

    for my $cache (@{$args{caches}}) {
        if (! _looks_like_cache($cache)) {
            die "`caches` contains invalid object.";
        }
    }

    return bless {
        caches     => $args{caches},
        sync_level => $args{sync_level},
    }
}

sub _looks_like_cache {
    my ($cache) = @_;

    for my $method (qw{get set delete}) {
        return if ! $cache->can($method);
    }

    return 1;
}

sub get {
    my ($self, $key) = @_;

    my $value;
    my @caches = @{$self->caches};
    my @missed;
    my @rest;

    while (my $cache = shift @caches) {
        $value = $cache->get($key);

        if (defined $value) {
            @rest = @caches;
            last;
        }

        push @missed, $cache;
    }

    return if ! defined $value;
    return $value if $self->sync_level == $SYNC_LEVEL_NONE;

    my @sync_targets = $self->sync_level == $SYNC_LEVEL_MISSED
        ? @missed
        : (@missed, @rest);

    for my $cache (@sync_targets) {
        $cache->set($key, $value, $self->sync_expiration);
    }

    return $value;
}

sub set {
    my ($self, $key, $value, $expiration) = @_;

    for my $cache (@{$self->caches}) {
        $cache->set($key, $value, $expiration);
    }

    return;
}

sub delete {
    my ($self, $key) = @_;

    for my $cache (@{$self->caches}) {
        $cache->delete($key);
    }

    return;
}

1;
__END__

=encoding utf-8

=head1 NAME

Cache::Escalate - It's new $module

=head1 SYNOPSIS

    use Cache::Escalate;

=head1 DESCRIPTION

Cache::Escalate is ...

=head1 LICENSE

Copyright (C) handlename.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

handlename E<lt>handle@cpan.orgE<gt>

=cut
