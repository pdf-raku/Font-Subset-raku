#| Type and Enumeration declarations
unit module Font::TTF::Subset::Defs;

# additional C bindings
our $SFNT-SUBSET-LIB is export = %?RESOURCES<libraries/sfnt-subset>;
our $CLIB = Rakudo::Internals.IS-WIN ?? 'msvcrt' !! Str;
