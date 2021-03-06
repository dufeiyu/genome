#!/usr/bin/env genome-perl

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use strict;
use warnings;

use above "Genome";
use Test::More;
use Sub::Override;
use Genome::Test::Factory::InstrumentData::Solexa;
use Genome::Test::Factory::InstrumentData::AlignmentResult;
use Cwd qw(abs_path);
use JSON qw(encode_json);

my $pkg = 'Genome::Qc::Tool::Samtools::Flagstat';
use_ok($pkg);

my $data_dir = __FILE__.".d";

use Genome::Qc::Tool;
my $sample_name_override = Sub::Override->new(
    'Genome::Qc::Tool::sample_name',
    sub { return 'TEST-patient1-somval_tumor1'; },
);

my $instrument_data = Genome::Test::Factory::InstrumentData::Solexa->setup_object(
    flow_cell_id => '12345ABXX',
    lane => '2',
    subset_name => '2',
    run_name => 'example',
    id => 'NA12878',
);
my $alignment_result = Genome::Test::Factory::InstrumentData::AlignmentResult->setup_object(
    instrument_data => $instrument_data,
);

my $bam_file = abs_path(File::Spec->join($data_dir, 'speedseq_merged.bam'));

my $config = {
    samtools_flagstat => {
        class => 'Genome::Qc::Tool::Samtools::Flagstat',
        params => {
            'bam-file' => $bam_file,
        },
    }
};

my $qc_config_name = 'testing-qc-run';
my $qc_config_item = Genome::Qc::Config->create(
    name => $qc_config_name,
    type => 'wgs',
    config => encode_json($config),
);

my $command = Genome::Qc::Run->create(
    config_name => $qc_config_name,
    alignment_result => $alignment_result,
    %{Genome::Test::Factory::SoftwareResult::User->setup_user_hash},
);
ok($command->execute, "Command executes ok");

my %tools = $command->output_result->_tools;
my ($tool) = values %tools;
ok($tool->isa($pkg), 'Tool created successfully');

my $output = $tool->qc_metrics_file;
my @expected_cmd_line =(
    'gmt',
    'sam',
    'flagstat',
    sprintf('--output-file=%s', $output),
    sprintf('--bam-file=%s', $bam_file),
);
is_deeply([$tool->cmd_line], [@expected_cmd_line], 'Command line list as expected');

my %expected_metrics = (
    'hq_reads_mapped_in_interchromosomal_pairs' => '4',
    'reads_mapped' => '34',
    'reads_mapped_as_singleton' => '2',
    'reads_mapped_as_singleton_percentage' => '5.56',
    'reads_mapped_in_interchromosomal_pairs' => '4',
    'reads_mapped_in_interchromosomal_pairs_percentage' => '0.125',
    'reads_mapped_in_pair' => '32',
    'reads_mapped_in_proper_pairs' => '28',
    'reads_mapped_in_proper_pairs_percentage' => '77.78',
    'reads_mapped_percentage' => '94.44',
    'reads_marked_as_read1' => '18',
    'reads_marked_as_read2' => '18',
    'reads_marked_duplicates' => '0',
    'reads_marked_failing_qc' => '0',
    'reads_marked_passing_qc' => '36',
    'reads_paired_in_sequencing' => '36',
    'total_reads' => '36',
);
is_deeply({$command->output_result->get_metrics}, {%expected_metrics}, 'Parsed metrics as expected');

done_testing;
