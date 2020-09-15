#include "font_subset.h"
#include <memory.h>
#include <stdio.h>

DLLEXPORT void
font_subset_fail(fontSubsetPtr self, const char* msg) {
    if (self->fail != NULL) {
        fprintf(stderr, "%s\n", self->fail);
        free(self->fail);
    }
    self->fail = strdup(msg);
}

DLLEXPORT fontSubsetPtr
font_subset_create(FT_Face font, FT_ULong *charset, size_t len) {
    size_t i;
    fontSubsetPtr self = (fontSubsetPtr)malloc(sizeof(struct _fontSubset));
    self->font = font;
    self->len = 0;
    self->charset = calloc(len + 1, sizeof(FT_ULong));
    self->gids = calloc(len + 1, sizeof(FT_UInt));
    self->fail = NULL;
    for (i = 0; i < len; i++) {
        FT_ULong code = charset[i];
        FT_UInt gid;
        if (i && code <= charset[i-1]) {
            font_subset_fail(self, "charset is not unique and in ascending order");
            break;
        }
        gid = FT_Get_Char_Index(font, code);
        if (gid != 0) {
            self->gids[self->len] = gid;
            self->charset[self->len] = code;
            self->len++;
        }
    }
    self->gids[self->len] = 0;
    self->charset[self->len] = 0;
    return self;
}

static void _done(void** p) {
    if (*p != NULL) {
        free(*p);
        *p = NULL;
    }
}

DLLEXPORT void
font_subset_done(fontSubsetPtr self) {

    if (self->fail) {
        char msg[120];
        snprintf(msg, sizeof(msg), "uncaught failure on fontSubsetPtr %p destruction: %s", self, self->fail);
        FONT_SUBSET_WARN(msg);
        _done((void**) &(self->fail) );
    }
    _done((void**) &(self->charset) );
    _done((void**) &(self->gids) );

    free(self);
}
