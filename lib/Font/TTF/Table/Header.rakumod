use Font::TTF::Table;

class Font::TTF::Table::Header
    is repr('CStruct')
    does Font::TTF::Table['head'] {

    use Font::TTF::Defs :types;

    HAS Fixed  $.version;
    HAS Fixed  $.fontRevision;
    has uint32 $.checkSumAdjustment;
    has uint32 $.magicNumber;
    has uint16 $.flags;
    has uint16 $.unitsPerEm;
    has longDateTime $.created;
    sub sfnt-date(Int $date) {
        constant SfntEpochDiff = -2082844800;
        DateTime.new: $date + SfntEpochDiff;
    }
    method created {
        sfnt-date($!created);
    }
    has longDateTime $.modified;
    method modified {
        sfnt-date($!modified);
    }
    has FWord  $.xMin;
    has FWord  $.yMin;
    has FWord  $.xMax;
    has FWord  $.yMax;
    has uint16 $.macStyle;
    has uint16 $.lowestRecPPEM;
    has int16  $.fontDirectionHint;
    has int16  $.indexToLocFormat;
    has int16  $.glyphDataFormat;
}

