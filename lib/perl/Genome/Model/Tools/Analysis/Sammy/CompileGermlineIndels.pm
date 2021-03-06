
package Genome::Model::Tools::Analysis::Sammy::CompileGermlineIndels;     # rename this when you give the module file a different name <--

#####################################################################################################################################
# Compilegermline - Call germline variants from normal/tumor BAM files
#					
#	AUTHOR:		Dan Koboldt (dkoboldt@watson.wustl.edu)
#
#	CREATED:	07/28/2009 by D.K.
#	MODIFIED:	07/28/2009 by D.K.
#
#	NOTES:	
#			
#####################################################################################################################################

use strict;
use warnings;

use FileHandle;

use Genome;                                 # using the namespace authorizes Class::Autouse to lazy-load modules under it

class Genome::Model::Tools::Analysis::Sammy::CompileGermlineIndels {
	is => 'Command',                       
	
	has => [                                # specify the command's single-value properties (parameters) <--- 
		output_dir	=> { is => 'Text', doc => "Output directory for germline calls", is_optional => 0 },
		sample_name	=> { is => 'Text', doc => "Sample name for file naming purposes", is_optional => 0 },
		germline_file	=> { is => 'Text', doc => "File name of Sammy-germline indel calls", is_optional => 1 },
		dbsnp_file	=> { is => 'Text', doc => "Tab-delimited file containing known dbSNPs", is_optional => 1 },
		p_value	        => { is => 'Text', doc => "P-value threshold for germline variants [1.0E-06]", is_optional => 1 },
	],
};

sub sub_command_sort_position { 12 }

sub help_brief {                            # keep this to just a few words <---
    "Compiles germline variants from normal and tumor BAM files"                 
}

sub help_synopsis {
    return <<EOS
This command compiles germline variants from Sammy germline calls
EXAMPLE:	gmt analysis sammy
EOS
}

sub help_detail {                           # this is what the user will see with the longer version of help. <---
    return <<EOS 

EOS
}


################################################################################################
# Execute - the main program logic
#
################################################################################################

sub execute {                               # replace with real execution logic.
	my $self = shift;

	## Get required parameters ##

	## Create directory ##
	mkdir($self->output_dir) if(!(-d $self->output_dir));
	my $cmd;
	
	my $p_value = 1.0E-06;
	$p_value = $self->p_value if($self->p_value);
	
	## Determine germline status file ##

	my $germline_status_file = "";
	if($self->germline_file)
	{
		$germline_status_file = $self->germline_file;
	}
	else
	{
		## infer the name of the file ##
		$germline_status_file = $self->output_dir . "/" . $self->sample_name . ".indels.compared.status";
		print "$germline_status_file inferred as germline status file\n";
	}

	my $germline_snp_file = $self->output_dir . "/" . $self->sample_name . ".indels.germline";
	my $num_germline = parse_germline_variants($self, $germline_status_file, $germline_snp_file);

	if($num_germline > 0)
	{
		## Determine dbSNP file ##
		
		my $dbsnp_file = "";
		
		if($self->dbsnp_file)
		{
			$dbsnp_file = $self->dbsnp_file;
		}
		else
		{
			$dbsnp_file = "/gscuser/dkoboldt/SNPseek/SNPseek2/ucsc/snp130.txt.nochrPositions";
		}
	
		## Remove dbSNPs ##
		
		my $germline_non_dbsnp = $self->output_dir . "/" . $self->sample_name . ".indels.germline.not-dbSNP";
		
        my $limit_snps_obj = Genome::Model::Tools::Bowtie::LimitSnps->create(
            positions_file => $dbsnp_file,
            variants_file => $germline_snp_file,
            not_file => $germline_non_dbsnp,
        );
        $limit_snps_obj->execute;

		## Format SNPs for annotation ##
		my $formatted_file = $self->output_dir . "/" . $self->sample_name . ".indels.germline.not-dbSNP.formatted";
		system("perl ~dkoboldt/src/mptrunk/trunk/Auto454/format_snps_for_annotation.pl $germline_non_dbsnp $formatted_file");

		my $num_non_dbsnp = `cat $formatted_file | wc -l`;
		chomp($num_non_dbsnp);
		
		print "$num_non_dbsnp germline non-dbSNP variants formatted for annotation\n";

		print "Running annotation...\n";
		
		my $annotated_file = $formatted_file . ".annotations";
		my $variants_obj = Genome::Model::Tools::Annotate::TranscriptVariants->create(
            variant_file => $formatted_file,
            output_file => $annotated_file,
        );
        $variants_obj->execute;

		print "Merging annotations with SNP calls...\n";
		my $merged_file = $germline_non_dbsnp . ".annotated";
		system("perl ~dkoboldt/src/mptrunk/trunk/Auto454/format_snps_with_annotation.pl $germline_non_dbsnp $annotated_file $merged_file");

	}
	
	return 1;                               # exits 0 for true, exits 1 for false (retval/exit code mapping is overridable)
}



###############################################################################################
# parse_germline_variants - parse out the germline variants from the status file
#
###############################################################################################

sub parse_germline_variants
{
	(my $self, my $infile, my $outfile) = @_;

	my $p_value_threshold = 1.0E-06;
	$p_value_threshold = $self->p_value if($self->p_value);
	
	print "Infile: $infile\nOutfile: $outfile P-value $p_value_threshold\n";

	my $num_germline = 0;
	
	open(OUTFILE, ">$outfile") or die "Can't open outfile $outfile: $!\n";
	
	my $input = new FileHandle ($infile);
	my $lineCounter = 0;
	
	while (<$input>)
	{
		chomp;
		my $line = $_;
		$lineCounter++;		

		if($line)
		{
			my @lineContents = split(/\t/, $line);
			my $chrom = $lineContents[0];
			my $position = $lineContents[1];
			my $allele1 = $lineContents[2];
			my $allele2 = $lineContents[3];
			my $status = $lineContents[12];
			my $p_value = $lineContents[13];

			if($status && $status eq "Germline" && $p_value <= $p_value_threshold)
			{
				print OUTFILE "$line\n";
				print "$chrom\t$position\t$allele1\t$allele2\t$status\t$p_value\n";
				
				$num_germline++;
			}

		}
		
#		return(0) if($lineCounter > 40);
	}

	
	close($input);
	
	close(OUTFILE);
	
	return($num_germline);
}




sub call_sammy
{
	my $classpath = "/gscuser/dkoboldt/Software/Sammy2";
	my $cmd = "java -Xms2000m -Xmx2000m -classpath $classpath Sammy ";
	return($cmd);
}



sub commify
{
	local($_) = shift;
	1 while s/^(-?\d+)(\d{3})/$1,$2/;
	return $_;
}

1;

