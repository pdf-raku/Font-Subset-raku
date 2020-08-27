unit module Font::Subset::Raw;

use Font::FreeType::Raw;
use Font::Subset::Raw::Defs;
use NativeCall;

our sub font_subset_create(FT_Face, CArray $codes, size_t, size_t is rw --> CArray) is native($FONT-SUBSET-LIB) is export(:font_subset_create) {*}

