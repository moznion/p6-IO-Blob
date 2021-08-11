#!/usr/bin/env raku

use Test;
use IO::Blob;

my $b = $*PROGRAM.parent.add('data/test.csv').slurp(:bin);

my $io = IO::Blob.new($b);

my $count = 0;
while ( defined(my $row = $io.get) ) {
    $count++;
    last if $count > 10;
}

is $count, 10, "got the expected number of rows";

done-testing;
# vim: ft=raku
