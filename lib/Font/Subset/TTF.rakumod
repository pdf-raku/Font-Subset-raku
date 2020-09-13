unit class Font::Subset::TTF;

use CStruct::Packing :Endian;
use Font::FreeType;
use Font::FreeType::Face;
use Font::Subset::TTF::Defs :Sfnt-Struct;
use Font::Subset::TTF::Table;
use Font::Subset::TTF::Table::CMap;
use Font::Subset::TTF::Table::Locations;
use NativeCall;

class Offsets is repr('CStruct') does Sfnt-Struct {
    has uint32  $.ver;
    has uint16  $.numTables;
    has uint16  $.searchRange;
    has uint16  $.entrySelector;
    has uint16  $.rangeShift;
}

class Directory is repr('CStruct') does Sfnt-Struct {
    has uint32	$.tag; 	        # 4-byte identifier
    sub tag-decode(UInt:D $tag is copy) is export(:tag-decode) {
        my @chrs = (1..4).map: {
            my $chr = ($tag mod 256).chr;
            $tag div= 256;
            $chr;
        }
        @chrs.reverse.join;
    }

    sub tag-encode(Str:D $s --> UInt) is export {
        my uint32 $enc = 0;
        for $s.ords {
            $enc *= 256;
            $enc += $_;
        }
        $enc;
    }

    method tag {
        tag-decode($!tag);
    }

    has uint32	$.checkSum;	# checksum for this table
    has uint32	$.offset;	# offset from beginning of sfnt
    has uint32	$.length;	# length of this table in byte (actual length not padded length)
}
has IO::Handle:D $.fh is required;
has Font::FreeType::Face $.face;
has Offsets $!offsets handles<numTables>;
has %!position;
has %!length;
has Directory @!directories;
has Buf %!bufs;
has Font::Subset::TTF::Table %!tables = %(
    :cmap(Font::Subset::TTF::Table::CMap),
    :loca(Font::Subset::TTF::Table::Locations),
);
has Set $.copied = set <head hhea vhea maxp hmtx fpgm prep cvt>;
##has Set $.rebuilt = set <cmap loca glyph>;

method tables {
    %!position.sort(*.value).map(*.key);
}

submethod TWEAK {
    with $!fh {
        $!face //= Font::FreeType.new.face: .slurp(:bin);
        .seek(0, SeekFromBeginning);
        $!offsets .= read($!fh);
    }

    for 1 .. $!offsets.numTables {
        my Directory $dir .= read($!fh);
        %!position{$dir.tag} = $dir.offset;
        @!directories.push: $dir;
    }

    self!setup-lengths();
    self;
}

method !setup-lengths {
    my $prev;
    for %!position.pairs.sort(*.value) {
        if $prev.defined {
            %!length{$prev.key} = .value - $prev.value;
        }
        $prev = $_;
    }
    %!length{.key} = .value with $prev;
}

method read($tag) {
    without %!bufs{$tag} {
        with %!position{$tag} -> $pos {
            $!fh.seek($pos, SeekFromBeginning);
            my $len = %!length{$tag};
            $_ = $!fh.read($len);
        }
    }
    %!bufs{$tag}
}

multi method load(Str $tag, :$class = %!tables{$tag}) {
    %!tables{$tag} //= do {
        with self.read($tag) -> $buf {
            $class.new: :$buf, :$tag, :pad, :loader(self);
        }
    }
}

method !rebuild {
    my $out = self.new;
    # copy or rebuild tables. Preserve input order
    for @!directories.sort: *.offset {
        given .tag {
##            when $!rebuilt{$_}:exists {
##                ...
##            }
            when $!copied{$_}:exists {
            }
        }
    }
}

#| rebuilt the Sfnt Image
method Blob {
    my $out = self!rebuild;
    $out.pack;
}

