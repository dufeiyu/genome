package Genome::TestObjGenerator::Sample;
use base qw(Genome::TestObjGenerator::Base);

use strict;
use warnings;
use Genome;

my @required_params = ('name');

sub generate_obj {
    my $self = shift;
    return Genome::Sample->create(@_);
}

sub create_name {
    return Genome::TestObjGenerator::Util::generate_name('sample_name');
}

sub get_required_params {
    return \@required_params;
}

1;
