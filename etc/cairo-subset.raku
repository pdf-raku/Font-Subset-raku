use v6;
use Cairo;

use Font::FreeType:ver<0.3.0+>;
use Font::FreeType::Face;
use Font::FreeType::Raw;

my Font::FreeType $freetype .= new;

=begin pod

creates an embedded subset via Cairo for comparision with t/ttf-subset.t

=item to then extract font:

    use PDF::Reader;
    my PDF::Reader $r .= new.open: "etc/cairo-subset.pdf";
    etc/cairo-subset.ttf".IO.open(:w).write: $r.ind-obj(7, 0).object.decoded;'
=item to inspect the font

    $ pyftinspect etc/cairo-subset.ttf 

=end pod

given Cairo::Surface::PDF.create("etc/cairo-subset.pdf", 256, 256) {
    given Cairo::Context.new($_) {

        my $font-file = 't/fonts/Vera.ttf';
        my Font::FreeType::Face $face = $freetype.face($font-file);
        my FT_Face $ft-face = $face.raw;
        my Cairo::Font $font .= create(
            $ft-face, :free-type,
        );
        .move_to(10, 10);
        .set_font_size(10.0);
        .set_font_face($font);
        .show_text("Hello, world");
    };
    .show_page;
    .finish;
}

