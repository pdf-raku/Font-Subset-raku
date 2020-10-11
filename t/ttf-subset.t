use Test;
plan 50;
use Font::Subset::TTF;
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
my Font::Subset::TTF $subset .= new: :$fh, :@charset;

my Font::TTF:D $ttf = $subset.ttf;

do-subset-tests($ttf, $orig-ttf);

my $buf = $subset.Buf;
$ttf .= new: :$buf;

do-subset-tests($ttf, $orig-ttf);

do {
    # check that we've defeated FreeType cacheing
    use Font::FreeType;
    my Font::FreeType $ft .= new;
    my $orig-face = $ft.face: $orig-ttf.Blob;
    my $subset-face = $ft.face: $ttf.Blob;

    is $orig-face.num-glyphs, 268;
    is $subset-face.num-glyphs, 10;
}

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

    # compare Horizontal Metrics against originals
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
    $table.object.format.&is: 4;
    $ttf.cmap.pack.&is-deeply: buf8.new(
    # -Header-
    0,0,       # version
    0,1,       # numSubtables
    # -Subtable-
    0,3,       # platformId
    0,1,       # encID
    0,0,0,12,  # offset
    # - CMAP format 4
    0,4,       # format
    0,96,      # length
    0,0,       # language
    0,20,      # segCount X 2
    2,0,       # searchRange
    0,3,       # entrySelector
    254,160,   # rangeShift
    # -endCode-
      0,  0,   0, 32,   0, 44,   0, 72,   0,101,   0,108,   0,111,   0,114,   0,119, 255,255,
      0,  0,   # pad
    # -startCode-
      0,  0,   0, 32,   0, 44,   0, 72,   0,100,   0,108,   0,111,   0,114,   0,119, 255,255,
    #  -delta-
      0,  0, 255,225, 255,214, 255,187, 255,160, 255,154, 255,152, 255,150, 255,146,   0,  1,
    # -offset-
      0,  0,   0,  0,   0,  0,   0,  0,   0,  0,   0,  0,   0,  0,  0,  0,    0,  0,   0,  0,
    );
}

done-testing();
