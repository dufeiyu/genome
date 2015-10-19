#!/usr/bin/env genome-perl

BEGIN { 
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use strict;
use warnings;

use above "Genome";
use Test::More;

use_ok('Genome::Disk::Command::Group::UnderAllocated') or die;

my $cmd = Genome::Disk::Command::Group::UnderAllocated->create(
    disk_group_names => Genome::Config::get('disk_group_dev'),
);
ok($cmd, 'Created underallocated command object successfully');

my $rv = $cmd->execute;
ok($rv, 'Successfully executed underallocated command');

done_testing();
