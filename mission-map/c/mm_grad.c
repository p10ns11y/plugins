/* mm_grad.c: owns d(te)/d(m) on one stage or a simple path. */

#include <stddef.h>

#include "mm_grad.h"

static mm_status_t mm_grad_validate_path(const double *out,
                                         const mm_stage_t *stages,
                                         size_t n,
                                         size_t idx);

mm_status_t mm_grad_te_wrt_m(double *out_dte, mm_stage_t stage)
{
    double unused = 0.0;

    if (out_dte == NULL)
        return MM_ERR_ARG;
    MM_TRY(mm_pert_expected(&unused, stage));
    *out_dte = (double)MM_PERT_WEIGHT_MODE / (double)MM_PERT_WEIGHT_SUM;
    return MM_OK;
}

mm_status_t mm_grad_path_wrt_m(double *out_dt,
                               const mm_stage_t *stages,
                               size_t n,
                               size_t idx)
{
    MM_TRY(mm_grad_validate_path(out_dt, stages, n, idx));
    return mm_grad_te_wrt_m(out_dt, stages[idx]);
}

static mm_status_t mm_grad_validate_path(const double *out,
                                         const mm_stage_t *stages,
                                         size_t n,
                                         size_t idx)
{
    if (out == NULL || stages == NULL || n == 0)
        return MM_ERR_ARG;
    if (n > (size_t)MM_MAX_STAGES)
        return MM_ERR_FULL;
    if (idx >= n)
        return MM_ERR_ARG;
    if (!mm_stage_is_valid(stages[idx]))
        return MM_ERR_ARG;
    return MM_OK;
}
