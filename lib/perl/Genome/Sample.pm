package Genome::Sample;

use strict;
use warnings;

use Genome;
use Genome::Info::TCGASpecialSampleNamingConversion;

my $default_nomenclature = Genome::Config::get('nomenclature_default');

class Genome::Sample {
    is => 'Genome::Subject',
    roles => ['Genome::Role::ObjectWithLockedConstruction', 'Genome::Role::Searchable'],
    has => [
        sample_id => {
            is => 'Text',
            calculate_from => 'subject_id',
            calculate => q{ return $subject_id },
        },
        subject_type => {
            is_constant => 1,
            is_classwide => 1,
            value => 'sample_name'
        },
    ],
    has_optional => [
        common_name => {
            is => 'Text',
            via => 'attributes',
            to => 'attribute_value',
            where => [ attribute_label => 'common_name', nomenclature => $default_nomenclature ],
            is_mutable => 1,
            doc => 'Typically tumor, normal, etc. A very brief description of the sample',
        },
        individual_common_name => {
            is => 'Text',
            via => 'source',
            to => 'common_name',
            doc => 'AML45, BRC1, etc'
        },
        extraction_label => {
            is => 'Text',
            via => 'attributes',
            to => 'attribute_value',
            where => [ attribute_label => 'extraction_label', nomenclature => $default_nomenclature ],
            is_mutable => 1,
            doc => 'Identifies the specimen sent from the laboratory which extracted DNA/RNA',
        },
        extraction_type => {
            is => 'Text',
            via => 'attributes',
            to => 'attribute_value',
            where => [ attribute_label => 'extraction_type', nomenclature => $default_nomenclature ],
            is_mutable => 1,
            doc => 'Either "genomic dna" or "rna" in most cases',
        },
        sample_type => {
            is => 'Text',
            via => '__self__',
            to => 'extraction_type',
        },
        is_rna => {
            calculate_from => [qw/ extraction_type /],
            calculate => q|
                return if not defined $extraction_type;
                for my $rna_sample_type ( 'rna', 'cdna', 'total rna', 'cdna library', 'mrna', 'pooled rna' ) {
                    return 1 if $extraction_type eq $rna_sample_type;
                }
                return;
            |,
        },
        extraction_desc => {
            is => 'Text',
            via => 'attributes',
            to => 'attribute_value',
            where => [ attribute_label => 'extraction_desc', nomenclature => $default_nomenclature ],
            is_mutable => 1,
            doc => 'Notes specified when the specimen entered this site',
        },
        tissue_label => {
            is => 'Text',
            via => 'attributes',
            to => 'attribute_value',
            where => [ attribute_label => 'tissue_label', nomenclature => $default_nomenclature ],
            is_mutable => 1,
            doc => 'Identifies/labels the original tissue sample from which this extraction was made'
        },
        tissue_desc => {
            is => 'Text',
            via => 'attributes',
            to => 'attribute_value',
            where => [ attribute_label => 'tissue_desc', nomenclature => $default_nomenclature ],
            is_mutable => 1,
            doc => 'Describes the original tissue sample',
        },
        organ_name => {
            is => 'Text',
            via => 'attributes',
            to => 'attribute_value',
            where => [ attribute_label => 'organ_name', nomenclature => $default_nomenclature ],
            is_mutable => 1,
            doc => 'The name of the organ from which the sample was taken'
        },
        disease => {
            is => 'Text',
            via => 'attributes',
            to => 'attribute_value',
            where => [ attribute_label => 'disease', nomenclature => $default_nomenclature ],
            is_mutable => 1,
            doc => 'The name of the disease if present in the sample.',
        },
        default_genotype_data_id => {
            is => 'Number',
            via => 'attributes',
            to => 'attribute_value',
            where => [ attribute_label => 'default_genotype_data', nomenclature => $default_nomenclature ],
            is_mutable => 1,
            doc => 'ID of genotype microarray data associated with this sample',
        },
        default_genotype_data => {
            is => 'Genome::InstrumentData::Imported',
            id_by => 'default_genotype_data_id',
            doc => 'Genotype microarray instrument data object',
        },
        source_id => {
            is => 'Number',
            via => 'attributes',
            to => 'attribute_value',
            where => [ attribute_label => 'source_id', nomenclature => $default_nomenclature ],
            is_mutable => 1,
            doc => 'ID of the source of this sample, either a Genome::Individual or Genome::PopulationGroup',
        },
        source => {
            is => 'Genome::SampleSource',
            id_by => 'source_id',
            doc => 'The patient/individual organism or group from which the sample was taken, or the population for pooled samples.',
        },
        source_type => {
            is => 'Text',
            calculate_from => 'source',
            calculate => q{
                return unless $source;
                return $source->subject_type;
            },
            doc => 'Plain text type of the sample source',
        },
        source_name => {
            via => 'source',
            to => 'name',
            doc => 'Name of the sample source',
        },
        source_common_name => {
            via => 'source',
            to => 'common_name',
            doc => 'Common name of the sample source',
        },
        individual => {
            is => 'Genome::Individual',
            id_by => 'source_id',
            doc => 'The individual (previously patient) organism from which the sample was taken.'
        },
        individual_name => {
            via => 'individual',
            to => 'name',
            doc => 'The system name for an individual (often a substring of the sample name)'
        },
        individual_common_name => {
            via => 'individual',
            to => 'common_name',
            doc => 'Common name of the individual, eg AML1',
        },
        age => {
            is => 'Number',
            via => 'attributes',
            to => 'attribute_value',
            where => [ attribute_label => 'age' ],
            is_mutable => 1,
            doc => 'Age of the patient at the time of sample taking.',
        },
        body_mass_index => {
            is => 'Text',
            via => 'attributes',
            to => 'attribute_value',
            where => [ attribute_label => 'body_mass_index' ],
            is_mutable => 1,
            doc => 'BMI of the patient at the time of sample taking.',
        },
        tcga_name => {
            via => 'attributes',
            to => 'attribute_value',
            where => [ 'nomenclature like' => 'TCGA%', attribute_label => 'biospecimen_barcode_side'],
            is_mutable => 1,
            doc => 'TCGA name of the sample, if available',
        },
        timepoint => {
            is => 'Text',
            via => 'attributes',
            to => 'attribute_value',
            where => [ attribute_label => 'timepoint' ],
            is_mutable => 1,
            doc => 'Point in time at which this sample was taken',
        },
        taxon => {
            is => 'Genome::Taxon',
            via => 'source',
            to => 'taxon',
            doc => 'Taxon for this sample via the source.',
        },
        taxon_id => {
            is => 'Number',
            via => 'source',
            to => 'taxon_id',
            doc => 'Taxon id for this sample via the source.',
        },
        species_name => {
            via => 'taxon',
            to =>  'name',
            doc => 'Name of the species of the sample source\'s taxonomic category'
        },
        sub_type => {
            calculate_from => ['_sub_type1','_sub_type2'],
            calculate => q|$_sub_type1 or $_sub_type2|
        },
        _sub_type1 => {
            via => 'attributes',
            to => 'attribute_value',
            where => [ attribute_label => 'sub-type' ],
            is_mutable => 1,
        },
        _sub_type2 => {
            via => 'attributes',
            to => 'attribute_value',
            where => [ attribute_label => 'subtype' ],
            is_mutable => 1,
        },
    ],
    has_many_optional => [
        models => {
            is => 'Genome::Model',
            reverse_as => 'subject',
            doc => 'Models that use this sample',
        },
        libraries => {
            is => 'Genome::Library',
            reverse_as => 'sample',
            is_many => 1,
            doc => 'Libraries that were created from the sample',
        },
        instrument_data => {
            is => 'Genome::InstrumentData',
            via => 'libraries',
            is_many => 1,
            doc => 'Instrument data from all DNA libraries from this sample',
        },
    ],
    doc => 'A single specimen of DNA or RNA extracted from some tissue sample',
};

sub sample_name_to_name_in_vcf {
    my $class = shift;
    my $sample_name = shift;
    my $sample = Genome::Sample->get(name => $sample_name);
    if ($sample) {
        return $sample->name_in_vcf;
    }
    return $sample_name;
}

sub name_in_vcf {
    my $self = shift;
    my $sample_tcga_name = $self->extraction_label;

    unless ($sample_tcga_name and $sample_tcga_name =~ /^TCGA\-/) {
        $sample_tcga_name = $self->name;
        my @tcga_names = $self->get_tcga_names;
        if (@tcga_names == 1) {
            $sample_tcga_name = shift @tcga_names;
        }
        else {
            my %conversion = Genome::Info::TCGASpecialSampleNamingConversion->tcga_naming_conversion;
            $sample_tcga_name = $conversion{$sample_tcga_name} if $conversion{$sample_tcga_name};
        }
    }

    if ($sample_tcga_name =~ /^TCGA\-/) {
        $self->debug_message("Found TCGA name: %s for sample: %s", $sample_tcga_name, $self->name);
    }
    return $sample_tcga_name;
}

sub get_tcga_names {
    my $self = shift;
    
    my %tcga_names;
    my $extraction_label = $self->extraction_label;
    if ($extraction_label and $extraction_label =~ /^TCGA\-/) {
        $tcga_names{$extraction_label}++;
    }

    my @sample_attributes = $self->attributes(attribute_label => 'external_name');
    if (@sample_attributes) {
        for my $attr (@sample_attributes) {
            my $sample_tcga_name = $attr->attribute_value;

            if ($sample_tcga_name and $sample_tcga_name =~ /^TCGA\-/) {
                $tcga_names{$sample_tcga_name}++;
            }
        }
    }

    return sort keys %tcga_names;
}

sub resolve_tcga_patient_id {
    my $self = shift;
    my @tcga_names = $self->get_tcga_names;
    return unless @tcga_names;
    
    my %patient_ids;
    for my $tcga_name (@tcga_names) {
        my ($patient_id) = $tcga_name =~ /^(TCGA\-\w{2}\-\w{4})\-/;
        $patient_ids{$patient_id}++ if $patient_id;
    }
    my @patient_ids = keys %patient_ids;
    return $patient_ids[0] if @patient_ids == 1;
    my $patient_ids = join ',', @patient_ids;
    $self->fatal_message("Multiple patient ids: %s found for sample %s", $patient_ids, $self->name);
}

sub get_source {
    my $self = shift;
    return $self->source;
}

sub __display_name__ {
    my $self = $_[0];
    return $self->name . ' (' . (($self->source && $self->source->common_name) ? $self->source->common_name . ($self->common_name ? ' ' . $self->common_name  : '') . ' ' : '') . $self->id . ')';
}

sub check_genotype_data {
    my $self = shift;
    my $genotype_instrument_data = shift;

    Carp::confess $self->error_message("No genotype instrument data provided.")
        unless $genotype_instrument_data;

    Carp::confess $self->error_message("Genotype instrument data is not a Genome::InstrumentData::Imported object.")
        unless $genotype_instrument_data->isa('Genome::InstrumentData::Imported');

    Carp::confess $self->error_message("Instrument data is not a 'genotype file' format.")
       unless $genotype_instrument_data->import_format && $genotype_instrument_data->import_format eq 'genotype file';

    my $genotype_sample = $genotype_instrument_data->sample;
    my $genotype_source = $genotype_sample->source;
    unless ($self->source->class eq $genotype_source->class and $self->source->id eq $genotype_source->id) {
        Carp::confess $self->error_message("Genotype instrument data has source " . $genotype_source->__display_name__ .
            " but sample has source " . $self->source->__display_name__);
    }

    return 1;
}

sub set_default_genotype_data {
    my ($self, $genotype_data_id, $allow_overwrite) = @_;
    $allow_overwrite ||= 0;
    Carp::confess 'Not given genotype instrument data to assign to sample ' . $self->id unless $genotype_data_id;

    unless ($genotype_data_id eq 'none') {
        my $genotype_instrument_data = Genome::InstrumentData::Imported->get($genotype_data_id);
        Carp::confess "Could not find any instrument data with id $genotype_data_id!" unless $genotype_instrument_data;
        Carp::confess "Genotype instrument data $genotype_data_id is not valid!"
            unless $self->check_genotype_data($genotype_instrument_data);
    }

    if (defined $self->default_genotype_data_id) {
        return 1 if $self->default_genotype_data_id eq $genotype_data_id;
        unless ($allow_overwrite) {
            Carp::confess "Attempted to overwrite current genotype instrument data id " . $self->default_genotype_data_id .
                " for sample " . $self->id . " with genotype data id $genotype_data_id " .
                " without setting the overwrite flag!";
        }
    }

    $self->default_genotype_data_id($genotype_data_id);

    my @genotype_models = $self->default_genotype_models;
    unless (@genotype_models) {
        $self->warning_message("Found no default genotype models using sample " . $self->__display_name__);
    }
    else {
        for my $genotype_model ($self->default_genotype_models) {
            $genotype_model->request_builds_for_dependent_cron_ref_align;
            $self->status_message("Requested builds for reference alignment models dependent on genotype model " . $genotype_model->id);
        }
    }

    return 1;
}

sub default_genotype_models {
    my $self = shift;

    my $genotype_data_id = $self->default_genotype_data_id;
    return unless defined $genotype_data_id;
    return if $genotype_data_id eq 'none';

    my $genotype_data = $self->default_genotype_data;
    return unless $genotype_data;

    my @inputs = Genome::Model::Input->get(
        value_class_name => $genotype_data->class,
        value_id => $genotype_data->id,
        name => 'instrument_data',
    );
    my @models = map { $_->model } @inputs;
    @models = grep { $_->subclass_name eq 'Genome::Model::GenotypeMicroarray' } @models;

    return @models;
}

sub delete {
    my $self = shift;

    for my $library ( $self->libraries ) {
        $library->delete;
    }

    Genome::SoftwareResult->expunge_results_containing_object($self, 'deleting sample ' . $self->id);

    return $self->SUPER::delete;
}

sub lock_id {
    my $class = shift;
    my %args = @_;
    return $args{name};
}

1;

