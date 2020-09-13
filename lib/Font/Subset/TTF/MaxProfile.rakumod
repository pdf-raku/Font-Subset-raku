use Font::Subset::TTF::Defs :types,  :Sfnt-Struct, :Sfnt-Table;

class Font::Subset::TTF::MaxProfile is repr('CStruct') does Sfnt-Struct does Sfnt-Table['maxp'] {
    HAS Fixed	$.version;	# 0x00010000 (1.0)
    has uint16	$.numGlyphs;	# the number of glyphs in the font
    has uint16	$.maxPoints;	# points in non-compound glyph
    has uint16	$.maxContours;	# contours in non-compound glyph
    has uint16	$.maxComponentPoints;	# points in compound glyph
    has uint16	$.maxComponentContours;	# contours in compound glyph
    has uint16	$.maxZones;	# set to 2
    has uint16	$.maxTwilightPoints;	# points used in Twilight Zone (Z0)
    has uint16	$.maxStorage;	# number of Storage Area locations
    has uint16	$.maxFunctionDefs;	# number of FDEFs
    has uint16	$.maxInstructionDefs;	# number of IDEFs
    has uint16	$.maxStackElements;	# maximum stack depth
    has uint16	$.maxSizeOfInstructions;	# byte count for glyph instructions
    has uint16	$.maxComponentElements;	# number of glyphs referenced at top level
    has uint16	$.maxComponentDepth;	# levels of recursion, set to 0 if font has only simple glyp
}
