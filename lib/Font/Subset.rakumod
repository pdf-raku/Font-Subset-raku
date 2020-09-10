unit class Font::Subset:ver<0.0.1>;

use Font::Subset::Raw;
use Font::FreeType::Face;
use Font::FreeType::Raw::Defs;
use NativeCall;

has Font::FreeType::Face $.face is required;
has fontSubset $!raw handles<len charset gids>;

submethod TWEAK(List:D :$charset!) {
    my CArray[FT_ULong] $codes .= new: $charset.list;
    $!raw = fontSubset::create($!face.raw, $codes, $codes.elems);
}

submethod DESTROY {
    .done with $!raw;
}
