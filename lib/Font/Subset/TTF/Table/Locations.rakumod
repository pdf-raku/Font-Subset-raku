use Font::Subset::TTF::Table;

class Font::Subset::TTF::Table::Locations
    is Font::Subset::TTF::Table {

    use Font::Subset::TTF::Defs :Sfnt-Struct;
    use Font::FreeType::Face;
    use Font::FreeType::Raw::TT_Sfnt;
    use CStruct::Packing;
    use NativeCall;
    
    method tag {'loca'}

    has UInt $.num-glyphs;
    method elems { $!num-glyphs + 1}

    role Offset does Sfnt-Struct {
    }
    has CArray $.offsets handles<AT-POS>;

    class OffsetShort is repr('CStruct') does Offset {
        has uint16 $.word;
        method byte { $!word * 2 }
    }

    class OffsetLong  is repr('CStruct') does Offset {
        has uint32 $.byte;
    }

    submethod TWEAK(:$loader!) {
        my $buf := self.buf;
        my Font::FreeType::Face $face = $loader.face;
        my TT_Header $head .= load: :$face;
        my TT_MaxProfile $maxp .= load: :$face;

        $!num-glyphs = $maxp.numGlyphs;
        warn $!num-glyphs;

        my Offset:U $class = ? $head.indexToLocFormat
            ?? OffsetLong
            !! OffsetShort;

        my Buf $locs-buf = $loader.read(self.tag);
        $!offsets = $class.unpack-array($locs-buf, $!num-glyphs+1);
        self;
    }
    method pack(buf8 $buf) {
        ...
    }
}
