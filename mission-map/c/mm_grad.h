#ifndef MM_GRAD_H
#define MM_GRAD_H

#include <stddef.h>

#include "mm_pert.h"

/* Writes d(te)/d(m) = 4/6 for one stage. Same arg rules as PERT. */
mm_status_t mm_grad_te_wrt_m(double *out_dte, mm_stage_t stage);

/* Writes d(path te)/d(m_idx) for a simple path (sum of tes).
 * Fails MM_ERR_ARG on NULL or bad idx, MM_ERR_FULL if n>MM_MAX_STAGES. */
mm_status_t mm_grad_path_wrt_m(double *out_dt,
                               const mm_stage_t *stages,
                               size_t n,
                               size_t idx);

#endif /* MM_GRAD_H */
