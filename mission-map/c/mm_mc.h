#ifndef MM_MC_H
#define MM_MC_H

#include <stddef.h>
#include <stdint.h>

#include "mm_pert.h"

typedef struct {
    double mean;
    double p50;
    double p90;
} mm_mc_summary_t;

typedef struct {
    const mm_stage_t *stages;
    size_t n;
    uint32_t draws;
    uint32_t seed;
} mm_mc_cfg_t;

/* Samples a simple path (sum of independent triangular-PERT draws).
 * Writes mean, p50, p90 of the sample. Fails MM_ERR_ARG on bad cfg,
 * MM_ERR_FULL when draws exceed MM_MAX_DRAWS or n exceeds MM_MAX_STAGES. */
mm_status_t mm_mc_path(mm_mc_summary_t *out, const mm_mc_cfg_t *cfg);

#endif /* MM_MC_H */
