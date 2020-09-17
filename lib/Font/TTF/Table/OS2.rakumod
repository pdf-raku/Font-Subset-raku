use Font::TTF::Table;

class Font::TTF::Table::OS2
    is repr('CStruct')
    does Font::TTF::Table['OS/2'] {

    use Font::TTF::Defs :types, :Sfnt-Struct;

    has uint16	$.version;	# table version number (set to 0)
    has int16	$.xAvgCharWidth;	# average weighted advance width of lower case letters and space
    has uint16	$.usWeightClass;	# visual weight (degree of blackness or thickness) of stroke in glyphs
    has uint16	$.usWidthClass;	# relative change from the normal aspect ratio (width to height ratio) as specified by a font designer for the glyphs in the font
    has int16	$.fsType;	# characteristics and properties of this font (set undefined bits to zero)
    has int16	$.ySubscriptXSize;;	# recommended horizontal size in pixels for subscripts
    has int16	$.ySubscriptYSize;	# recommended vertical size in pixels for subscripts
    has int16	$.ySubscriptXOffset;	# recommended horizontal offset for subscripts
    has int16	$.ySubscriptYOffset;	# recommended vertical offset form the baseline for subscripts
    has int16	$.ySuperscriptXSize;	# recommended horizontal size in pixels for superscripts
    has int16	$.ySuperscriptYSize;	# recommended vertical size in pixels for superscripts
    has int16	$.ySuperscriptXOffset;	# recommended horizontal offset for superscripts
    has int16	$.ySuperscriptYOffset;	# recommended vertical offset from the baseline for superscripts
    has int16	$.yStrikeoutSize;	# width of the strikeout stroke
    has int16	$.yStrikeoutPosition;	# position of the strikeout stroke relative to the baseline
    has int16	$.sFamilyClass;	# classification of font-family design.
        # todo
    my class PANOSE is repr('CStruct') does Sfnt-Struct {
        has int8 $.bFamilyType;
        has int8 $.bSerifStyle;
        has int8 $.bWeight;
        has int8 $.bProportion;
        has int8 $.bContrast;
        has int8 $.bStrokeVariation;
        has int8 $.bArmStyle;
        has int8 $.bLetterForm;
        has int8 $.bMidline;
        has int8 $.bXHeight;
        method Blob {
            self.pack;
        }
    }

    HAS PANOSE	$.panose;	# 10 byte series of number used to describe the visual characteristics of a given typeface
    has uint32	$.ulUnicodeRange1;	# Field is split into two bit fields of 96 and 36 bits each. The low 96 bits are used to specify the Unicode blocks encompassed by the font file. The high 32 bits are used to specify the character or script sets covered by the font file. Bit assignments are pending. Set to 0
    has uint32   $.ulUnicodeRange2;        # Bits 32-63
    has uint32   $.ulUnicodeRange3;        # Bits 64-95
    has uint32   $.ulUnicodeRange4;        # Bits 96-127

    my class achVendID is repr('CStruct')  does Sfnt-Struct {
        has uint8 ($!b1, $!b2, $!b3, $!b4);
        method Str handles<gist> {
            self.pack.grep(* > 0).map(*.chr).join;
        }
    }
    HAS	achVendID $.achVendID;	# four character identifier for the font vendor
    has uint16	$.fsSelection;	# 2-byte bit field containing information concerning the nature of the font patterns
    has uint16	$.fsFirstCharIndex;	# The minimum Unicode index in this font.
    has uint16	$.fsLastCharIndex;	# The maximum Unicode index in this font.
    has int16	$.sTypoAscender;	# The typographic ascender for this font. This is not necessarily the same as the ascender value in the 'hhea' table.
    has int16	$.sTypoDescender;	# The typographic descender for this font. This is not necessarily the same as the descender value in the 'hhea' table.
    has int16	$.sTypoLineGap;	# The typographic line gap for this font. This is not necessarily the same as the line gap value in the 'hhea' table.
    has uint16	$.usWinAscent;	# The ascender metric for Windows. usWinAscent is computed as the yMax for all characters in the Windows ANSI character set.
    has uint16	$.usWinDescent;	# The descender metric for Windows. usWinDescent is computed as the -yMin for all characters in the Windows ANSI character set.
    # only version 1 and higher:
    has uint32	$.ulCodePageRange1;	# Bits 0-31
    has uint32	$.ulCodePageRange2;	# Bits 32-63
    # only version 2 and higher:
    has int16	$.sxHeight;	# The distance between the baseline and the approximate height of non-ascending lowercase letters measured in FUnits.
    has int16	$.sCapHeight;	# The distance between the baseline and the approximate height of uppercase letters measured in FUnits.
    has uint16	$.usDefaultChar;	# The default character displayed by Windows to represent an unsupported character. (Typically this should be 0.)
    has uint16	$.usBreakChar;	# The break character used by Windows.
    has uint16	$.usMaxContext;	# The maximum length of a target glyph OpenType context for any feature in this font.
     # only version 5 and higher:
    has uint16	$.usLowerPointSize;	# The lowest size (in twentieths of a typographic point), at which the font starts to be used. This is an inclusive value.
    has uint16	$.usUpperPointSize;	# The highest size (in twentieths of a typographic point), at which the font starts to be used. This is an exclusive value. Use 0xFFFFU to indicate no upper limit.

}
