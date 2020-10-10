unit class Font::Subset;

use Font::FreeType::Face;
use Font::Subset::TTF;

has Font::Subset::TTF $!delegate;

method can-subset( Font::FreeType::Face :$face! --> Bool) {
    $face.font-format ~~ 'TrueType';
}

method Blob returns Blob {
    $!delegate.apply.Blob;
}

multi submethod TWEAK(Blob:D :$buf!, |c) {
    # hacked for now
    "/tmp/blah".IO.spurt: $buf;
    my $fh = "/tmp/blah".IO.open(:r, :bin);
    self.TWEAK( :$fh, |c);
}

multi submethod TWEAK(IO::Handle:D :$fh!, |c) {
    $!delegate .= new: :$fh, |c;
}
