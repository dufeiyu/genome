use strict;
use warnings;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT}               = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use above 'Genome';

use Genome::Test::Factory::Model::ReferenceSequence;
use Genome::Test::Factory::SoftwareResult::User;

use Test::More;

my $pkg = 'Genome::Model::Tools::Speedseq::ConfigFile';
use_ok($pkg);

my $speedseq_version = '0.1.0-gms';

my $test_dir = __FILE__.'.d';

my $reference_fasta_path = File::Spec->join($test_dir,'all_sequences.fa');
my $reference_fasta_absolute_path = File::Spec->rel2abs($reference_fasta_path);

my $reference_build = Genome::Test::Factory::Model::ReferenceSequence->setup_reference_sequence_build(
   data_directory => Genome::Sys->create_temp_directory,
);
my $override = Sub::Override->new(
    'Genome::Model::Build::ReferenceSequence::full_consensus_path',
    sub { return $reference_fasta_absolute_path; }
);

my $result_user = Genome::Test::Factory::SoftwareResult::User->setup_user_hash(
   reference_sequence_build_id => $reference_build->id
);

my $sr = $pkg->get_or_create(
   reference_sequence_build => $reference_build,
   speedseq_version => $speedseq_version,
   users => $result_user,
);

ok($sr,'got the expected software result');     

done_testing();
