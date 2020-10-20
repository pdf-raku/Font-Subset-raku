unit class Font::Subset::TTF:ver<0.0.1>;

use Font::TTF;
use Font::TTF::Raw;
use Font::TTF::Table::CMap;
use Font::TTF::Table::CMap::Format0;
use Font::TTF::Table::CMap::Format4;
use Font::TTF::Table::CMap::Format12 :GroupIndex;
use Font::TTF::Table::GlyphIndex;
use Font::TTF::Table::HoriHeader;
use Font::TTF::Table::HoriMetrics;
use Font::TTF::Table::VertHeader;
use Font::TTF::Table::VertMetrics;
use Font::Subset::Raw;
use Font::FreeType;
use Font::FreeType::Face;
use Font::FreeType::Raw::Defs;
use NativeCall;

has Font::TTF $.ttf handles <Blob Buf> is built;
has Font::FreeType::Face $.face;

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

method !load-face(:$fh, :$buf) {
    Font::FreeType.new.face($fh || $buf);
}

submethod TWEAK(:@charset!, |c) {
    my CArray[FT_ULong] $codes .= new: @charset.unique;
    $!face //= self!load-face(|c);
    $!raw = fontSubset::create($!face.raw, $codes, $codes.elems);
    @!index = (0 ..^ $!raw.charset-len).sort({$!raw.charset[$_]});
    $!ttf .= new: |c;
    $!segments = self!count-segments();
    self!build-subset();
}

submethod DESTROY {
    .done with $!raw;
}

# rebuild the glyphs index ('loca') and the glyphs buffer ('glyf')
method !subset-glyf-table {
    my $old-loca = $!ttf.loca;
    my buf8 $old-glyphs-buf = $!ttf.buf('glyf');
    my CArray[uint16] $offsets .= new;
    my buf8 $glyphs-buf .= new;

    loop (my $i = 0; $i < $.gids-len; $i++) {
        my $old-gid = $.gids[$i];
        my $offset = $old-loca[$old-gid];
        my $end = $old-loca[$old-gid + 1];
        my UInt $len = $end - $offset;
        my $buf = $old-glyphs-buf.subbuf($offset, $len);
        $offsets[$i] = $glyphs-buf.bytes div 2;
        # extract any unseen composite glyphs, update buffer references
        if $buf.bytes {
            $!raw.add-glyph-components($buf, $buf.bytes)
                || warn "unable to add glyph components";
            $glyphs-buf.append: $buf;
        }
    }

    $offsets[$.gids-len] = $glyphs-buf.bytes div 2;

    my Font::TTF::Table::GlyphIndex $loca .= new: :$offsets, :num-glyphs($.gids-len);

    $!ttf.upd($loca);
    $!ttf.upd($glyphs-buf, :tag<glyf>)
}

# rebuild horizontal metrics
method !subset-hmtx-table {
    with $!ttf.hmtx -> $hmtx {
        my @metrics = (0 ..^ $.gids-len).map: {$hmtx[$.gids[$_]]};
        $!ttf.upd: $hmtx.new(:@metrics, :loader($!ttf));
    }
}

# rebuild vertical metrics
method !subset-vmtx-table {
    with $!ttf.vmtx -> $vmtx {
        my @metrics = (0 ..^ $.gids-len).map: {$vmtx[$.gids[$_]]};
        $!ttf.upd: $vmtx.new(:@metrics, :loader($!ttf));
    }
}

method !subset-cmap-format0 {
    my uint8 @glyphIndexArray[255];

    for 0 ..^ min($.charset-len, 256) {
        my $ord := $.charset[$_];
        @glyphIndexArray[$_] = $ord
            if $ord <= 255;
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
    # add missing glyph entry
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

method !build-subset(Font::Subset::TTF:D:) {
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
    given $!ttf.head {
        # set 2 byte location indexing
        $!ttf.upd($_).indexToLocFormat = 0
            if .indexToLocFormat;
    }

    $!ttf
}

