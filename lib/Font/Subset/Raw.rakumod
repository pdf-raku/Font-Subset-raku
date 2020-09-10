unit module Font::Subset::Raw;

use Font::FreeType::Raw;
use Font::FreeType::Raw::Defs;
use Font::Subset::Raw::Defs;
use NativeCall;

class fontSubset is repr('CStruct') is export {

    has FT_Face $.face;
    has size_t $.len;
    has CArray[FT_ULong] $.charset;
    has CArray[FT_UInt] $.gids;
    has Pointer $.fail;

    our sub create(FT_Face, CArray[FT_ULong] $codes, size_t --> fontSubset) is native($FONT-SUBSET-LIB) is symbol('font_subset_create') {*}
    method new(|) {...}
    method done is native($FONT-SUBSET-LIB) is symbol('font_subset_done') {*}
}


