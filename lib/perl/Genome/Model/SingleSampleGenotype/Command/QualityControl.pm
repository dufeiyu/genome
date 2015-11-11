package Genome::Model::SingleSampleGenotype::Command::QualityControl;

use strict;
use warnings;

use Genome;

class Genome::Model::SingleSampleGenotype::Command::QualityControl {
    is => 'Genome::Model::SingleSampleGenotype::Command::Base',
    doc => 'Perform quality control analysis on the alignments for the build.',
};

sub _result_accessor {
    return 'output_result';
}

sub _command_class {
    return 'Genome::Qc::Run';
}

sub _params_for_command {
    my $self = shift;
    my $build = $self->build;

    my $result_users = Genome::SoftwareResult::User->user_hash_for_build($build);

    my @params = (
        alignment_result => $build->merged_alignment_result,
        config_name => $build->model->qc_config,
        result_users => $result_users,
    );

    return @params;
}

sub _label_for_result {
    return 'qc_result';
}

1;