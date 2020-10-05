unit module Font::TTF::Subset::Raw;

use Font::FreeType::Raw;
use Font::FreeType::Raw::Defs;
use Font::TTF::Subset::Defs;
use NativeCall;

class fontSubset is repr('CStruct') is export {

    has FT_Face $.face;
    has size_t $.segments;
    # characters and corresponding gids 
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
    method subset-glyphs(CArray[uint16], buf8 --> uint16)
        is native($SFNT-SUBSET-LIB) is symbol('sfnt_subset_repack_glyphs_16') {*}
    method done is native($SFNT-SUBSET-LIB) is symbol('sfnt_subset_done') {*}
}


