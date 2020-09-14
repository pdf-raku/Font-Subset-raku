use Font::Subset::TTF::Table;

class Font::Subset::TTF::Table::Locations
    does Font::Subset::TTF::Table {

    use Font::Subset::TTF::Defs :Sfnt-Struct;
    use Font::Subset::TTF::Table::Header;
    use Font::Subset::TTF::Table::MaxProfile;
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
        my Font::Subset::TTF::Table::Header:D $head .= load($loader);
        my Font::Subset::TTF::Table::MaxProfile:D $maxp .= load($loader);

        $!num-glyphs = $maxp.numGlyphs;

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
