package Genome::Annotation::Filter::WithSampleName;

use strict;
use warnings;
use Genome;
use Memoize qw(memoize);

class Genome::Annotation::Filter::WithSampleName {
    is => 'Genome::Annotation::Filter::Base',
    has => [
        sample_name => {
            is => 'Text',
            is_translated => 1,
        },
    ],
};

sub sample_index {
    my $self = shift;
    my $header = shift;

    return $header->index_for_sample_name($self->sample_name);
}

Memoize::memoize("sample_index");

sub sample_name_with_suffix {
    my $self = shift;
    my $suffix = shift;
    return sprintf("%s-[%s]", $self->sample_name, $suffix);
}

1;

