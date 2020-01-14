package main;

use 5.008001;

use strict;
use warnings;

use Test2::V0;
use Test2::Tools::LoadModule;

load_module_or_skip_all 'Test::Pod::LinkCheck::Lite';

Test::Pod::LinkCheck::Lite->new()->all_pod_files_ok(
    qw{ blib eg },
);

done_testing;

1;

# ex: set textwidth=72 :
