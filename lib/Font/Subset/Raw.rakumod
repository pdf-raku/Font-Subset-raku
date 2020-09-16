unit module Font::Subset::Raw;

use Font::FreeType::Raw;
use Font::FreeType::Raw::Defs;
use Font::Subset::Raw::Defs;
use NativeCall;

sub font_subset_sfnt_checksum(Blob, size_t --> uint32)
    is export is native($FONT-SUBSET-LIB) {*}

class fontSubset is repr('CStruct') is export {

    has FT_Face $.face;
    has size_t $.len;
    has CArray[FT_ULong] $.charset;
    has CArray[FT_UInt] $.gids;
    has Pointer $.fail;

    our sub create(FT_Face, CArray[FT_ULong] $codes, size_t --> fontSubset)
        is native($FONT-SUBSET-LIB) is symbol('font_subset_create') {*}
    method new(|) {...}
    method repack-glyphs(CArray[uint16], buf8 --> uint16)
        is native($FONT-SUBSET-LIB) is symbol('font_subset_sfnt_repack_glyphs_16') {*}
    method done is native($FONT-SUBSET-LIB) is symbol('font_subset_done') {*}
}


