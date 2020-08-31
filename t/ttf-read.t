use Test;
use Font::TTF;
plan 1;

my $fh = "t/subset.ttf".IO.open(:r, :bin);

my Font::TTF:D $font .= read($fh);

is $font.num-tables, 10;

done-testing;