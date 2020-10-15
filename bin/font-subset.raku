use Font::Subset;
use Font::FreeType;
use Font::FreeType::Face;

sub MAIN(Str $input, Str :$output = $input.subst(/['.'\w+]?$/, '.subset'), Str :$text, *@ords) {
    my UInt @charset = @ords>>.Int;
    @charset.append: $text.ords;
    fail  "no characters specified"
        unless @charset;
    my IO::Handle $fh = $input.IO.open: :r, :bin;
    my Font::FreeType::Face $face = Font::FreeType.new.face: $fh;
    given $face.font-format {
        die "don't know how to format fonts of type: $_"
            unless $_ ~~ 'TrueType';
    }
    my Font::Subset $subset .= new: :$face, :@charset, :$fh;
    $output.IO.open(:w, :bin).write: $subset.Blob;
}


=begin pod

=head1 NAME

font-subset.raku - Subset a font

=head1 SYNOPSIS

font-subset.raku font-file --output=subset --text="String" codes*

=head1 DESCRIPTION

Writes a subsetted font that includes only the selected characters. Also removes all optional font features by default.

The default action to to write an minimilstic font by default, with many missing features.

Todo: Options to reenable selected features, e.g.

=item --kern --os2 --pclt --names --...

=end pod
