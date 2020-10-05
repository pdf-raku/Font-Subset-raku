#include "sfnt_glyph.h"

static FT_UInt find_gid(sfntSubsetPtr self, FT_UInt old_gid) {
    FT_UInt i;
    FT_UInt new_gid = 0;

    // search subset gids
    for (i = 0; i < self->gids_len; i++) {
        if (self->gids[i] == old_gid) {
            new_gid = i;
            break;
        }
        
    }
    return new_gid;
}

static FT_UInt add_gid(sfntSubsetPtr self, FT_UInt old_gid) {
    if (self->gids_len >= self->gids_size) {
        // extend
        self->gids_size += 2;
        self->gids_size *= 1.5;
        self->gids = (FT_UInt*) realloc((void*) self->gids, self->gids_size * sizeof(*self->gids));
    }
    self->gids[self->gids_len] = old_gid;
    return self->gids_len++;
}

static FT_UInt use_gid(sfntSubsetPtr self, FT_UInt old_gid) {
    // use this gid and add it to our subset
    FT_UInt new_gid = find_gid(self, old_gid);
    if (new_gid == 0) {
        new_gid = add_gid(self, old_gid);
    }
    return new_gid;
}

static uint16_t
cpu_to_be16(uint16_t v) {
    return (v << 8) | (v >> 8);
}

static uint16_t
be16_to_cpu(uint16_t v) {
    return cpu_to_be16 (v);
}


// port of cairo_truetype_font_remap_composite_glyph()
DLLEXPORT int
sfnt_glyph_add_components(
    sfntSubsetPtr self,
    uint8_t*      buffer,
    size_t        size
    ) {
    sfnt_glyph_data_t *glyph_data;
    sfnt_composite_glyph_t *composite_glyph;
    int num_args;
    int has_more_components;
    unsigned short flags;
    FT_UInt old_gid;
    FT_UInt new_gid;
    unsigned char *end = buffer + size;

    glyph_data = (sfnt_glyph_data_t *) buffer;
    if ((unsigned char *)(&glyph_data->data) >= end) {
        sfnt_subset_fail(self, "insufficient glyph data");
	return 0;
    }

    if ((int16_t)be16_to_cpu (glyph_data->num_contours) >= 0)
        return 1;  // not a composite

    composite_glyph = &glyph_data->glyph;

    do {
	if ((unsigned char *)(&composite_glyph->args[1]) > end) {
            sfnt_subset_fail(self, "insufficient glyph data");
            return 0;
	}

        old_gid = be16_to_cpu (composite_glyph->index);
        new_gid = use_gid(self, old_gid);

        composite_glyph->index = cpu_to_be16 (new_gid);

	flags = be16_to_cpu (composite_glyph->flags);
        has_more_components = flags & SFNT_MORE_COMPONENTS;
        num_args = 1;
        if (flags & SFNT_ARG_1_AND_2_ARE_WORDS)
            num_args += 1;

	if (flags & SFNT_WE_HAVE_A_SCALE)
            num_args += 1;
        else if (flags & SFNT_WE_HAVE_AN_X_AND_Y_SCALE)
            num_args += 2;
        else if (flags & SFNT_WE_HAVE_A_TWO_BY_TWO)
            num_args += 4;

	composite_glyph = (sfnt_composite_glyph_t *) &(composite_glyph->args[num_args]);
    } while (has_more_components);

    return 1;
}
