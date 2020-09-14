role Font::Subset::TTF::Table {

    has Str $.tag is required;
    has Blob $.buf is required;

    method load($loader) { $loader.load(self.tag, :class(self.WHAT)) }
}

use Font::Subset::TTF::Defs :Sfnt-Struct;

role Font::Subset::TTF::Table[Str $tag] is Sfnt-Struct {
    method tag { $tag }
    method load($loader) { $loader.load(self.tag, :class(self.WHAT)) }
    method unpack(|) {...}
    method pack(|) {...}
    method buf { self.pack }

    submethod TWEAK(Blob :$buf) {
        self.unpack($_) with $buf;
    }
}

