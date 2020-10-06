unit class Font::TTF::Subset:ver<0.0.1>;

use Font::TTF;
use Font::TTF::Table::CMap;
use Font::TTF::Table::CMap::Format0;
use Font::TTF::Table::CMap::Format4;
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
    my $load-flags := FT_LOAD_NO_RECURSE;
    $_ .= new(:$load-flags) without $freetype;
    $freetype.face($!fh, );
}

has fontSubset $.raw handles<charset gids charset-len gids-len>;
has uint16 @!index;
has UInt $.segments is built;

method !count-segments {
    my $segs = 1;
    my $last-gid := @!index[0];

    for 1 ..^ $!raw.charset-len {
        my $gid := @!index[$_];
        $segs++
            unless $gid == $last-gid + 1
            && $!raw.charset[$gid] == $!raw.charset[$last-gid] + 1;
        $last-gid := $gid;
    }
    $segs;
}

submethod TWEAK(:@charset!) {
    my CArray[FT_ULong] $codes .= new: @charset.unique;
    $!raw = fontSubset::create($!face.raw, $codes, $codes.elems);
    @!index = (0 ..^ $!raw.charset-len).sort({$!raw.charset[$_]});
    $!segments = self!count-segments();
}

submethod DESTROY {
    .done with $!raw;
}

# rebuild the glyphs index ('loca') and the glyphs buffer ('glyf')
method !subset-glyf-table {
    my Font::TTF::Table::GlyphIndex:D $index = $!ttf.loca;
    my buf8 $glyphs-buf = $!ttf.buf('glyf');

    my $glyph-bytes := $!raw.subset-glyphs($index.offsets, $glyphs-buf);

    $glyphs-buf.reallocate($glyph-bytes);
    $index.num-glyphs = self.gids-len;

    $!ttf.upd($index);
    $!ttf.upd($glyphs-buf, :tag<glyf>)
}

method !subset-mtx(
    buf8 $mtx-buf, $num-long-metrics
) {
    # todo: rewrite in C
    my $new-num-long-metrics = 0;
    my $new-num-glyphs = $.gids-len;
    my $old-gids := $.gids;

    for 0 ..^ $new-num-glyphs -> $new-gid {
        my $old-gid = $old-gids[$new-gid];
        if $old-gid >= $num-long-metrics {
            # repack short metric
            my $from-offset := 2 * $num-long-metrics + 2 * $old-gid;
            my $to-offset := 2 * $new-num-long-metrics + 2 * $new-gid;
            $mtx-buf.subbuf-rw($to-offset, 2) = $mtx-buf.subbuf($from-offset, 2)
                unless $from-offset == $to-offset;
        }
        else {
            # repack long metric
            my $from-offset := 4 * $old-gid;
            my $to-offset := 4 * $new-gid;
            $new-num-long-metrics++;
            $mtx-buf.subbuf-rw($to-offset, 4) = $mtx-buf.subbuf($from-offset, 4)
                unless $from-offset == $to-offset;
        }
    }
    $mtx-buf.reallocate($new-num-glyphs * 2  +  $new-num-long-metrics * 2);
    $new-num-long-metrics;
}

# rebuild horizontal metrics
method !subset-hmtx-table {
    with $!ttf.hhea -> Font::TTF::Table::HoriHeader $hhea {
        with $!ttf.buf('hmtx') -> buf8 $htmx-buf {
            $hhea.numOfLongHorMetrics = self!subset-mtx($htmx-buf, $hhea.numOfLongHorMetrics);
            $!ttf.upd($htmx-buf, :tag<hmtx>);
            $!ttf.upd($hhea);
        }
    }
}

# rebuild vertical metrics
method !subset-vmtx-table {
    with $!ttf.vhea -> Font::TTF::Table::VertHeader $vhea {
        with $!ttf.buf('vmtx') -> buf8 $vmtx-buf {
            $vhea.numOfLongVerMetrics = self!subset-mtx($vmtx-buf, $vhea.numOfLongVerMetrics);
            $!ttf.upd($vmtx-buf, :tag<vmtx>);
            $!ttf.upd($vhea);
        }
    }
}

method !subset-cmap-format0 {
    my uint8 @glyphIndexArray[255];

    for 0 ..^ $.charset-len {
        my $ord := $.charset[$_];
        last if $ord > 255 || $_ > 255;
        @glyphIndexArray[$_] = $ord;
    }

    Font::TTF::Table::CMap::Format0.new: :@glyphIndexArray;
}

method !subset-cmap-format4 {
    my $segCount = $!segments + 1;
    my uint16 @startCode[$segCount];
    my uint16 @endCode[$segCount];
    my uint16 @idDelta[$segCount];
    my uint16 @idRangeOffset[$segCount];
    my uint16 @glyphIndexArray;
    my Int:D $last-ord := -2;
    my Int:D $last-gid := -2;
    my Int:D $seg = -1;


    for 0 ..^ $.charset-len {
        my $gid = @!index[$_];
        my $ord := $.charset[$gid];
        unless $ord == $last-ord + 1 && $gid == $last-gid + 1 {
            $seg++;
            @startCode[$seg] = $ord;
            @idDelta[$seg] = $gid - $ord;
        }
        @endCode[$seg] = $ord;
        $last-ord := $ord;
        $last-gid := $gid;
    }
    # add missing glyph
    ++$seg;
    @startCode[$seg] = @endCode[$seg] = 0xFFFF;
    @idDelta[$seg] = 1;

    Font::TTF::Table::CMap::Format4.new: :$segCount, :@startCode, :@endCode, :@idDelta, :@idRangeOffset, :@glyphIndexArray;
}

method !subset-cmap-format12 {
    my uint32 @groups[$!segments;3];
    my Int:D $last-ord := -2;
    my Int:D $seg = -1;

    for 0 ..^ $.charset-len {
        my $gid = @!index[$_];
        my $ord := $.charset[$gid];
        if $ord != $last-ord + 1 {
            $seg++;
            @groups[$seg;startCharCode] = $ord;
            @groups[$seg;startGlyphCode] = $gid;
        }
        @groups[$seg;endCharCode] = $ord;
        $last-ord := $ord;
    }

    Font::TTF::Table::CMap::Format12.new: :@groups;
}

method !subset-cmap-table {
    my $max-code := $.charset[@!index.tail];
    my $max-gid := $.gids-len;
    my @tables = (max($max-code - $max-gid, $max-gid) < 0xFFFF
                  ?? self!subset-cmap-format4()   # 16 bit
                  !! self!subset-cmap-format12()  # 32 bit
                 );

    my Font::TTF::Table::CMap $cmap .= new: :@tables;
    $!ttf.upd($cmap);
}

method apply(Font::TTF::Subset:D:) {
    my Font::TTF::Table::MaxProfile:D $maxp = $!ttf.maxp;
    my Set $retained .= new: <cmap glyf loca head hhea hmtx vhea vmtx maxp fpgm cvt prep>;

    for $!ttf.tags {
        $!ttf.delete($_)
            unless $_ ∈ $retained;
    }

    self!subset-glyf-table();
    self!subset-hmtx-table();
    self!subset-vmtx-table();
    self!subset-cmap-table();

    my $num-glyphs := self.gids-len;
    $!ttf.upd($maxp).numGlyphs = $num-glyphs;
    $!ttf
}

