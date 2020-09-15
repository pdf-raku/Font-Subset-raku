#include "font_subset.h"
#include "font_subset_sfnt.h"
#include <stdio.h>

struct _table {
    unsigned long tag;
    int (*write) (fontSubsetPtr, unsigned long tag);
    int pos; /* position in the font directory */
};
typedef struct _table table_t;

struct _file {
    table_t tables[10];    
};

// in-place repacking of both an 16-bit location index and corresponding glyph buffer
DLLEXPORT uint16_t
font_subset_sfnt_repack_glyphs_16(fontSubsetPtr self, uint16_t* loc_idx, uint8_t* glyphs) {
    uint16_t glyph_new = 0; // glyph write postion
    FT_UInt  gid_new;       // new (written) GID
    for (gid_new = 0; gid_new <= self->len; gid_new++) {
        FT_UInt  gid_old = self->gids[gid_new];
        uint32_t glyph_old = loc_idx[gid_old];
        int32_t  glyph_len = loc_idx[gid_old+1] - glyph_old;
        uint16_t i;

        if (glyph_len < 0) {
            font_subset_fail(self, "subset location index is not ascending");
            return 0;
        }

        // convert 2 byte words addressing to bytes
        glyph_old *= 2;
        glyph_len *= 2;

        // update location index (word addressing)
        loc_idx[gid_new] = glyph_new / 2;

        for (i = 0; i < glyph_len; i++) {
            glyphs[glyph_new++] = glyphs[glyph_old++];
        }

    }
    loc_idx[gid_new] = glyph_new;

    return gid_new;
}
