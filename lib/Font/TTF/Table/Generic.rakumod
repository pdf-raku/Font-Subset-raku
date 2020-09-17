use Font::TTF::Table;

class Font::TTF::Table::Generic
    does Font::TTF::Table {

    has Str $.tag is required;
    has Blob $.buf is required;

    method load($loader) { $loader.load(self.tag, :class(self.WHAT)) }
}

