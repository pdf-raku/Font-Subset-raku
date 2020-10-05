#ifndef __SFNT_GLYPH_H
#define __SFNT_GLYPH_H

#include "sfnt_subset.h"

// adapted from cairo-truetype-subset-private.h 

/* composite_glyph_t flags */
#define SFNT_ARG_1_AND_2_ARE_WORDS     0x0001
#define SFNT_WE_HAVE_A_SCALE           0x0008
#define SFNT_MORE_COMPONENTS           0x0020
#define SFNT_WE_HAVE_AN_X_AND_Y_SCALE  0x0040
#define SFNT_WE_HAVE_A_TWO_BY_TWO      0x0080

typedef struct _sfnt_composite_glyph {
    uint16_t flags;
    uint16_t index;
    uint16_t args[6]; /* 1 to 6 arguments depending on value of flags */
} sfnt_composite_glyph_t;

typedef struct _sfnt_glyph_data {
    int16_t           num_contours;
    int8_t            data[8];
    sfnt_composite_glyph_t glyph;
} sfnt_glyph_data_t;

DLLEXPORT int sfnt_glyph_add_components(sfntSubsetPtr, unsigned char*, size_t);

#endif /* __SFNT_GLYPH_H */
