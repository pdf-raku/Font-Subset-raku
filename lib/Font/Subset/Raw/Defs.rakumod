#| Type and Enumeration declarations
unit module Font::Subset::Raw::Defs;

# additional C bindings
our $FONT-SUBSET-LIB is export = %?RESOURCES<libraries/font-subset>;
our $CLIB = Rakudo::Internals.IS-WIN ?? 'msvcrt' !! Str;
