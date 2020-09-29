unit class Font::TTF::Subset:ver<0.0.1>;

use Font::TTF;
use Font::TTF::Table::CMap;
use Font::TTF::Table::CMap::Format12 :GroupIndex;
use Font::TTF::Table::HoriHeader;
use Font::TTF::Table::HoriMetrics;
use Font::TTF::Table::VertHeader;
use Font::TTF::Table::VertMetrics;
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

has fontSubset $.raw handles<len charset gids segments>;

submethod TWEAK(List:D :$charset!) {
    my CArray[FT_ULong] $codes .= new: $charset.list;
    $!raw = fontSubset::create($!face.raw, $codes, $codes.elems);
}

submethod DESTROY {
    .done with $!raw;
}

# rebuild the glyphs index ('loca') and the glyphs buffer ('glyf')
method !subset-glyph-tables {

    my Font::TTF::Table::GlyphIndex:D $index = $!ttf.loca;
    my buf8 $glyphs-buf = $!ttf.buf('glyf');

    my $glyph-bytes := $!raw.subset-glyphs($index.offsets, $glyphs-buf);

    $glyphs-buf.reallocate($glyph-bytes);
    $index.num-glyphs = self.len;

    $!ttf.upd($index);
    $!ttf.upd($glyphs-buf, :tag<glyf>)
}

method !subset-mtx(
    buf8 $mtx-buf, $num-long-metrics
) {
    # todo: rewrite in C
    my $ss-num-long-metrics = 0;
    my $ss-num-glyphs = $.len;
    my $gid-map := $.gids;

    for 0 ..^ $ss-num-glyphs -> $ss-gid {
        my $gid = $gid-map[$ss-gid];
        if $gid >= $num-long-metrics {
            # repack short metric
            my $from-offset := 2 * $num-long-metrics + 2 * $gid;
            my $to-offset := 2 * $ss-num-long-metrics + 2 * $ss-gid;
            $mtx-buf.subbuf-rw($to-offset, 2) = $mtx-buf.subbuf($from-offset, 2)
            unless $from-offset == $to-offset;
        }
        else {
            # repack long metric
            my $from-offset := 4 * $gid;
            my $to-offset := 4 * $ss-gid;
            $ss-num-long-metrics++;
            $mtx-buf.subbuf-rw($to-offset, 4) = $mtx-buf.subbuf($from-offset, 4)
            unless $from-offset == $to-offset;
        }
    }
    $mtx-buf.reallocate($ss-num-glyphs * 2  +  $ss-num-long-metrics * 2);
    $ss-num-long-metrics;
}

# rebuild horizontal metrics
method !subset-hori-tables {
    with $!ttf.hhea -> Font::TTF::Table::HoriHeader $hhea {
        with $!ttf.buf('hmtx') -> buf8 $htmx-buf {
            $hhea.numOfLongHorMetrics = self!subset-mtx($htmx-buf, $hhea.numOfLongHorMetrics);
            $!ttf.upd($htmx-buf, :tag<hmtx>);
            $!ttf.upd($hhea);
        }
    }
}

# rebuild vertzontal metrics
method !subset-vert-tables {
    with $!ttf.vhea -> Font::TTF::Table::VertHeader $vhea {
        with $!ttf.buf('vmtx') -> buf8 $vmtx-buf {
            $vhea.numOfLongVerMetrics = self!subset-mtx($vmtx-buf, $vhea.numOfLongVerMetrics);
            $!ttf.upd($vmtx-buf, :tag<vmtx>);
            $!ttf.upd($vhea);
        }
    }
}

method !subset-cmap {
    my uint32 @groups[$.segments;3];
    my Int:D $last-ord := -2;
    my Int:D $seg = -1;

    for 0 ..^ $.len {
        my $ord := $.charset[$_];
        my $gid := $.gids[$_];
        if $ord != $last-ord + 1 {
            $seg++;
            @groups[$seg;startCharCode] = $ord;
            @groups[$seg;startGlyphCode] = $_;
        }
        @groups[$seg;endCharCode] = $ord;
        $last-ord := $ord;
    }

    my Font::TTF::Table::CMap::Format12 $format .= new: :@groups;
    my Font::TTF::Table::CMap $cmap .= new: :$format;
    $!ttf.upd($cmap);
}

method apply(Font::TTF::Subset:D:) {
    my Font::TTF::Table::Header:D $head = $!ttf.head;
    my Font::TTF::Table::MaxProfile:D $maxp = $!ttf.maxp;

    self!subset-glyph-tables();
    self!subset-hori-tables();
    self!subset-vert-tables();
    self!subset-cmap();

    my $num-glyphs := self.len;
    $!ttf.upd($maxp).numGlyphs = $num-glyphs;
    $!ttf
}
