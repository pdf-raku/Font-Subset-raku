#include "font_subset.h"
#include "font_subset_sfnt.h"
#include <stdio.h>

DLLEXPORT uint32_t
font_subset_sfnt_checksum(uint8_t* buf, size_t len) {
    uint32_t checksum = 0;
    size_t i;
    uint8_t j;
    for (i = 0; i < len;) {
        uint32_t val = 0;
        for (j = 0; j < 4; j++) {
            val <<= 8;
            if (i < len) {
                val += buf[i++];
            }
        }
        checksum += val;
    }
    return checksum;
}

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
