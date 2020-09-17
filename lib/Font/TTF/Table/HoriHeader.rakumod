use Font::TTF::Table;

class Font::TTF::Table::HoriHeader
    is repr('CStruct')
    does Font::TTF::Table['hhea'] {

    use Font::TTF::Defs :types;

    HAS Fixed	$.version;	# 0x00010000 (1.0)
    has FWord	$.ascent;	# Distance from baseline of highest ascender
    has FWord	$.descent;	# Distance from baseline of lowest descender
    has FWord	$.lineGap;	# typographic line gap
    has uFWord	$.advanceWidthMax;	# must be consistent with horizontal metrics
    has FWord	$.minLeftSideBearing;	# must be consistent with horizontal metrics
    has FWord	$.minRightSideBearing;	# must be consistent with horizontal metrics
    has FWord	$.xMaxExtent;	# max(lsb + (xMax-xMin))
    has int16	$.caretSlopeRise;	# used to calculate the slope of the caret (rise/run) set to 1 for vertical caret
    has int16	$.caretSlopeRun;	# 0 for vertical
    has FWord	$.caretOffset;	# set value to 0 for non-slanted fonts
    has int16	($!reserved, $!r2, $!r3, $!r4);	# set value to 0
    has int16	$.metricDataFormat;	# 0 for current format
    has uint16	$.numOfLongHorMetrics;	# number of advance widths in metrics table
}
