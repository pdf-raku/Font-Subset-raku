#include "font_subset.h"
#include "font_subset__truetype.h"
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

void* font_subset_write__truetype(fontSubsetPtr self, size_t *len) {
    fprintf(stderr, __FILE__ "%d: todo font-subset (TrueType) creation\n", __LINE__);
    return NULL;
}

