#!/usr/bin/env genome-perl

use strict;
use warnings;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
};

use above "Genome";
use File::Temp;
use Test::More;
use Data::Dumper;
use File::Compare;
use File::Slurp;
use Genome::Test::Factory::SoftwareResult::User;

if (Genome::Sys->arch_os ne 'x86_64') {
    plan skip_all => 'requires 64-bit machine';
}
use_ok( 'Genome::Model::Tools::DetectVariants2::Filter::PindelReadSupport');

# This will compare 2 bed files field-by-field, numerically comparing on floats.
# It's necessary so that implementations that produce slightly different floats
# (e.g. 64 bit perl vs 32 bit perl) will still compare equally.
sub compare_files {
    my ($f1, $f2) = @_;

    my @lines1 = read_file($f1);
    my @lines2 = read_file($f2);

    while (1) {
        my $line1 = shift @lines1;
        my $line2 = shift @lines2;
        last unless $line1 && $line2;

        my @fields1 = split "\t", $line1;
        my @fields2 = split "\t", $line2;

        return 1 if scalar @fields1 != scalar @fields2;

        for my $ii (0..$#fields1) {
            my $f1 = $fields1[$ii];
            my $f2 = $fields2[$ii];

            # compare numerically if it's a floating point number
            if ($f1 =~ /^\d\.\d/) {
                return 1 unless $f1 == $f2;
            } else {
                return 1 unless $f1 eq $f2;
            }
        }
    }
    return 0;
}


my $refbuild_id = 101947881;
my $input_directory = Genome::Config::get('test_inputs') . "/Genome-Model-Tools-DetectVariants2-Filter-PindelReadSupport";

my $result_users = Genome::Test::Factory::SoftwareResult::User->setup_user_hash(
    reference_sequence_build_id => $refbuild_id,
);

# Updated to v2 to allow for new columns
my $expected_dir = $input_directory . "/expected_v5/";
my $tumor_bam_file  = $input_directory. '/true_positive_tumor_validation.bam';
my $normal_bam_file  = $input_directory. '/true_positive_normal_validation.bam';
my $test_output_base = File::Temp::tempdir('Genome-Model-Tools-DetectVariants2-Filter-PindelReadSupport-XXXXX', CLEANUP => 1, TMPDIR => 1);
my $test_output_dir = $test_output_base . '/filter';
my $detector_directory = $input_directory."/pindel-somatic-calls-v1-";

my $hq_output_bed = "$test_output_dir/indels.hq.bed";
my $read_support_output_bed = "$test_output_dir/indels.hq.read_support.bed";
my $lq_output_bed = "$test_output_dir/indels.lq.bed";

my $expected_hq_bed_output = "$expected_dir/indels.hq.bed";
my $expected_lq_bed_output = "$expected_dir/indels.lq.bed";
my $expected_read_support_output = "$expected_dir/indels.hq.read_support.bed";

my $detector_result = Genome::Model::Tools::DetectVariants2::Result->__define__(
    output_dir => $detector_directory,
    detector_name => 'test',
    detector_params => '',
    detector_version => 'awesome',
    aligned_reads => $tumor_bam_file,
    control_aligned_reads => $normal_bam_file,
    reference_build_id => $refbuild_id,
);
$detector_result->lookup_hash($detector_result->calculate_lookup_hash());

my $pindel_read_support = Genome::Model::Tools::DetectVariants2::Filter::PindelReadSupport->create(
    previous_result_id => $detector_result->id,
    output_directory => $test_output_dir,
    capture_data => 1,
    result_users => $result_users,
);

ok($pindel_read_support, "created PindelReadSupport object");
ok($pindel_read_support->execute(), "executed PindelReadSupport");
ok(-s $hq_output_bed ,'HQ bed output exists and has size');
ok(-e $lq_output_bed,'LQ bed output exists');
ok(-s $read_support_output_bed,'Read Support bed output exists and has size');
is(compare($hq_output_bed, $expected_hq_bed_output), 0, 'hq bed output matched expected output');
is(compare_files($read_support_output_bed, $expected_read_support_output), 0, 'Read Support bed output matched expected output');
is(compare($lq_output_bed, $expected_lq_bed_output), 0, 'lq bed output matched expected output');

done_testing();
