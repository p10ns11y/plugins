/* mm_pert.c: owns PERT expected time and sigma for one stage. */

#include <assert.h>
#include <stddef.h>

#include "mm_pert.h"

static mm_status_t mm_pert_validate(const double *out, mm_stage_t stage);

int mm_stage_is_valid(mm_stage_t stage)
{
    if (stage.a < 0.0)
        return 0;
    if (stage.a > stage.m)
        return 0;
    if (stage.m > stage.b)
        return 0;
    return 1;
}

mm_status_t mm_pert_expected(double *out_te, mm_stage_t stage)
{
    MM_TRY(mm_pert_validate(out_te, stage));

    double weighted = (double)MM_PERT_WEIGHT_ENDS * stage.a;
    weighted += (double)MM_PERT_WEIGHT_MODE * stage.m;
    weighted += (double)MM_PERT_WEIGHT_ENDS * stage.b;
    *out_te = weighted / (double)MM_PERT_WEIGHT_SUM;
    return MM_OK;
}

mm_status_t mm_pert_sigma(double *out_sigma, mm_stage_t stage)
{
    MM_TRY(mm_pert_validate(out_sigma, stage));

    *out_sigma = (stage.b - stage.a) / (double)MM_PERT_WEIGHT_SUM;
    return MM_OK;
}

static mm_status_t mm_pert_validate(const double *out, mm_stage_t stage)
{
    if (out == NULL)
        return MM_ERR_ARG;
    if (!mm_stage_is_valid(stage))
        return MM_ERR_ARG;
    return MM_OK;
}
