#include "font_subset.h"

#define MAKE_TT_TAG(a, b, c, d)    (a<<24 | b<<16 | c<<8 | d)
#define TT_TAG_CFF    MAKE_TT_TAG('C','F','F',' ')
#define TT_TAG_cmap   MAKE_TT_TAG('c','m','a','p')
#define TT_TAG_cvt    MAKE_TT_TAG('c','v','t',' ')
#define TT_TAG_fpgm   MAKE_TT_TAG('f','p','g','m')
#define TT_TAG_glyf   MAKE_TT_TAG('g','l','y','f')
#define TT_TAG_head   MAKE_TT_TAG('h','e','a','d')
#define TT_TAG_hhea   MAKE_TT_TAG('h','h','e','a')
#define TT_TAG_hmtx   MAKE_TT_TAG('h','m','t','x')
#define TT_TAG_loca   MAKE_TT_TAG('l','o','c','a')
#define TT_TAG_maxp   MAKE_TT_TAG('m','a','x','p')
#define TT_TAG_name   MAKE_TT_TAG('n','a','m','e')
#define TT_TAG_OS2    MAKE_TT_TAG('O','S','/','2')
#define TT_TAG_post   MAKE_TT_TAG('p','o','s','t')
#define TT_TAG_prep   MAKE_TT_TAG('p','r','e','p')

DLLEXPORT void* font_subset_write__truetype(fontSubsetPtr self, size_t *len);
