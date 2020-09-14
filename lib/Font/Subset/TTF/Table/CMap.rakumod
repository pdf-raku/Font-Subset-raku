use Font::Subset::TTF::Table;

class Font::Subset::TTF::Table::CMap
    does Font::Subset::TTF::Table {

    use Font::Subset::TTF::Defs :types, :Sfnt-Struct;

    method tag {'cmap'}

    class Index is repr('CStruct') does Sfnt-Struct {
        has uint16 $.version;          # Version number (Set to zero)
        has uint16 $.numberSubtables;  # Number of encoding subtables
    }

    class Subtable {
        class Encoding is repr('CStruct') does Sfnt-Struct {
            has uint16	$.platformID;   	# Platform identifier
            has uint16	$.platformEncodingID;	# Platform-specific encoding identifier
            has uint32	$.offset;       	# Offset of the mapping table
        }
        has Encoding $.encoding handles<platformID platformEncodingID offset>;
        has blob8 $.subbuf;
        has $.obj;
        method fetch {
            $!obj //= do {
            }
        }
    }

    has Index $.index;
    has Subtable @.subtables handles<AT-POS Numeric elems>;
    
    submethod TWEAK {
        my $buf := self.buf;
        $!index .= unpack($buf);
        my UInt $offset = $!index.packed-size;
        my UInt $encoding-size = Subtable::Encoding.packed-size;
        my UInt $num-tables = $!index.numberSubtables;
        my Subtable::Encoding @encodings;

        for 0 ..^ $num-tables {
            @encodings.push: Subtable::Encoding.unpack($buf, :$offset);
            $offset += $encoding-size;
        }

        @encodings .= sort: *.offset;

        @!subtables = @encodings.pairs.map: {
            my Subtable::Encoding $encoding = .value;
            my UInt $n := .key + 1;
            my UInt $offset := $encoding.offset;
            my UInt $len := $n < +@encodings
                ?? @encodings[.key + 1].offset - $offset
                !! $buf.elems - $offset;

            my Blob:D $subbuf := $buf.subbuf($offset, $len);
            Subtable.new: :$encoding, :$subbuf;
        }

        self;
    }
    method pack(|) {...}
}
