#| Type and Enumeration declarations
unit module Font::Subset::Defs;

# additional C bindings
our $SFNT-SUBSET-LIB is export = %?RESOURCES<libraries/font-subset>;
our $CLIB = Rakudo::Internals.IS-WIN ?? 'msvcrt' !! Str;
