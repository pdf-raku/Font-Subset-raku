use Test;
plan 23;
use Font::TTF::Subset;
use Font::TTF;
use NativeCall;

constant @charset = "Hello, world".ords.unique.sort;
enum SubsetGids <notdef space comma H d e l o r w>;
enum OrigGids (
    :o_notdef(0), :o_space(3), :o_comma(15), :o_H(43), :o_d(71),
    :o_e(72), :o_l(79), :o_o(82), :o_r(85), :o_w(90)
);

my $fh = "t/fonts/Vera.ttf".IO.open(:r, :bin);

my Font::TTF $orig-ttf .= new: :$fh;
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

# compare hmtx against originals
given $orig-ttf.hmtx {
    is $hmtx[notdef].advanceWidth, .[o_notdef].advanceWidth;
    is $hmtx[notdef].leftSideBearing, .[o_notdef].leftSideBearing;

    is $hmtx[space].advanceWidth, .[o_space].advanceWidth;
    is $hmtx[space].leftSideBearing, .[o_space].leftSideBearing;

    is $hmtx[comma].advanceWidth, .[o_comma].advanceWidth;
    is $hmtx[comma].leftSideBearing, .[o_comma].leftSideBearing;

    is $hmtx[H].advanceWidth, .[o_H].advanceWidth;
    is $hmtx[H].leftSideBearing, .[o_H].leftSideBearing;

    is $hmtx[w].advanceWidth, .[o_w].advanceWidth;
    is $hmtx[w].leftSideBearing, .[o_w].leftSideBearing;
}

# spot check copying of glyph buffers
is-deeply $ttf.glyph-buf(notdef), $orig-ttf.glyph-buf(o_notdef);
is-deeply $ttf.glyph-buf(space), $orig-ttf.glyph-buf(o_space);
is-deeply $ttf.glyph-buf(H), $orig-ttf.glyph-buf(o_H);
is-deeply $ttf.glyph-buf(w), $orig-ttf.glyph-buf(o_w);

todo "rebuild other tables", 3;
flunk('cmap');
flunk('name');
flunk('kern');

done-testing();
