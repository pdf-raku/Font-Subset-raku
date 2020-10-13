use v6;
use Cairo;

use Font::FreeType:ver<0.3.0+>;
use Font::FreeType::Face;
use Font::FreeType::Raw;

my Font::FreeType $freetype .= new;

=begin pod

creates an embedded subset via Cairo for comparision with t/ttf-subset.t

=item to inspect the font

    $ pyftinspect etc/cairo-subset.ttf 

=end pod

sub cairo-subset($font-in, $pdf-out, $font-out) {   

    given Cairo::Surface::PDF.create($pdf-out, 256, 256) {
        given Cairo::Context.new($_) {

            my Font::FreeType::Face $face = $freetype.face($font-in);
            my FT_Face $ft-face = $face.raw;
            my Cairo::Font $font .= create(
                $ft-face, :free-type,
            );
            .move_to(10, 10);
            .set_font_size(10.0);
            .set_font_face($font);
            .show_text("Hello, ½world");
        };
        .show_page;
        .finish;
    }

    note "extracting font... $font-out";
    use PDF::Reader;
    my PDF::Reader $r .= new.open: $pdf-out;
    $font-out.IO.open(:w).write: $r.ind-obj(7, 0).object.decoded;
}

cairo-subset('t/fonts/Vera.ttf', 'etc/cairo-subset.pdf', 'etc/cairo-subset.ttf');

# note that Cairo extracts from otf to cff
cairo-subset('t/fonts/Cantarell-Oblique.otf', 'etc/cairo-subset2.pdf', 'etc/cairo-subset.cff');
