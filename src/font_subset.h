#ifndef __FONT_SUBSET_H
#define __FONT_SUBSET_H

#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_FONT_FORMATS_H

struct _fontSubset {
    FT_Face font;
    size_t len;
    FT_UInt *charset;
    FT_UInt *gids;
    char *fail;
};

typedef struct _fontSubset fontSubset;
typedef fontSubset *fontSubsetPtr;

#ifdef _WIN32
#define DLLEXPORT __declspec(dllexport)
#else
#define DLLEXPORT extern
#endif

DLLEXPORT void* font_subset_create(FT_Face font, FT_UInt*, size_t, size_t*);

#endif /* __FONT_SUBSET_H */
