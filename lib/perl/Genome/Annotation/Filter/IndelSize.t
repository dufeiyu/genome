#!/usr/bin/env genome-perl

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use strict;
use warnings;

use above "Genome";
use Genome::File::Vcf::Entry;
use Test::More;
use Test::Exception;

my $pkg = "Genome::Annotation::Filter::IndelSize";

subtest "test insertion" => sub {

    my $filter = $pkg->create(
        size => 5,
    );
    lives_ok(sub {$filter->validate}, "Filter validates ok");

    my $entry = create_entry('A', 'AAAAA,AAAAAA');
    ok($entry, 'create entry');

    my %expected_return_values = (
        AAAAA => 0,
        AAAAAA => 1,
    );
    is_deeply({$filter->filter_entry($entry)}, \%expected_return_values, "return values");

};

subtest "test deletion" => sub {

    my $filter = $pkg->create(
        size => 5,
    );
    lives_ok(sub {$filter->validate}, "Filter validates ok");

    my $entry = create_entry('AAAAA', 'A,AAAAAAAAAAA');
    ok($entry, 'create entry');

    my %expected_return_values = (
        A => 0,
        AAAAAAAAAAA => 1,
    );
    is_deeply({$filter->filter_entry($entry)}, \%expected_return_values, "return values");

};

subtest 'validate fails' => sub {

    my $filter = $pkg->create();
    throws_ok( sub{ $filter->validate; }, qr/^Failed to validate/, "failed to validate when size is undef" );

    $filter = $pkg->create(size => 'STRING');
    throws_ok( sub{ $filter->validate; }, qr/^Failed to validate/, "failed to validate when size is a string" );

    $filter = $pkg->create(size => -1);
    throws_ok( sub{ $filter->validate; }, qr/^Failed to validate/, "failed to validate when size is < 0" );

};

done_testing;

###

sub create_vcf_header {
    my $header_txt = <<EOS;
##fileformat=VCFv4.1
##FILTER=<ID=PASS,Description="Passed all filters">
##FILTER=<ID=BAD,Description="This entry is bad and it should feel bad">
##INFO=<ID=A,Number=1,Type=String,Description="Info field A">
##INFO=<ID=C,Number=A,Type=String,Description="Info field C (per-alt)">
##INFO=<ID=E,Number=0,Type=Flag,Description="Info field E">
##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Depth">
##FORMAT=<ID=FT,Number=.,Type=String,Description="Filter">
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	S1	S2	S3	S4
EOS
    my @lines = split("\n", $header_txt);
    my $header = Genome::File::Vcf::Header->create(lines => \@lines);
    return $header
}

sub create_entry {
    my ($ref, $alt) = @_;
    die "Missing REF or ALT!" if not @_ == 2;
    my @fields = (
        '1',            # CHROM
        10,             # POS
        '.',            # ID
        $ref,            # REF
        $alt,           # ALT
        '10.3',         # QUAL
        'PASS',         # FILTER
        'A=B;C=8,9;E',  # INFO
        'GT:DP',        # FORMAT
    );

    my $entry_txt = join("\t", @fields);
    my $entry = Genome::File::Vcf::Entry->new(create_vcf_header(), $entry_txt);
    return $entry;
}

