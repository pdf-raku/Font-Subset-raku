use Test;
plan 6;
use Font::TTF::Subset;
use NativeCall;

my $fh = 't/fonts/DejaVuSans.ttf'.IO.open;
my @charset = "Hello, world".ords.unique.sort;
# segments 1:notdef 2:space 3:comma 4:h 5:d,e 6:l 7:o 8:r 9:w
constant segment-count = 9;

my Font::TTF::Subset $subset .= new: :$fh, :@charset;
# charset + notdef
is $subset.len, +@charset+1;  # charset + notdef
is $subset.segments, segment-count;
is $subset.charset[1], 32;
is $subset.gids[1], 3;
is $subset.charset[2], 44;
is $subset.gids[2], 15;

done-testing();
