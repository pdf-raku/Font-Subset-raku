#ifndef __FONT_SUBSET_H
#define __FONT_SUBSET_H

#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_FONT_FORMATS_H

struct _fontSubset {
    FT_Face font;
    size_t len;
    FT_ULong *charset;
    FT_UInt *gids;
    char *fail;
};

typedef struct _fontSubset fontSubset;
typedef fontSubset *fontSubsetPtr;

#define FONT_SUBSET_WARN(msg) fprintf(stderr, __FILE__ ":%d: %s\n", __LINE__, (msg));

#ifdef _WIN32
#define DLLEXPORT __declspec(dllexport)
#else
#define DLLEXPORT extern
#endif

DLLEXPORT fontSubsetPtr font_subset_create(FT_Face font, FT_ULong*, size_t);
DLLEXPORT void font_subset_done(fontSubsetPtr);

#endif /* __FONT_SUBSET_H */
