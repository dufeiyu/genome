#!/usr/bin/env genome-perl

BEGIN { 
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use strict;
use warnings;

use above "Genome";
use Test::Exception;
use Test::More;
use Genome::Annotation::BamReadcount::TestHelper qw(bam_readcount_line create_entry);

my $pkg = "Genome::Annotation::BamReadcount::MinVafFilter";
use_ok($pkg);

subtest "pass" => sub {
    my $min_vaf = 90;
    my $filter = $pkg->create(min_vaf => $min_vaf, sample_index => 0);
    lives_ok(sub {$filter->validate}, "Filter validates");

    my $entry = create_entry(bam_readcount_line);
    ok($filter->process_entry($entry), "Entry passes filter with min_vaf $min_vaf");
};

subtest "fail" => sub {
    my $min_vaf = 100;
    my $filter = $pkg->create(min_vaf => $min_vaf, sample_index => 0);
    lives_ok(sub {$filter->validate}, "Filter validates");
    my $entry = create_entry(bam_readcount_line);
    ok(!$filter->process_entry($entry), "Entry fails filter with min_vaf $min_vaf");
};

subtest "fail heterozygous non-reference sample" => sub {
    my $min_vaf = 90;
    my $filter = $pkg->create(min_vaf => $min_vaf, sample_index => 1);
    lives_ok(sub {$filter->validate}, "Filter validates");
    my $entry = create_entry(bam_readcount_line);
    ok(!$filter->process_entry($entry), "Entry fails filter with min_vaf $min_vaf");
    cmp_ok($filter->calculate_vaf($entry, 'C'), '<', 0.3, "VAF is very low");
};

done_testing;
