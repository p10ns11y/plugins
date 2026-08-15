/* mm_mc.c: owns bounded triangular-PERT samples on a simple path. */

#include <assert.h>
#include <math.h>
#include <stdint.h>

#include "mm_mc.h"

static const double MM_U32_UNIT_SPAN = 4294967296.0;

/* Rejects NULL cfg/out, zero draws, overflow caps. Fails MM_ERR_ARG/FULL. */
static mm_status_t mm_mc_validate_cfg(const mm_mc_summary_t *out,
                                      const mm_mc_cfg_t *cfg);

/* Writes one triangular draw in [a,b] peaked at m. */
static double mm_mc_sample_stage(mm_stage_t stage, double unit);

/* Fills totals[0..draws) with path sums. Caller sized the buffer. */
static void mm_mc_fill_totals(double *totals, const mm_mc_cfg_t *cfg);

/* Sorts totals ascending in place. Bound = draws. */
static void mm_mc_sort_totals(double *totals, uint32_t draws);

/* Writes mean and percentiles from a sorted totals buffer. */
static void mm_mc_summarize(mm_mc_summary_t *out,
                            const double *totals,
                            uint32_t draws);

/* Next xorshift32 state. Never zero seed. */
static uint32_t mm_mc_rng_next(uint32_t *state);

/* Maps u32 to (0,1). */
static double mm_mc_unit(uint32_t bits);

mm_status_t mm_mc_path(mm_mc_summary_t *out, const mm_mc_cfg_t *cfg)
{
    MM_TRY(mm_mc_validate_cfg(out, cfg));

    double totals[MM_MAX_DRAWS];
    mm_mc_fill_totals(totals, cfg);
    mm_mc_sort_totals(totals, cfg->draws);
    mm_mc_summarize(out, totals, cfg->draws);
    return MM_OK;
}

static mm_status_t mm_mc_validate_cfg(const mm_mc_summary_t *out,
                                      const mm_mc_cfg_t *cfg)
{
    size_t i;

    if (out == NULL || cfg == NULL)
        return MM_ERR_ARG;
    if (cfg->stages == NULL || cfg->n == 0 || cfg->draws == 0)
        return MM_ERR_ARG;
    if (cfg->n > (size_t)MM_MAX_STAGES)
        return MM_ERR_FULL;
    if (cfg->draws > (uint32_t)MM_MAX_DRAWS)
        return MM_ERR_FULL;
    for (i = 0; i < cfg->n; i++) {
        if (!mm_stage_is_valid(cfg->stages[i]))
            return MM_ERR_ARG;
    }
    return MM_OK;
}

static void mm_mc_fill_totals(double *totals, const mm_mc_cfg_t *cfg)
{
    uint32_t state = cfg->seed;
    uint32_t d;
    size_t i;

    assert(totals != NULL);
    assert(cfg != NULL);
    if (state == 0)
        state = 1;

    for (d = 0; d < cfg->draws; d++) {
        double sum = 0.0;
        for (i = 0; i < cfg->n; i++) {
            double unit = mm_mc_unit(mm_mc_rng_next(&state));
            sum += mm_mc_sample_stage(cfg->stages[i], unit);
        }
        totals[d] = sum;
    }
}

static double mm_mc_sample_stage(mm_stage_t stage, double unit)
{
    double span = stage.b - stage.a;
    double left = stage.m - stage.a;
    double right = stage.b - stage.m;
    double fc;

    assert(mm_stage_is_valid(stage));
    if (span == 0.0)
        return stage.a;
    fc = left / span;
    if (unit < fc)
        return stage.a + sqrt(unit * span * left);
    return stage.b - sqrt((1.0 - unit) * span * right);
}

static void mm_mc_sort_totals(double *totals, uint32_t draws)
{
    uint32_t i;
    uint32_t j;

    assert(totals != NULL);
    for (i = 1; i < draws; i++) {
        double hold = totals[i];
        j = i;
        while (j > 0 && totals[j - 1] > hold) {
            totals[j] = totals[j - 1];
            j--;
        }
        totals[j] = hold;
    }
}

static void mm_mc_summarize(mm_mc_summary_t *out,
                            const double *totals,
                            uint32_t draws)
{
    uint32_t i;
    uint32_t i50;
    uint32_t i90;
    double sum = 0.0;

    assert(out != NULL);
    assert(totals != NULL);
    assert(draws > 0);
    for (i = 0; i < draws; i++)
        sum += totals[i];
    i50 = (draws - 1) / 2;
    i90 = (9 * (draws - 1)) / 10;
    out->mean = sum / (double)draws;
    out->p50 = totals[i50];
    out->p90 = totals[i90];
}

static uint32_t mm_mc_rng_next(uint32_t *state)
{
    uint32_t x;

    assert(state != NULL);
    x = *state;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    *state = x;
    return x;
}

static double mm_mc_unit(uint32_t bits)
{
    return ((double)bits + 0.5) / MM_U32_UNIT_SPAN;
}
