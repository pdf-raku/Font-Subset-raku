#ifndef __SFNT_SUBSET_H
#define __SFNT_SUBSET_H

#include <stdint.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_FONT_FORMATS_H

struct _sfntSubset {
    FT_Face font;
    size_t len;
    FT_ULong *charset;
    FT_UInt *gids;
    char *fail;
};

typedef struct _sfntSubset sfntSubset;
typedef sfntSubset *sfntSubsetPtr;

#define SFNT_SUBSET_WARN(msg) fprintf(stderr, __FILE__ ":%d: %s\n", __LINE__, (msg));

#ifdef _WIN32
#define DLLEXPORT __declspec(dllexport)
#else
#define DLLEXPORT extern
#endif

DLLEXPORT sfntSubsetPtr sfnt_subset_create(FT_Face, FT_ULong*, size_t);
DLLEXPORT void sfnt_subset_fail(sfntSubsetPtr, const char*);
DLLEXPORT void sfnt_subset_done(sfntSubsetPtr);
DLLEXPORT uint16_t sfnt_subset_repack_glyphs_16(sfntSubsetPtr, uint16_t*, uint8_t*);

#endif /* __SFNT_SUBSET_H */
