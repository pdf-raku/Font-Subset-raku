use Font::TTF::Table;

class Font::TTF::Table::VertHeader
    is repr('CStruct')
    does Font::TTF::Table['vhea'] {

    use Font::TTF::Defs :types;

    has Fixed	$.version;	# Version number of the Vertical Header Table (0x00011000 for the current version).
    has int16	$.vertTypoAscender;	# The vertical typographic ascender for this font. It is the distance in FUnits from the vertical center baseline to the right of the design space. This will usually be set to half the horizontal advance of full-width glyphs. For example, if the full width is 1000 FUnits, this field will be set to 500.
    has int16	$.vertTypoDescender;	# The vertical typographic descender for this font. It is the distance in FUnits from the vertical center baseline to the left of the design space. This will usually be set to half the horizontal advance of full-width glyphs. For example, if the full width is 1000 FUnits, this field will be set to -500.
    has int16	$.vertTypoLineGap;	# The vertical typographic line gap for this font.
    has int16	$.advanceHeightMax;	# The maximum advance height measurement in FUnits found in the font. This value must be consistent with the entries in the vertical metrics table.
    has int16	$.minTopSideBearing;	# The minimum top side bearing measurement in FUnits found in the font, in FUnits. This value must be consistent with the entries in the vertical metrics table.
    has int16	$.minBottomSideBearing;	# The minimum bottom side bearing measurement in FUnits found in the font, in FUnits. This value must be consistent with the entries in the vertical metrics table.
    has int16	$.yMaxExtent;	# This is defined as the value of the minTopSideBearing field added to the result of the value of the yMin field subtracted from the value of the yMax field.
    has int16	$.caretSlopeRise;	# The value of the caretSlopeRise field divided by the value of the caretSlopeRun field determines the slope of the caret. A value of 0 for the rise and a value of 1 for the run specifies a horizontal caret. A value of 1 for the rise and a value of 0 for the run specifies a vertical caret. A value between 0 for the rise and 1 for the run is desirable for fonts whose glyphs are oblique or italic. For a vertical font, a horizontal caret is best.
    has int16	$.caretSlopeRun;	# See the caretSlopeRise field. Value = 0 for non-slanted fonts.
    has int16	$.caretOffset;	# The amount by which the highlight on a slanted glyph needs to be shifted away from the glyph in order to produce the best appearance. Set value equal to 0 for non-slanted fonts.
    has int16	($!reserved, $!r2, $!r3, $!r4);	# set value to 0
    has uint16	$.numOfLongVerMetrics;	# Number of advance heights in the Vertical Metrics table.
}
