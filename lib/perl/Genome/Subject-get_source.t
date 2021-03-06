#!/usr/bin/env genome-perl

BEGIN { 
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use strict;
use warnings;

use above "Genome";
use Test::More;

use_ok('Genome::Subject') or die;
use_ok('Genome::Sample') or die;
use_ok('Genome::Individual') or die;
use_ok('Genome::PopulationGroup') or die;
use_ok('Genome::Taxon') or die;

### Set up test objects and their relationships with each other

my $taxon = Genome::Taxon->create(
    domain => 'eukaryota',
    name => 'test',
);
ok($taxon, 'created test taxon');

my $individual = Genome::Individual->create(
    taxon => $taxon,
    name => 'test critter',
);
ok($individual, 'created test individual');

my $pop_group = Genome::PopulationGroup->create(
    taxon => $taxon,
    name => 'test critters',
);
ok($pop_group, 'created test population group');

my $sample = Genome::Sample->create(
    name => 'test sample',
    source => $individual,
);
ok($sample, 'created test sample');

### Test relationships

is($taxon->get_source, undef, 'taxon has no source, as expected');

my $individual_source = $individual->get_source;
ok($individual_source, 'individual has a source');
is($individual_source->class, 'Genome::Taxon', 'individual\'s source is a taxon, as expected');
is($individual_source->id, $taxon->id, 'individual\'s source id matches test taxon');

my $pop_group_source = $pop_group->get_source;
ok($pop_group_source, 'got source for population group');
is($pop_group_source->class, 'Genome::Taxon', 'population group has a taxon as a source');
is($pop_group_source->id, $taxon->id, 'population group source id matches test taxon');

my $sample_source = $sample->get_source;
ok($sample_source, 'sample has a source');
is($sample_source->class, 'Genome::Individual', 'sample source is an indvidiaul');
is($sample_source->id, $individual->id, 'sample source id matches test individual');

### Now test get_source_with_class

$individual_source = $individual->get_source_with_class('Genome::Taxon');
ok($individual_source, 'individual has a source with type Genome::Taxon');
is($individual_source->class, 'Genome::Taxon', 'individual\'s source is a taxon, as expected');
is($individual_source->id, $taxon->id, 'individual\'s source id matches test taxon');

$pop_group_source = $pop_group->get_source_with_class('Genome::Taxon');
ok($pop_group_source, 'got source for population group with type Genome::Taxon');
is($pop_group_source->class, 'Genome::Taxon', 'population group has a taxon as a source');
is($pop_group_source->id, $taxon->id, 'population group source id matches test taxon');

$sample_source = $sample->get_source_with_class('Genome::Taxon');
ok($sample_source, 'got source for sample with type Genome::Taxon');
is($sample_source->class, 'Genome::Taxon', 'sample has a taxon as a source');
is($sample_source->id, $taxon->id, 'sampel source id matches test taxon');

done_testing();
