unit module Font::TTF::Subset::Raw;

use Font::FreeType::Raw;
use Font::FreeType::Raw::Defs;
use Font::TTF::Subset::Defs;
use NativeCall;

class fontSubset is repr('CStruct') is export {

    has FT_Face $.face;
    # characters and corresponding original gids 
    has CArray[FT_ULong] $.charset;
    has CArray[FT_UInt] $.gids;
    # additional composite glyph components
    has size_t $.charset-len;
    has FT_UInt $.gids-len;
    has FT_UInt $!gids-size;
    has Pointer $.fail;

    our sub create(FT_Face, CArray[FT_ULong] $codes, size_t --> fontSubset)
        is native($SFNT-SUBSET-LIB) is symbol('sfnt_subset_create') {*}
    method new(|) {...}
    method add-glyph-components(buf8, size_t --> int16)
        is native($SFNT-SUBSET-LIB) is symbol('sfnt_glyph_add_components') {*}
    method done is native($SFNT-SUBSET-LIB) is symbol('sfnt_subset_done') {*}
}


