unit class Font::TTF::Subset:ver<0.0.1>;

use Font::TTF;
use Font::TTF::Table::HoriHeader;
use Font::TTF::Table::HoriMetrics;
use Font::TTF::Subset::Raw;
use Font::FreeType;
use Font::FreeType::Face;
use Font::FreeType::Raw::Defs;
use NativeCall;

my Font::FreeType $freetype;
has IO::Handle $.fh is required;
has Font::TTF:D $.ttf .= new: :$!fh;
has Font::FreeType::Face $.face = do {
    $_ .= new without $freetype;
    $freetype.face($!fh);
}

has fontSubset $.raw handles<len charset gids>;

submethod TWEAK(List:D :$charset!) {
    my CArray[FT_ULong] $codes .= new: $charset.list;
    $!raw = fontSubset::create($!face.raw, $codes, $codes.elems);
}

submethod DESTROY {
    .done with $!raw;
}

# rebuild the glyphs index ('loca') and the glyphs buffer ('glyf')
method !subset-glyph-tables(Font::TTF $ttf) {

    my Font::TTF::Table::GlyphIndex:D $index = $ttf.loca;
    my buf8 $glyphs-buf = $ttf.buf('glyf');

    my $bytes = $!raw.subset-glyphs($index.offsets, $glyphs-buf);

    $glyphs-buf.reallocate($bytes);
    $index.num-glyphs = self.len;

    $ttf.upd($index);
    $ttf.upd($glyphs-buf, :tag<glyf>)
}

method !subset-hmtx(
    buf8 $hmtx-buf,
    Font::TTF::Table::HoriHeader:D :$hhea!,
) {
    # todo: rewrite in C
    my $num-long-metrics = $hhea.numOfLongHorMetrics;
    my $ss-num-long-metrics = 0;
    my $ss-num-glyphs = $.len;
    my $gid-map := $.gids;

    for 0 ..^ $ss-num-glyphs -> $ss-gid {
        my $gid = $gid-map[$ss-gid];
        if $gid >= $num-long-metrics {
            # repack short metric
            my $from-offset := 2 * $num-long-metrics + 2 * $gid;
            my $to-offset := 2 * $ss-num-long-metrics + 2 * $ss-gid;
            $hmtx-buf.subbuf-rw($to-offset, 2) = $hmtx-buf.subbuf($from-offset, 2)
            unless $from-offset == $to-offset;
        }
        else {
            # repack long metric
            my $from-offset := 4 * $gid;
            my $to-offset := 4 * $ss-gid;
            $ss-num-long-metrics++;
            $hmtx-buf.subbuf-rw($to-offset, 4) = $hmtx-buf.subbuf($from-offset, 4)
            unless $from-offset == $to-offset;
        }
    }
    $hmtx-buf.reallocate($ss-num-glyphs * 2  +  $ss-num-long-metrics * 2);
    $ss-num-long-metrics;
}

# rebuild horizontal metrics
method !subset-hori-tables(Font::TTF:D $ttf) {
    with $ttf.hhea -> Font::TTF::Table::HoriHeader $hhea {
        with $ttf.buf('hmtx') -> buf8 $htmx-buf {
            $hhea.numOfLongHorMetrics  = self!subset-hmtx($htmx-buf, :$hhea);
            $ttf.upd($htmx-buf, :tag<hmtx>);
            $ttf.upd($hhea);
        }
    }
}

method apply(Font::TTF::Subset:D:) {
    my Font::TTF::Table::Header:D $head = $!ttf.head;
    my Font::TTF::Table::MaxProfile:D $maxp = $!ttf.maxp;

    self!subset-glyph-tables($!ttf);
    self!subset-hori-tables($!ttf);

    my $num-glyphs := self.len;
    $!ttf.upd($maxp).numGlyphs = $num-glyphs;
    $!ttf
}

