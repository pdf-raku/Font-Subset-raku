use Test;
plan 82;
use Font::TTF::Subset;
use Font::TTF;
use Font::TTF::Table::CMap::Format12 :GroupIndex;
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

do-subset-tests($ttf, $orig-ttf);

mkdir("tmp");
"tmp/subset.ttf".IO.spurt: $ttf.buf;
$fh = "tmp/subset.ttf".IO.open(:r, :bin);
$ttf .= new: :$fh;

do-subset-tests($ttf, $orig-ttf);

todo "rebuild other tables", 2;
flunk('name');
flunk('kern');

sub do-subset-tests($ttf, $orig-ttf) {
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
    $ttf.glyph-buf(notdef).&is-deeply: $orig-ttf.glyph-buf(o_notdef);
    $ttf.glyph-buf(space).&is-deeply: $orig-ttf.glyph-buf(o_space);
    $ttf.glyph-buf(H).&is-deeply: $orig-ttf.glyph-buf(o_H);
    $ttf.glyph-buf(w).&is-deeply: $orig-ttf.glyph-buf(o_w);

    my $cmap = $ttf.cmap;
    $cmap.elems.&is: 1;
    my $table = $cmap[0];
    $table.object.format.&is: 12;

    my $groups = $table.object.groups;
    $groups[0;startCharCode].&is: 0;
    $groups[0;endCharCode].&is: 0;
    $groups[0;startGlyphCode].&is: +notdef;

    $groups[1;startCharCode].&is: 32;
    $groups[1;endCharCode].&is: 32;
    $groups[1;startGlyphCode].&is: +space;

    $groups[2;startCharCode].&is: ','.ord;
    $groups[2;endCharCode].&is: ','.ord;
    $groups[2;startGlyphCode].&is: +comma;

    $groups[3;startCharCode].&is: 'H'.ord;
    $groups[3;endCharCode].&is: 'H'.ord;
    $groups[3;startGlyphCode].&is: +H;

    $groups[4;startCharCode].&is: 'd'.ord;
    $groups[4;endCharCode].&is: 'e'.ord;
    $groups[4;startGlyphCode].&is: +d;

    $groups[5;startCharCode].&is: 'l'.ord;
    $groups[5;endCharCode].&is:   'l'.ord;
    $groups[5;startGlyphCode].&is: +l;

    todo "rebuild other tables", 3;
}

done-testing();
