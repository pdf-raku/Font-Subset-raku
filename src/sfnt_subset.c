#include "sfnt_subset.h"
#include <memory.h>
#include <stdio.h>

DLLEXPORT void
sfnt_subset_fail(sfntSubsetPtr self, const char* msg) {
    if (self->fail != NULL) {
        fprintf(stderr, "%s\n", self->fail);
        free(self->fail);
    }
    self->fail = strdup(msg);
}

DLLEXPORT sfntSubsetPtr
sfnt_subset_create(FT_Face font, FT_ULong *charset, size_t len) {
    size_t i;
    sfntSubsetPtr self = (sfntSubsetPtr)malloc(sizeof(struct _sfntSubset));
    self->font = font;
    self->len = 0;
    self->segments = 0;
    self->charset = calloc(len + 2, sizeof(FT_ULong));
    self->gids = calloc(len + 2, sizeof(FT_UInt));
    self->fail = NULL;

    // Add .notdef
    self->gids[0] = 0;
    self->charset[0] = 0;
    self->len++;
    self->segments++;

    for (i = charset[0] ? 0: 1; i <= len; i++) {
        FT_ULong code = charset[i];
        FT_UInt gid;
        if (i && code <= charset[i-1]) {
            sfnt_subset_fail(self, "charset is not unique and in ascending order");
            break;
        }
        gid = FT_Get_Char_Index(font, code);
        if (gid != 0) {
            if (self->gids[self->len-1]+1 != gid
                || self->charset[self->len-1]+1 != code) {
                self->segments++;
            }
            self->gids[self->len] = gid;
            self->charset[self->len] = code;
            self->len++;
        }
    }

    self->gids[self->len] = 0;
    self->charset[self->len] = 0;
    return self;
}

// in-place repacking of both an 16-bit location index and corresponding glyph buffer
DLLEXPORT uint16_t
sfnt_subset_repack_glyphs_16(sfntSubsetPtr self, uint16_t* loc_idx, uint8_t* glyphs) {
    uint16_t glyph_new = 0; // glyph write postion
    FT_UInt  gid_new;       // new (written) GID
    for (gid_new = 0; gid_new <= self->len; gid_new++) {
        FT_UInt  gid_old = self->gids[gid_new];
        uint32_t glyph_old = loc_idx[gid_old];
        int32_t  glyph_len = loc_idx[gid_old+1] - glyph_old;
        uint16_t i;

        if (glyph_len < 0) {
            sfnt_subset_fail(self, "subset location index is not ascending");
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

    return glyph_new;
}

static void _done(void** p) {
    if (*p != NULL) {
        free(*p);
        *p = NULL;
    }
}

DLLEXPORT void
sfnt_subset_done(sfntSubsetPtr self) {

    if (self->fail) {
        char msg[120];
        snprintf(msg, sizeof(msg), "uncaught failure on sfntSubsetPtr %p destruction: %s", self, self->fail);
        SFNT_SUBSET_WARN(msg);
        _done((void**) &(self->fail) );
    }
    _done((void**) &(self->charset) );
    _done((void**) &(self->gids) );

    free(self);
}
