/* mm_bayes_pert.c: Bayesian PERT band update on stage completion. */

#include <stddef.h>

#include "mm_bayes_pert.h"

static const double MM_BAYES_OBS_WEIGHT = 4.0;
static const double MM_BAYES_SHRINK = 0.85;

mm_status_t mm_bayes_pert_observe(mm_stage_t prior, double t_actual, mm_stage_t *out)
{
    double span;

    if (out == NULL)
        return MM_ERR_ARG;
    if (t_actual < 0.0)
        return MM_ERR_ARG;
    if (!mm_stage_is_valid(prior))
        return MM_ERR_ARG;

    out->m = ((double)MM_PERT_WEIGHT_MODE * prior.m + MM_BAYES_OBS_WEIGHT * t_actual)
             / ((double)MM_PERT_WEIGHT_MODE + MM_BAYES_OBS_WEIGHT);

    out->a = prior.a;
    out->b = prior.b;
    if (t_actual < out->a)
        out->a = t_actual;
    if (t_actual > out->b)
        out->b = t_actual;

    span = out->b - out->a;
    if (span > 0.0) {
        double center = 0.5 * (out->a + out->b);
        double half = 0.5 * span * MM_BAYES_SHRINK;
        out->a = center - half;
        out->b = center + half;
        if (out->a < 0.0)
            out->a = 0.0;
    }

    if (out->a > out->m)
        out->m = out->a;
    if (out->m > out->b)
        out->b = out->m;
    if (!mm_stage_is_valid(*out))
        return MM_ERR_ARG;
    return MM_OK;
}
