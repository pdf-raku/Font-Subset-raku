use Font::Subset::TTF;

unit class Font::Subset
    is Font::Subset::TTF;

use Font::FreeType::Face;

method can-subset( Font::FreeType::Face :$face! --> Bool) {
    $face.font-format ~~ 'TrueType';
}

