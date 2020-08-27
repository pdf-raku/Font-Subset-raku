use Test;
plan 1;
use Font::Subset::Raw :&font_subset_create;
use Font::FreeType;
use Font::FreeType::Face;
use NativeCall;

my Font::FreeType $freetype .= new;
my Font::FreeType::Face $face = $freetype.face('t/fonts/DejaVuSans.ttf');

my CArray[uint32] $codes .= new: "Hello, World".ords.unique.sort;

lives-ok { font_subset_create($face.raw, $codes, $codes.elems, my size_t $len) }
done-testing();
