#include "font_subset.h"
#include "font_subset__truetype.h"
#include <memory.h>
#include <stdio.h>

static void _font_subset_fail(fontSubsetPtr self, const char* msg) {
    if (self->fail != NULL) {
        fprintf(stderr, "%s\n", self->fail);
        free(self->fail);
    }
    self->fail = strdup(msg);
}

static void _font_subset_init(fontSubsetPtr self, FT_Face font, FT_UInt *charset, size_t len) {
    size_t i;

    FT_Reference_Face(font);
    self->font = font;
    self->len = 0;
    self->charset = calloc(len + 1, sizeof(FT_UInt));
    self->gids = calloc(len + 1, sizeof(FT_UInt));
    self->fail = NULL;
    for (i = 0; i < len; i++) {
        FT_UInt code = charset[i];
        FT_UInt gid;
        if (i && code <= charset[i-1]) {
            _font_subset_fail(self, "charset is not unique and in ascending order");
            break;
        }
        gid = FT_Get_Char_Index(font, code);
        if (gid != 0) {
            self->gids[self->len] = gid;
            self->charset[self->len] = code;
            self->len++;
        }
    }
}

static void* _font_subset_write(fontSubsetPtr self, size_t *len) {
    void* rv = NULL;
    *len = 0;
    if (strcmp(FT_Get_X11_Font_Format(self->font), "TrueType") == 0) {
        rv = font_subset_write__truetype(self, len);
    }
    else {
        _font_subset_fail(self, "can only handle TrueType fonts ATM");
    }
    return rv;
}

static void _done(FT_UInt** p) {
    if (*p != NULL) {
        free(*p);
        *p = NULL;
    }
}

static void _font_subset_done(fontSubsetPtr* _self) {
    fontSubsetPtr self = *_self;

    _done( &(self->charset) );
    _done( &(self->gids) );

    free(self);
    self = NULL;
}


DLLEXPORT void* font_subset_create(FT_Face font, FT_UInt* codes, size_t codes_len, size_t* rv_len) {
    void *rv;
    fontSubsetPtr self = (fontSubsetPtr)malloc(sizeof(struct _fontSubset));
    _font_subset_init(self, font, codes, codes_len);
    rv = _font_subset_write(self, rv_len);
    _font_subset_done(&self);
    return rv;
}
