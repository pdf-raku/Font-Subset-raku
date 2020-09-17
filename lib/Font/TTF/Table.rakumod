use Font::TTF::Defs :Sfnt-Struct;

role Font::TTF::Table is Sfnt-Struct {
}

role Font::TTF::Table[Str $tag] does Font::TTF::Table {
    method tag { $tag }
    method load($loader) { $loader.load(self.tag, :class(self.WHAT)) }
    method unpack(|) {...}
    method pack(|) {...}
    method buf { self.pack }

    submethod TWEAK(Blob :$buf) {
        self.unpack($_) with $buf;
    }
}

