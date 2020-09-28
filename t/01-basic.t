use Test;
plan 6;
use Font::TTF::Subset;
use NativeCall;

my $fh = 't/fonts/DejaVuSans.ttf'.IO.open;
my @charset = "Hello, world".ords.unique.sort;

my Font::TTF::Subset $subset .= new: :$fh, :@charset;
is $subset.len, +@charset+1;  # charset + notdef
is $subset.segments, +@charset;
is $subset.charset[1], 32;
is $subset.gids[1], 3;
is $subset.charset[2], 44;
is $subset.gids[2], 15;

done-testing();
