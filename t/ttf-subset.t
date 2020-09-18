use Test;
plan 19;
use Font::TTF::Subset;
use Font::TTF;
use NativeCall;

constant @charset = "Hello, world".ords.unique.sort;
enum SubsetGids <notdef space comma H d e l o r w>;

my $fh = "t/fonts/Vera.ttf".IO.open(:r, :bin);

my Font::TTF::Subset $subset .= new: :$fh, :@charset;
my Font::TTF:D $ttf = $subset.apply;

my $maxp = $ttf.maxp;
is $maxp.numGlyphs, 10;

my $loca = $ttf.loca;
is $loca.elems, 11;
is $loca[10], 1482;

my $hhea = $ttf.hhea;
is $hhea.numOfLongHorMetrics, 10;

my $hmtx = $ttf.hmtx;
is $hmtx.elems, 11;
is $hmtx.num-long-metrics, 10;

is $hmtx[notdef].advanceWidth, 1229;
is $hmtx[notdef].leftSideBearing, 102;

is $hmtx[space].advanceWidth, 651;
is $hmtx[space].leftSideBearing, 0;

is $hmtx[comma].advanceWidth, 651;
is $hmtx[comma].leftSideBearing, 158;

is $hmtx[H].advanceWidth, 1540;
is $hmtx[H].leftSideBearing, 201;

is $hmtx[w].advanceWidth, 1675;
is $hmtx[w].leftSideBearing, 86;


todo "rebuild other tables", 5;

flunk('cmap');
flunk('name');
flunk('kern');

done-testing();
