use Test;
use Font::Subset::TTF;
use Font::Subset::TTF::Table::CMap;
use Font::Subset::TTF::Table::Locations;
use NativeCall;
plan 12;

my $fh = "t/fonts/Vera.ttf".IO.open(:r, :bin);

my Font::Subset::TTF:D $ttf .= new: :$fh;

is $ttf.numTables, 17;
is $ttf.face.num-glyphs, 268;

my Font::Subset::TTF::Table::Locations $locs .= load($ttf);
is $locs.elems, $locs.num-glyphs+1;
is $locs[0].byte, 0;
is $locs[1].byte, 68;
is $locs[5].byte, 176;
is $locs[268].byte, 35454;

my Font::Subset::TTF::Table::CMap $cmap .= load($ttf);
is $cmap.elems, 2;

is $cmap[0].platformID, 1;
is $cmap[0].subbuf.bytes, 262;

is $cmap[1].platformID, 3;
is $cmap[1].subbuf.bytes, 574;

done-testing;
