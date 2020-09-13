unit class Font::Subset::TTF::Table;

has Str $.tag is required;
has Blob $.buf is required;

method load($loader) { $loader.load(self.tag, :class(self.WHAT)) }
