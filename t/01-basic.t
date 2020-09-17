use Test;
plan 3;
use Font::TTF::Subset;
use Font::FreeType;
use Font::FreeType::Face;
use NativeCall;

my Font::FreeType $freetype .= new;
my Font::FreeType::Face $face = $freetype.face('t/fonts/DejaVuSans.ttf');

my @charset = "Hello, World!".ords.unique.sort;

my Font::TTF::Subset $subset .= new: :$face, :@charset;
is $subset.len, 10;
is $subset.charset[0], 32;
is $subset.gids[0], 3;

done-testing();
