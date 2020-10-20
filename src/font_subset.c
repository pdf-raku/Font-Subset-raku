#include "font_subset.h"
#include <memory.h>
#include <stdio.h>

DLLEXPORT void
font_subset_fail(sfntSubsetPtr self, const char* msg) {
    if (self->fail != NULL) {
        fprintf(stderr, "%s\n", self->fail);
        free(self->fail);
    }
    self->fail = strdup(msg);
}

DLLEXPORT sfntSubsetPtr
font_subset_create(FT_Face font, FT_ULong *charset, size_t len) {
    size_t i;
    sfntSubsetPtr self = (sfntSubsetPtr)malloc(sizeof(struct _sfntSubset));
    self->charset_len = 0;
    self->charset = calloc(len + 2, sizeof(FT_ULong));
    // reserve extra space for component glyphs
    self->gids_size = len * 1.5 + 3;
    self->gids = calloc(self->gids_size, sizeof(FT_UInt));
    self->gids_len = 0;
    self->fail = NULL;

    // Add .notdef
    self->gids[self->gids_len++] = 0;
    self->charset[self->charset_len++] = 0;

    for (i = 0; i < len; i++) {
        FT_ULong code = charset[i];
        FT_UInt gid;

        gid = FT_Get_Char_Index(font, code);
        self->gids[self->gids_len++] = gid;
        self->charset[self->charset_len++] = code;
    }

    self->gids[self->gids_len] = 0;
    self->charset[self->charset_len] = 0;
    return self;
}

static void _done(void** p) {
    if (*p != NULL) {
        free(*p);
        *p = NULL;
    }
}

DLLEXPORT void
font_subset_done(sfntSubsetPtr self) {

    if (self->fail) {
        char msg[120];
        snprintf(msg, sizeof(msg), "uncaught failure on sfntSubsetPtr %p destruction: %s", self, self->fail);
        FONT_SUBSET_WARN(msg);
        _done((void**) &(self->fail) );
    }
    _done((void**) &(self->charset) );
    _done((void**) &(self->gids) );

    free(self);
}
