use Font::TTF::Table;

class Font::TTF::Table::PCLT is repr('CStruct')
    is repr('CStruct')
    does Font::TTF::Table['PCLT'] {

    use Font::TTF::Defs :types, :Sfnt-Struct;

    HAS Fixed   $.version;
    has uint32   $.fontNumber;
    has uFWord   $.pitch;
    has uFWord   $.xHeight;
    has uFWord   $.style;
    has uFWord   $.typeFamily;
    has uFWord   $.capHeight;
    has uFWord   $.symbolSet;

    my class TypeFace is repr('CStruct')  does Sfnt-Struct {
        has uint8 ($!b1, $!b2, $!b3, $!b4, $!b5,
                     $!b6, $!b7, $!b8, $!b9, $!b10,
                     $!b11, $!b12, $!b13, $!b14, $!b15, $!b16
                  );
        method Str handles<gist> {
            self.pack.grep(* > 0).map(*.chr).join;
        }
    }
    HAS TypeFace $.typeface;

    has uint64 $.characterComplement;

    my class FileName is repr('CStruct') does Sfnt-Struct {
        has uint8 ($!b1, $!b2, $!b3, $!b4, $!b5, $!b6);
        method Str handles<gist> {
            self.pack.grep(* > 0).map(*.chr).join;
        }
    }
    HAS FileName $.fileName;
    has int8     $.strokeWeight;
    has int8     $.widthType;
    has uint8    $.serifStyle;
    has uint8    $.reserved;
}
