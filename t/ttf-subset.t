use Test;
plan 10;
use Font::TTF::Subset;
use Font::TTF;
use Font::FreeType;
use Font::FreeType::Face;
use NativeCall;

my @charset = "Hello, World!".ords.unique.sort;

my Font::FreeType $freetype .= new;
my Font::FreeType::Face $face = $freetype.face('t/fonts/DejaVuSans.ttf');

my $fh = "t/fonts/Vera.ttf".IO.open(:r, :bin);

my Font::TTF:D $ttf .= new: :$fh;
my Font::TTF::Subset $subset .= new: :$face, :@charset;

$ttf.subset($subset);

my $maxp = $ttf.load('maxp');
is $maxp.numGlyphs, 10;

my $loca = $ttf.load('loca');
is $loca.elems, 11;
is $loca[10], 1394;

todo "rebuild other tables", 5

flunk('head');
flunk('hhea');
flunk('htmx');
flunk('cmap');
flunk('name');
flunk('kern');

done-testing();
