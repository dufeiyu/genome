#!/usr/bin/env genome-perl

use strict;
use warnings FATAL => 'all';

use Test::More;
use above 'Genome';

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
};

my $pkg = 'Genome::VariantReporting::Framework::Component::Expert::Command';
use_ok($pkg) || die;

{
    package Genome::VariantReporting::Framework::Component::Expert::TestCommand;

    class Genome::VariantReporting::Framework::Component::Expert::TestCommand {
        is => $pkg,
    };
}
my $obj = Genome::VariantReporting::Framework::Component::Expert::TestCommand->create(
    input_vcf => __FILE__,
    variant_type => 'snvs',
);

my %input_hash = $obj->input_hash;
is($input_hash{'input_vcf'}, __FILE__, 'input_vcf entry is as expected');
ok(exists($input_hash{'input_vcf_lookup_md5'}) && ($input_hash{'input_vcf_lookup_md5'} ne $input_hash{'input_vcf'}),
    'input_vcf_lookup_md5 entry exists and is not the same as input_vcf');
is($input_hash{'variant_type'}, 'snvs', 'variant_type entry is as expected');
ok(!exists $input_hash{'variant_type_lookup_md5'}, 'variant_type_lookup_md5 entry absent as expected');

done_testing();
