unit class Font::Subset::TTF;

use CStruct::Packing :Endian;
use Font::Subset::TTF::Defs :Sfnt-Struct;
use Font::Subset;
use Font::Subset::Raw;
use Font::Subset::TTF::Table;
use Font::Subset::TTF::Table::CMap;
use Font::Subset::TTF::Table::Header;
use Font::Subset::TTF::Table::Locations;
use Font::Subset::TTF::Table::MaxProfile;
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
    has uint32	$.checkSum;	# checksum for this table
    has uint32	$.offset;	# offset from beginning of sfnt
    has uint32	$.length;	# length of this table in byte (actual length not padded length)

    sub tag-decode(UInt:D $tag is copy) is export(:tag-decode) {
        my @chrs = (1..4).map: {
            my $chr = ($tag mod 256).chr;
            $tag div= 256;
            $chr;
        }
        @chrs.reverse.join.trim;
    }

    sub tag-encode(Str:D $s --> UInt) is export {
        my uint32 $enc = 0;
        for $s.ords {
            $enc *= 256;
            $enc += $_;
        }
        $enc ~= ' ' while $enc.chars < 4;
        $enc;
    }

    method tag-encoded { $!tag }
    method tag {
        tag-decode($!tag);
    }
}
has IO::Handle:D $.fh is required;
has Offsets $!offsets handles<numTables>;
has UInt %!tag-idx;
has Font::Subset::TTF::Table %!tables = %(
    :cmap(Font::Subset::TTF::Table::CMap),
    :head(Font::Subset::TTF::Table::Header),
    :loca(Font::Subset::TTF::Table::Locations),
    :maxp(Font::Subset::TTF::Table::MaxProfile),
);
has Directory @.directories;
has UInt @.lengths;
has Buf @.bufs;
has Set $.rebuilt = set <
    maxp hdmx htmx cmap loca glyf name kern
>;

method tags {
    @!directories.grep(*.defined)>>.tag;
}

submethod TWEAK {
    $!offsets .= read($!fh);
    for 0 ..^ $!offsets.numTables {
        my Directory $dir .= read($!fh);
        %!tag-idx{$dir.tag} = $_;
        @!directories.push: $dir;
    }

    self!setup-lengths();
    self;
}

method !setup-lengths {
    my $prev;
    for @!directories.sort(*.offset) -> $dir {
        with $prev {
            my $offset = $dir.offset;
            my $idx = %!tag-idx{$prev.tag};
            @!lengths[$idx] = $offset - $prev.offset;
        }
        $prev = $dir;
    }
}

method buf(Str $tag) {
    my UInt:D $idx = %!tag-idx{$tag};
    @!bufs[$idx] //= do with %!tables{$tag} {
        .pack;
    }
    else {
        with @!directories[$idx] {
            my $offset = .offset;
            $!fh.seek($offset, SeekFromBeginning);
            with @!lengths[$idx] {
                $!fh.read($_);
            }
            else {
                $!fh.slurp-rest(:bin);
            }
        }
    }
}

multi method update-buf(Blob $buf, Str:D :$tag!) {
    %!tables{$tag}:delete; # invalidate object
    my $idx = (%!tag-idx{$tag} //= +%!tag-idx);
    @!bufs[$idx] = $buf;
}

multi method update-table(Font::Subset::TTF::Table $obj) {
    my $tag = $obj.tag;
    %!tables{$tag} = $obj;
    my $idx = (%!tag-idx{$tag} //= +%!tag-idx);
    @!bufs[$idx] = Nil;  # invalidate buffer
}

method load(Str $tag, :$class = %!tables{$tag}) {
    %!tables{$tag} //= do {
        with self.buf($tag) -> Blob $buf {
            $class.new: :$buf, :$tag, :loader(self);
        }
    };
}

constant Alignment = nativesizeof(long);

multi sub byte-align(UInt $bytes is rw) {
    if $bytes %% Alignment {
        $bytes;
    }
    else {
        my \padding = Alignment - $bytes % Alignment;
        $bytes += padding;
    }
}

multi sub byte-align(buf8 $buf) {
    my $bytes := $buf.bytes;
    unless $bytes %% Alignment {
        my \padding = Alignment - $bytes % Alignment;
        $buf.append: 0 xx padding;
    }
    $buf;
}

method subset(Font::Subset $subset) {
    my Font::Subset::TTF::Table::Header:D $head .= load(self);
    my Font::Subset::TTF::Table::MaxProfile:D $maxp .= load(self);
    my Font::Subset::TTF::Table::Locations:D $loca .= load(self);
    my buf8 $glyphs = self.buf('glyf');

    my $num-glyphs := $subset.len;
    $maxp.numGlyphs = $num-glyphs;
    my $bytes = $subset.raw.repack-glyphs($loca.offsets, $glyphs);
    $glyphs.reallocate($bytes);
    $loca.num-glyphs = $num-glyphs;

    self.update-table($maxp);
    self.update-table($loca);
    self.update-buf($glyphs, :tag<glyf>);
}

method !rebuild returns Blob {
    # copy or rebuild tables. Preserve input order\
    my class ManifestItem {
        has Directory:D $.dir-in is required;
        has Blob:D $.buf is required;
        has Directory $.dir-out is rw;
    }
    my ManifestItem @manifest;

    for @!directories -> $dir-in {
        my $tag := $dir-in.tag;
        given self.load($tag) -> $table {
            my $buf = $table.buf;
            @manifest.push: ManifestItem.new: :$dir-in, :$buf;
        }
    }

    @manifest .= sort(*.dir-in.tag);

    my uint16 $numTables = +@manifest;
    # todo: recalc properties. copy for now
    my uint16  $searchRange = $!offsets.searchRange;
    my uint16  $entrySelector = $!offsets.entrySelector;
    my uint16  $rangeShift = $!offsets.rangeShift;
    my uint32  $ver = $!offsets.ver;
    my Offsets $offsets .= new: :$numTables, :$ver, :$searchRange, :$entrySelector, :$rangeShift;
    my $buf = $offsets.pack;
    my $offset = Offsets.packed-size + $numTables * Directory.packed-size;
    for @manifest {
        my $dir = .dir-in;
        my $tag-str = $dir.tag;
        my uint32 $tag = $dir.tag-encoded;
        # todo: recalc properties. copy for now
        my uint32	$checkSum = $dir.checkSum;
        my $subbuf = $dir.pack;
        my uint32 $length = $dir.length;
        .dir-out = Directory.new: :$offset, :$tag, :$tag-str, :$length, :$checkSum;
        $buf.append: .dir-out.pack;
        $offset += $length;
        byte-align($offset);
    }
    for @manifest {
        $buf.append: .buf;
        byte-align($buf);
    }
    $buf;
}

#| rebuilt the Sfnt Image
method Blob {
    self!rebuild;
}

