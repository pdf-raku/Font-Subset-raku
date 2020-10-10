use Test;
plan 58;
use Font::Subset::TTF;
use Font::TTF;
use Font::TTF::Table::CMap::Format12 :GroupIndex;
use NativeCall;

constant @charset = "¹ and ½".ords.unique.sort;
enum SubsetGids <notdef space a d n onesup half fraction twosup>;
enum OrigGids (
    :o_notdef(0), :o_space(3), :o_onesup(240), :o_twosup(241),
    :o_fraction(188), :o_a(68), :o_d(71), :o_n(81), :o_half(244)
);

my $fh = "t/fonts/Vera.ttf".IO.open(:r, :bin);

my Font::TTF $orig-ttf .= new: :$fh;
my Font::Subset::TTF $subset .= new: :$fh, :@charset;
my Font::TTF:D $ttf = $subset.apply;

do-subset-tests($ttf, $orig-ttf);

mkdir("tmp");
"tmp/composites.ttf".IO.spurt: $ttf.buf;
$fh = "tmp/composites.ttf".IO.open(:r, :bin);
$ttf .= new: :$fh;

do-subset-tests($ttf, $orig-ttf);

todo "rebuild other tables", 2;
flunk('name');
flunk('kern');

sub do-subset-tests($ttf, $orig-ttf) {
    my $maxp = $ttf.maxp;
    is $maxp.numGlyphs, 9;

    my $loca = $ttf.loca;
    is $loca.elems, 10;
    is $loca[9], 992;
    my $hhea = $ttf.hhea;
    is $hhea.numOfLongHorMetrics, 9;

    my $hmtx = $ttf.hmtx;
    is $hmtx.elems, 10;
    is $hmtx.num-long-metrics, 9;

    # compare Horizontal Metrics against originals
    given $orig-ttf.hmtx {
        is $hmtx[notdef].advanceWidth, .[o_notdef].advanceWidth;
        is $hmtx[notdef].leftSideBearing, .[o_notdef].leftSideBearing;

        is $hmtx[space].advanceWidth, .[o_space].advanceWidth;
        is $hmtx[space].leftSideBearing, .[o_space].leftSideBearing;

        is $hmtx[onesup].advanceWidth, .[o_onesup].advanceWidth;
        is $hmtx[onesup].leftSideBearing, .[o_onesup].leftSideBearing;

        is $hmtx[twosup].advanceWidth, .[o_twosup].advanceWidth;
        is $hmtx[twosup].leftSideBearing, .[o_twosup].leftSideBearing;

        is $hmtx[fraction].advanceWidth, .[o_fraction].advanceWidth;
        is $hmtx[fraction].leftSideBearing, .[o_fraction].leftSideBearing;

        is $hmtx[a].advanceWidth, .[o_a].advanceWidth;
        is $hmtx[a].leftSideBearing, .[o_a].leftSideBearing;

        is $hmtx[d].advanceWidth, .[o_d].advanceWidth;
        is $hmtx[d].leftSideBearing, .[o_d].leftSideBearing;

        is $hmtx[n].advanceWidth, .[o_n].advanceWidth;
        is $hmtx[n].leftSideBearing, .[o_n].leftSideBearing;

        is $hmtx[half].advanceWidth, .[o_half].advanceWidth;
        is $hmtx[half].leftSideBearing, .[o_half].leftSideBearing;

    }

    # spot check copying of glyph buffers
    $ttf.glyph-buf(notdef).&is-deeply: $orig-ttf.glyph-buf(o_notdef);
    $ttf.glyph-buf(space).&is-deeply: $orig-ttf.glyph-buf(o_space);
    $ttf.glyph-buf(n).&is-deeply: $orig-ttf.glyph-buf(o_n);
    $ttf.glyph-buf(onesup).&is-deeply: $orig-ttf.glyph-buf(o_onesup);

}

done-testing();
